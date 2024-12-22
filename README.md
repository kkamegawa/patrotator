# Integrating Microsoft Identity Platform with a Python web application

## About this sample

### Overview

This sample demonstrates a Python web application that signs-in users with the Microsoft identity platform and calls the API.

1. The python web application uses the Microsoft Authentication Library (MSAL) to obtain a JWT access token from the Microsoft identity platform (formerly Entra v2.0):
2. The access token is used as a bearer token to authenticate the user when calling the API.

### Scenario

This sample shows how to build a Python web app using Flask and MSAL Python,
that signs in a user, and get access to the API.
For more information about how the protocols work in this scenario and other scenarios,
see [Authentication Scenarios for Entra](https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-authentication-scenarios).

## How to run this sample

To run this sample, you'll need:

> - [Python 3+](https://www.python.org/downloads/release/python-364/)
> - An Entra tenant. For more information on how to get an Entra tenant, see [how to get an Entra tenant.](https://learn.microsoft.com/ja-jp/entra/identity-platform/quickstart-create-new-tenant)

### Step 1:  Clone or download this repository

> Given that the name of the sample is quite long, you might want to clone it in a folder close to the root of your hard drive, to avoid file name length limitations when running on Windows.

### Step 2:  Register the sample application with your Entra tenant

#### Choose the Entra tenant where you want to create your applications

As a first step you'll need to:

1. Sign in to the [Azure portal](https://portal.azure.com) using either a work or school account or a personal Microsoft account.
1. If your account is present in more than one Entra tenant, select your profile at the top right corner in the menu on top of the page, and then **switch directory**.
   Change your portal session to the desired Entra tenant.

#### Register the Python Webapp (python-webapp)

1. Navigate to the Microsoft identity platform for developers [App registrations](https://go.microsoft.com/fwlink/?linkid=2083908) page.
1. Select **New registration**.
1. When the **Register an application page** appears, enter your application's registration information:
   - In the **Name** section, enter a meaningful application name that will be displayed to users of the app, for example `python-webapp`.
   - Change **Supported account types** to **Accounts in any organizational directory and personal Microsoft accounts (e.g. Skype, Xbox, Outlook.com)**.
   - In the Redirect URI (optional) section, select **Web** in the combo-box and enter the following redirect URIs: `http://localhost:5000/getAToken`.
1. Select **Register** to create the application.
1. On the app **Overview** page, find the **Application (client) ID** value and record it for later. You'll need it to configure the Visual Studio configuration file for this project.
1. Select **Save**.
1. From the **Certificates & secrets** page, in the **Client secrets** section, choose **New client secret**:

   - Type a key description (of instance `app secret`),
   - Select a key duration of either **In 1 year**, **In 2 years**, or **Never Expires**.
   - When you press the **Add** button, the key value will be displayed, copy, and save the value in a safe location.
   - You'll need this key later to configure the project in Visual Studio. This key value will not be displayed again, nor retrievable by any other means,
     so record it as soon as it is visible from the Azure portal.
1. Select the **API permissions** section
   - Click the **Add a permission** button and then,
   - Ensure that the **Microsoft APIs** tab is selected
   - In the *Commonly used Microsoft APIs* section, click on **Azure DevOps**
   - In the **Delegated permissions** section, ensure that the right permissions are checked: **user_impersonation**. Use the search box if necessary.
   - Select the **Add permissions** button

### Step 3:  Configure the sample to use your Entra tenant

In the steps below, "ClientID" is the same as "Application ID" or "AppId".

#### Configure the pythonwebapp project

> Note: if you used the setup scripts, the changes below may have been applied for you

1. Open the `app_config.py` file
2. For a multi-tenant app, find the app key `Enter_the_Tenant_ID_Here` and replace the existing value with your Entra tenant ID.  For a single tenant app, use the alternate value for the AUTHORITY variable, adding the specific tenant name in `Enter_the_Tenant_Name_Here`.
3. You saved your application secret during the creation of the `python-webapp` app in the Azure portal.
   Now you can set the secret in environment variable `CLIENT_SECRET`,
   and then adjust `app_config.py` to pick it up.
4. Find the app key `Enter_the_Application_Id_here` and replace the existing value with the application ID (clientId) of the `python-webapp` application copied from the Azure portal.
5. Find the ENDPOINT variable and replace `Enter_the_Collection_Name_Here` with the name of your Azure DevOps collection.

### Step 4: Run the sample

- You will need to install dependencies using pip as follows:
```Shell
$ pip install -r requirements.txt
```

Run app.py from shell or command line. Note that the host and port values need to match what you've set up in your redirect_uri:

```Shell
$ flask run --host localhost --port 5010
```

or 

```Shell
$ python -m flask run
```

## More information

For more information, see MSAL.Python's [conceptual documentation]("https://github.com/AzureAD/microsoft-authentication-library-for-python/wiki"):


For more information about web apps scenarios on the Microsoft identity platform see [Scenario: Web app that calls web APIs](https://docs.microsoft.com/en-us/azure/active-directory/develop/scenario-web-app-call-api-overview)

For more information about how OAuth 2.0 protocols work in this scenario and other scenarios, see [Authentication Scenarios for Entra](http://go.microsoft.com/fwlink/?LinkId=394414).