Start-Sleep -Seconds 500

#All  variables for infra build
$studentsuffix = "ltn"
$resourcegroupName = "fabmedical-rg-" + $studentsuffix
$cosmosDBName = "fabmedical-cdb-" + $studentsuffix
$webappName = "fabmedical-web-" + $studentsuffix
$planName = "fabmedical-plan-" + $studentsuffix
$workspaceName = "fabmedical-law-" + $studentsuffix
$appInsights = "fabmedical-ai-" + $studentsuffix
$location1 = "westus3"
$location2 = "eastus"
$dbConnection = ""
$manipulate = ""
$dbKeys = ""


#create the resource group
az group create -l $location1 -n $resourcegroupName

#create the cosmosDB with 2 failover locations
az cosmosdb create --name $cosmosDBName `
--resource-group $resourcegroupName `
--locations regionName=$location1 failoverPriority=0 isZoneRedundant=False `
--locations regionName=$location2 failoverPriority=1 isZoneRedundant=True `
--enable-multiple-write-locations `
--kind MongoDB 


#Create a Azure App Service Plan
az appservice plan create --name $planName --resource-group $resourcegroupName --sku S1 --is-linux

#get and configure dbConnection string
$dbKeys = az cosmosdb keys list -n $cosmosDBName -g $resourcegroupName --type connection-strings `
    --query "connectionStrings[?description=='Primary MongoDB Connection String'].connectionString"
$manipulate = $dbKeys[1]
$manipulate = $manipulate.Split("""")[1]
$manipulate = $manipulate.Split("?")
$dbConnection = $manipulate[0] + "contentdb?" + $manipulate[1]

az webapp config appsettings set --settings DOCKER_REGISTRY_SERVER_URL="https://ghcr.io" --name $webappName --resource-group $resourcegroupName 
az webapp config appsettings set --settings DOCKER_REGISTRY_SERVER_USERNAME="notapplicable" --name $webappName --resource-group $resourcegroupName 
az webapp config appsettings set --settings DOCKER_REGISTRY_SERVER_PASSWORD="$env:CR_PAT" --name $webappName --resource-group $resourcegroupName 

#Create a Azure Web App with NGINX container
az webapp create `
--multicontainer-config-file docker-compose.yml `
--multicontainer-config-type COMPOSE `
--name $webappName `
--resource-group $resourcegroupName `
--plan $planName

az webapp config container set `
--docker-registry-server-password $env:CR_PAT `
--docker-registry-server-url https://ghcr.io `
--docker-registry-server-user notapplicable `
--multicontainer-config-file docker-compose.yml `
--multicontainer-config-type COMPOSE `
--name $webappName `
--resource-group $resourcegroupName 

az extension add --name application-insights
az monitor app-insights component create --app $appInsights --location $location1 --kind web -g $resourcegroupName --application-type web --retention-time 120

#set the mongoDB connection
az webapp config appsettings set --resource-group $resourceGroupName `
--name $webappName `
--settings MONGODB_CONNECTION=$dbConnection



#Create the following: A log analytics workspace & app insights
az monitor log-analytics workspace create --resource-group $resourcegroupName `
    --workspace-name $workspaceName

az extension add --name application-insights
sudo npm install applicationinsights
$ai = az monitor app-insights component create --app $appInsights --location $location1 --kind web -g $resourcegroupName `
    --workspace "/subscriptions/c074675d-209c-429a-a95e-ea35b822e146/resourceGroups/fabmedical-rg-ltn/providers/Microsoft.OperationalInsights/workspaces/fabmedical-law-ltn" `
    --application-type web | ConvertFrom-Json

$global:aiInstKey = $ai.instrumentationKey
$aiConnectionString = $ai.connectionString

#link the newly created app insights to the webapp with default values
az webapp config appsettings set --resource-group $resourceGroupName `
--name $webappName `
--settings APPINSIGHTS_INSTRUMENTATIONKEY=$global:aiInstKey `
    APPINSIGHTS_PROFILERFEATURE_VERSION=1.0.0 `
    APPINSIGHTS_SNAPSHOTFEATURE_VERSION=1.0.0 `
    APPLICATIONINSIGHTS_CONNECTION_STRING=$aiConnectionString `
    ApplicationInsightsAgent_EXTENSION_VERSION=~2 `
    DiagnosticServices_EXTENSION_VERSION=~3 `
    InstrumentationEngine_EXTENSION_VERSION=disabled `
    SnapshotDebugger_EXTENSION_VERSION=disabled `
    XDT_MicrosoftApplicationInsights_BaseExtensions=disabled `
    XDT_MicrosoftApplicationInsights_Mode=recommended `
    XDT_MicrosoftApplicationInsights_PreemptSdk=disabled `
    WEBSITES_ENABLE_APP_SERVICE_STORAGE=true

#commit the updated app.js
& .\azinf/gitpp.ps1

#re-deploy the web container to the application
& .\azinf/deploy-container.ps1
