import os

# To configure this application, fill in your application (client) ID, client secret, 
# Entra tenant ID, and Azure DevOps collection name in the placeholders below.

CLIENT_ID = "{APPLICATION_ID}" 
# Application (client) ID of app registration

CLIENT_SECRET = "{CLIENT_SECRET_HERE}"
# In a production app, we recommend you use a more secure method of storing your secret,
# like Azure Key Vault. Or, use an environment variable as described in Flask's documentation:
# https://flask.palletsprojects.com/en/1.1.x/config/#configuring-from-environment-variables
# CLIENT_SECRET = os.getenv("CLIENT_SECRET")
# if not CLIENT_SECRET:
#     raise ValueError("Need to define CLIENT_SECRET environment variable")

AUTHORITY = "https://login.microsoftonline.com/{tenant_id}"  # For multi-tenant app
# AUTHORITY = "https://login.microsoftonline.com/domain_name"  # For single-tenant app

REDIRECT_PATH = "/getAToken"  # Used for forming an absolute URL to your redirect URI.
                              # The absolute URL must match the redirect URI you set
                              # in the app's registration in the Azure portal.


ENDPOINT = 'https://vssps.dev.azure.com/{organization_name}/_apis/Tokens/Pats?api-version=7.2-preview.1' 
# fill in the url to the user's ADO collection name here

SCOPE = ["499b84ac-1321-427f-aa17-267ca6975798/.default"]
# Means "All scopes for the Azure DevOps API resource"

SESSION_TYPE = "filesystem"  
# Specifies the token cache should be stored in server-side session
