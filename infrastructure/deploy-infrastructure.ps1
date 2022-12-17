#All  variables for infra build

param
(
    [string] $studentsuffix = "lnt"
)

$resourcegroupName = "fabmedical-rg-" + $studentsuffix
$cosmosDBName = "fabmedical-cdb-" + $studentsuffix
$webappName = "fabmedical-web-" + $studentsuffix
$planName = "fabmedical-plan-" + $studentsuffix
$workspaceName = "fabmedical-law-" + $studentsuffix
$appInsights = "fabmedical-ai-" + $studentsuffix
$workspaceName = "fabmedical-law-" + $studentsuffix
$location1 = "westus3"
$location2 = "eastus"

# Create a group
$rg = az group create --name $resourcegroupName --location $location1 | ConvertFrom-Json

#Then create a CosmosDB
az cosmosdb create --name $cosmosDBName `
--resource-group $resourcegroupName `
--locations regionName=$location1 failoverPriority=0 isZoneRedundant=False `
--locations regionName=$location2 failoverPriority=1 isZoneRedundant=True `
--enable-multiple-write-locations `
--kind MongoDB `
--enable-app-service-storage true

# Create an Azure App Service Plan
az appservice plan create --name $planName --resource-group $resourcegroupName --sku S1 --is-linux

az webapp config appsettings set --settings DOCKER_REGISTRY_SERVER_URL="https://ghcr.io" --name $($webappName) --resource-group $($resourcegroupName) 
az webapp config appsettings set --settings DOCKER_REGISTRY_SERVER_USERNAME="notapplicable" --name $($webappName) --resource-group $($resourcegroupName) 
az webapp config appsettings set --settings DOCKER_REGISTRY_SERVER_PASSWORD="$($env:CR_PAT)" --name $($webappName) --resource-group $($resourcegroupName)

# Create an Azure Web App with NGINX container
az webapp create `
--multicontainer-config-file ./docker-compose.yml `
--multicontainer-config-type COMPOSE `
--resource-group $($resourcegroupName) `
--plan $($planName) `
--name $($webappName)

# Add container properties to Web App to pull from GitHub Container Registry images
az webapp config container set `
--docker-registry-server-password $($env:CR_PAT) `
--docker-registry-server-url https://ghcr.io `
--docker-registry-server-user notapplicable `
--multicontainer-config-file docker-compose.yml `
--multicontainer-config-type COMPOSE `
--name $($webappName) `
--resource-group $resourcegroupName 

#Create the following: A log analytics workspace & app insights
az extension add --name application-insights
az monitor app-insights component create --app $appInsights --location $location2 --kind web -g $resourcegroupName --application-type web --retention-time 120
