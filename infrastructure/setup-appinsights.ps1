#All  variables for infra build
$studentsuffix = "lnt"
$resourcegroupName = "fabmedical-rg-" + $studentsuffix
$location1 = "westus3"
$workspaceName = "fabmedical-law-" + $studentsuffix
$appInsights = "fabmedical-ai-" + $studentsuffix

#Create the following: A log analytics workspace & app insights
<# 
Note.
basic app insights is being deprecated in 2024. The west US 3 region can only support through
a log analytics workspace.So to implement an app insights that won't be deprecated in a year 
#>
az monitor log-analytics workspace create --resource-group $resourcegroupName `
    --workspace-name $workspaceName

az extension add --name application-insights
$ai = az monitor app-insights component create --app $appInsights --location $location1 --kind web -g $resourcegroupName `
    --workspace "/subscriptions/c074675d-209c-429a-a95e-ea35b822e146/resourceGroups/fabmedical-rg-ltn/providers/Microsoft.OperationalInsights/workspaces/fabmedical-law-ltn" `
    --application-type web | ConvertFrom-Json

$global:aiInstKey = $ai.instrumentationKey
$aiConnectionString = $ai.connectionString

#===============================================================================================================================
#configure the app insights instrumentation key and insert it into app.js
$insertString = "appInsights.setup(`"" + $aiInstKey + "`");"
(Get-Content ../content-web/app.js) -Replace "appInsights\.setup\(\`"*\S*\`"*\);", $insertString | Set-Content ../content-web/app.js

#commit the updated app.js
git add . ../content-web/app.js
git commit -m "added new aiInstKey to app.js"
git push

#push will trigger our AZ pipeline to build and deploy our application. 


