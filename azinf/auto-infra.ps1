$script:studentprefix = "ltn"
$script:resourcegroupName = "fabmedical-rg-" + $studentsuffix
$script:webappName = "fabmedical-web-" + $studentsuffix
$script:workspaceName = "fabmedical-law-" + $studentsuffix
$script:location1 = "westus3"
$script:CR_PAT = $CR_PAT

#login to github
git config --global user.email "lnformbu-insight@insight.com"
git config --global user.name "Lenon Nformbui"

#Create the following:
#log analytics workspace: fabmedical-law-add / app insights: fabmedical-ai-add
& .\deploy-infra.ps1
& .\deploy-ai.ps1
#configure the app insights instrumentation key and insert it into app.js
$insertString = "appInsights.setup(`"" + $aiInstKey + "`");"
(Get-Content ../content-web/app.js) -Replace "appInsights\.setup\(\`"*\S*\`"*\);", $insertString | Set-Content ../content-web/app.js
 
#commit the updated app.js
& .\gitpp.ps1

#re-deploy the web container to the application
& .\deploy-container.ps1


