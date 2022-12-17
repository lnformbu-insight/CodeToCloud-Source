$studentsuffix = "lnt"
$resourcegroupName = "fabmedical-rg-" + $studentsuffix
$webappName = "fabmedical-web-" + $studentsuffix
$workspaceName = "fabmedical-law-" + $studentsuffix
$appInsights = "fabmedical-ai-" + $studentsuffix
$location1 = "westus3"
$location2 = "eastus"

az extension add --name application-insights
az monitor app-insights component create --app $appInsights --location $location2 --kind web -g $resourcegroupName --application-type web --retention-time 120

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
