#All  variables for infra build
$studentsuffix = "lnt"
$resourcegroupName = "fabmedical-rg-" + $studentsuffix
$cosmosDBName = "fabmedical-cdb-" + $studentsuffix
$webappName = "fabmedical-web-" + $studentsuffix
$planName = "fabmedical-plan-" + $studentsuffix
$workspaceName = "fabmedical-law-" + $studentsuffix
$appInsights = "fabmedical-ai-" + $studentsuffix
$location1 = "westus3"
$location2 = "eastus"

#create the resource group
az group create -l $location1 -n $resourcegroupName

#create the cosmosDB with 2 failover locations
az cosmosdb create --name $cosmosDBName `
--resource-group $resourcegroupName `
--locations regionName=$location1 failoverPriority=0 isZoneRedundant=False `
--locations regionName=$location2 failoverPriority=1 isZoneRedundant=True `
--enable-multiple-write-locations `
--kind MongoDB 


#create the App Service Plan
az appservice plan create --name $planName --resource-group $resourcegroupName --sku S1 --is-linux

#create the WebApp with nginx
az webapp create --resource-group $resourcegroupName --plan $planName --name $webappName 

#create the WebApp with nginx
az webapp create --resource-group $resourcegroupName `
--plan $planName --name $webappName -i nginx

#configure the webapp settings
az webapp config container set `
--docker-registry-server-password $MY_PAT `
--docker-registry-server-url https://ghcr.io `
--docker-registry-server-user notapplicable `
--multicontainer-config-file ../docker-compose.yml `
--multicontainer-config-type COMPOSE `
--name $webappName `
--resource-group $resourcegroupName `
--enable-app-service-storage true

#setting up Application Insights
az extension add --name application-insights
az monitor app-insights component create --app $appInsights --location $location1 --kind web -g $resourcegroupName --application-type web --retention-time 120

#Create the following: A log analytics workspace & app insights

<# basic app insights is being deprecated in 2024. The west US 3 region doesn't even support the basic app insights, 
only ones through a log analytics workspace. So to implement an app insights that won't be deprecated in a year (ish), 
it was best to use the newer way of doing things.

az monitor log-analytics workspace create --resource-group $resourcegroupName `
    --workspace-name $workspaceName

az extension add --name application-insights
$ai = az monitor app-insights component create --app $appInsights --location $location1 --kind web -g $resourcegroupName `
    --workspace "/subscriptions/c074675d-209c-429a-a95e-ea35b822e146/resourceGroups/fabmedical-rg-ltn/providers/Microsoft.OperationalInsights/workspaces/fabmedical-law-ltn" `
    --application-type web | ConvertFrom-Json

$global:aiInstKey = $ai.instrumentationKey
$aiConnectionString = $ai.connectionString
#>