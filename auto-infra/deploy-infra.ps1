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
$dbConnection = "mongodb://fabmedical-cdb-lnt:OertNdMqlVVl8Kpn6nnwSu9lMGZMjTbqEl1RoqGniDVK9GGt5YLIY40iz0rgEPIu6No6bTk1EGhEACDbSlLINA==@fabmedical-cdb-lnt.mongo.cosmos.azure.com:10255/contentdb?ssl=true&replicaSet=globaldb&retrywrites=false&maxIdleTimeMS=120000&appName=@fabmedical-cdb-lnt@"
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

#create the App Service Plan
az appservice plan create --name $planName --resource-group $resourcegroupName --sku S1 --is-linux

#create the WebApp with nginx
az webapp create --resource-group $resourcegroupName `
--plan $planName --name $webappName -i nginx

#configure the webapp settings
az webapp config container set `
--docker-registry-server-password $CR_PAT `
--docker-registry-server-url https://ghcr.io `
--docker-registry-server-user notapplicable `
--multicontainer-config-file ../docker-compose.yml `
--multicontainer-config-type COMPOSE `
--name $webappName `
--resource-group $resourcegroupName `
--enable-app-service-storage true


#set the mongoDB connection
az webapp config appsettings set -n $webappName -g $resourcegroupName --settings MONGODB_CONNECTION="mongodb://fabmedical-cdb-lnt:OertNdMqlVVl8Kpn6nnwSu9lMGZMjTbqEl1RoqGniDVK9GGt5YLIY40iz0rgEPIu6No6bTk1EGhEACDbSlLINA==@fabmedical-cdb-lnt.mongo.cosmos.azure.com:10255/contentdb?ssl=true&replicaSet=globaldb&retrywrites=false&maxIdleTimeMS=120000&appName=@fabmedical-cdb-lnt@"

#docker run -ti --rm -e MONGODB_CONNECTION=$dbConnection ghcr.io/lnformbu-insight/fabrikam-init
docker run -ti --rm -e MONGODB_CONNECTION="mongodb://fabmedical-cdb-lnt:OertNdMqlVVl8Kpn6nnwSu9lMGZMjTbqEl1RoqGniDVK9GGt5YLIY40iz0rgEPIu6No6bTk1EGhEACDbSlLINA==@fabmedical-cdb-lnt.mongo.cosmos.azure.com:10255/contentdb?ssl=true&replicaSet=globaldb&retrywrites=false&maxIdleTimeMS=120000&appName=@fabmedical-cdb-lnt@" ghcr.io/lnformbu-insight/fabrikam-init

