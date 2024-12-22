[CmdletBinding()]
param(
    [PSCredential] $Credential,
    [Parameter(Mandatory=$False, HelpMessage='Tenant ID (This is a GUID which represents the "Directory ID" of the Entra tenant into which you want to create the apps')]
    [string] $tenantId
)

<#
 This script creates the Entra applications needed for this sample and updates the configuration files
 for the visual Studio projects from the data in the Entra applications.

 Before running this script you need to install the Entra cmdlets as an administrator. 
 For this:
 1) Run Powershell as an administrator
 2) in the PowerShell window, type: Install-Module -Name Microsoft.Graph.Entra -AllowPrerelease -Repository PSGallery -Force

 There are four ways to run this script. For more information, read the AppCreationScripts.md file in the same folder as this script.
#>

# Create a password that can be used as an application key
Function ComputePassword
{
    $aesManaged = [System.Security.Cryptography.Aes]::Create()
    $aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aesManaged.Padding = [System.Security.Cryptography.PaddingMode]::Zeros
    $aesManaged.BlockSize = 128
    $aesManaged.KeySize = 256
    $aesManaged.GenerateKey()
    return [System.Convert]::ToBase64String($aesManaged.Key)
}

# Create an application key
Function CreateAppKey([DateTime] $fromDate, [double] $durationInYears, [string]$pw)
{
    $endDate = $fromDate.AddYears($durationInYears) 
    $keyId = [Guid]::NewGuid().ToString()
    $key = @{
        "startDateTime" = $fromDate.ToString("o")
        "endDateTime" = $endDate.ToString("o")
        "secretText" = $pw
        "keyId" = $keyId
    }
    return $key
}

# Adds the requiredAccesses (expressed as a pipe separated string) to the requiredAccess structure
# The exposed permissions are in the $exposedPermissions collection, and the type of permission (Scope | Role) is 
# described in $permissionType
Function AddResourcePermission($requiredAccess, $exposedPermissions, [string]$requiredAccesses, [string]$permissionType)
{
    foreach($permission in $requiredAccesses.Trim().Split("|"))
    {
        foreach($exposedPermission in $exposedPermissions)
        {
            if ($exposedPermission.Value -eq $permission)
            {
                $resourceAccess = @{
                    "id" = $exposedPermission.Id
                    "type" = $permissionType
                }
                $requiredAccess.Add($resourceAccess)
            }
        }
    }
}

#
# Example: GetRequiredPermissions "Microsoft Graph"  "Graph.Read|User.Read"
# See also: http://stackoverflow.com/questions/42164581/how-to-configure-a-new-azure-ad-application-through-powershell
Function GetRequiredPermissions([string] $applicationDisplayName, [string] $requiredDelegatedPermissions, [string]$requiredApplicationPermissions, $servicePrincipal)
{
    # If we are passed the service principal we use it directly, otherwise we find it from the display name (which might not be unique)
    if ($servicePrincipal)
    {
        $sp = $servicePrincipal
    }
    else
    {
        $sp = Get-MgServicePrincipal -Filter "displayName eq '$applicationDisplayName'"
    }
    $appid = $sp.AppId
    $requiredAccess = @{
        "resourceAppId" = $appid
        "resourceAccess" = @()
    }

    # $sp.Oauth2Permissions | Select Id,AdminConsentDisplayName,Value: To see the list of all the Delegated permissions for the application:
    if ($requiredDelegatedPermissions)
    {
        AddResourcePermission $requiredAccess.resourceAccess -exposedPermissions $sp.Oauth2PermissionScopes -requiredAccesses $requiredDelegatedPermissions -permissionType "Scope"
    }
    
    # $sp.AppRoles | Select Id,AdminConsentDisplayName,Value: To see the list of all the Application permissions for the application
    if ($requiredApplicationPermissions)
    {
        AddResourcePermission $requiredAccess.resourceAccess -exposedPermissions $sp.AppRoles -requiredAccesses $requiredApplicationPermissions -permissionType "Role"
    }
    return $requiredAccess
}


Function ReplaceInLine([string] $line, [string] $key, [string] $value)
{
    $index = $line.IndexOf($key)
    if ($index -ige 0)
    {
        $index2 = $index+$key.Length
        $line = $line.Substring(0, $index) + $value + $line.Substring($index2)
    }
    return $line
}

Function ReplaceInTextFile([string] $configFilePath, [System.Collections.HashTable] $dictionary)
{
    $lines = Get-Content $configFilePath
    $index = 0
    while($index -lt $lines.Length)
    {
        $line = $lines[$index]
        foreach($key in $dictionary.Keys)
        {
            if ($line.Contains($key))
            {
                $lines[$index] = ReplaceInLine $line $key $dictionary[$key]
            }
        }
        $index++
    }

    Set-Content -Path $configFilePath -Value $lines -Force
}

Set-Content -Value "<html><body><table>" -Path createdApps.html
Add-Content -Value "<thead><tr><th>Application</th><th>AppId</th><th>Url in the Azure portal</th></tr></thead><tbody>" -Path createdApps.html

$ErrorActionPreference = "Stop"

Function ConfigureApplications
{
<#.Description
   This function creates the Entra applications for the sample in the provided Entra tenant and updates the
   configuration files in the client and service project  of the visual studio solution (App.Config and Web.Config)
   so that they are consistent with the Applications parameters
#> 
    # $tenantId is the Active Directory Tenant. This is a GUID which represents the "Directory ID" of the Entra tenant
    # into which you want to create the apps. Look it up in the Azure portal in the "Properties" of the Entra.

    # Login to Microsoft Graph PowerShell
    if (!$Credential -and $TenantId)
    {
        $creds = Connect-MgGraph -TenantId $tenantId
    }
    else
    {
        if (!$TenantId)
        {
            $creds = Connect-MgGraph -Credential $Credential
        }
        else
        {
            $creds = Connect-MgGraph -TenantId $tenantId -Credential $Credential
        }
    }

    if (!$tenantId)
    {
        $tenantId = (Get-MgOrganization).Id
    }

    $tenant = Get-MgOrganization
    $tenantName =  ($tenant.VerifiedDomains | Where-Object { $_.IsDefault -eq $True }).Name

    # Get the user running the script to add the user as the app owner
    $user = Get-MgUser -UserId $creds.Account.Id

   # Create the pythonwebapp Entra application
   Write-Host "Creating the Entra application (python-webapp)"
   # Get a 2 years application key for the pythonwebapp Application
   $pw = ComputePassword
   $fromDate = [DateTime]::Now;
   $key = CreateAppKey -fromDate $fromDate -durationInYears 2 -pw $pw
   $pythonwebappAppKey = $pw
   # create the application 
   $pythonwebappAadApplication = New-MgApplication -DisplayName "python-webapp" `
                                                    -Web @{ "redirectUris" = @("http://localhost:5000/getAToken") } `
                                                    -IdentifierUris @("https://$tenantName/python-webapp") `
                                                    -PasswordCredentials @($key) `
                                                    -SignInAudience "EntraMyOrg"

   # create the service principal of the newly created application 
   $currentAppId = $pythonwebappAadApplication.AppId
   $pythonwebappServicePrincipal = New-MgServicePrincipal -AppId $currentAppId

   # add the user running the script as an app owner if needed
   $owner = Get-MgApplicationOwner -ApplicationId $pythonwebappAadApplication.Id
   if ($owner -eq $null)
   { 
        Add-MgApplicationOwner -ApplicationId $pythonwebappAadApplication.Id -DirectoryObjectId $user.Id
        Write-Host "'$($user.UserPrincipalName)' added as an application owner to app '$($pythonwebappServicePrincipal.DisplayName)'"
   }


   Write-Host "Done creating the pythonwebapp application (python-webapp)"

   # URL of the AAD application in the Azure portal
   # Future? $pythonwebappPortalUrl = "https://portal.azure.com/#@"+$tenantName+"/blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Overview/appId/"+$pythonwebappAadApplication.AppId+"/objectId/"+$pythonwebappAadApplication.ObjectId+"/isMSAApp/"
   $pythonwebappPortalUrl = "https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/CallAnAPI/appId/"+$pythonwebappAadApplication.AppId+"/objectId/"+$pythonwebappAadApplication.Id+"/isMSAApp/"
   Add-Content -Value "<tr><td>pythonwebapp</td><td>$currentAppId</td><td><a href='$pythonwebappPortalUrl'>python-webapp</a></td></tr>" -Path createdApps.html

   $requiredResourcesAccess = @()

   # Add Required Resources Access (from 'pythonwebapp' to 'Microsoft Graph')
   Write-Host "Getting access from 'pythonwebapp' to 'Microsoft Graph'"
   $requiredPermissions = GetRequiredPermissions -applicationDisplayName "Microsoft Graph" `
                                                -requiredDelegatedPermissions "User.ReadBasic.All" `

   $requiredResourcesAccess += $requiredPermissions


   Update-MgApplication -ApplicationId $pythonwebappAadApplication.Id -RequiredResourceAccess $requiredResourcesAccess
   Write-Host "Granted permissions."

   # Update config file for 'pythonwebapp'
   $configFile = $pwd.Path + "\..\app_config.py"
   Write-Host "Updating the sample code ($configFile)"
   $dictionary = @{ "Enter_the_Tenant_Name_Here" = $tenantName;"Enter_the_Client_Secret_Here" = $pythonwebappAppKey;"Enter_the_Application_Id_here" = $pythonwebappAadApplication.AppId };
   ReplaceInTextFile -configFilePath $configFile -dictionary $dictionary
  
   Add-Content -Value "</tbody></table></body></html>" -Path createdApps.html  
}

# Pre-requisites
if ((Get-Module -ListAvailable -Name "Microsoft.Graph") -eq $null) { 
    Install-Module "Microsoft.Graph" -Scope CurrentUser 
}

Import-Module Microsoft.Graph

# Run interactively (will ask you for the tenant ID)
ConfigureApplications -Credential $Credential -tenantId $TenantId