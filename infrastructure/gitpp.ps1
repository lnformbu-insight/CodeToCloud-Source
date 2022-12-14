#commit the updated app.js
git pull https://github.com/lnformbu-insight/CodeToCloud-Source
git config --global user.email "lnformbu-insight@insight.com"
git config --global user.name "Lenon Nformbui"
git add ../content-web/app.js
git commit -m "added new aiInstKey to app.js"
git push
#wait 5 minutes to make sure new container has been pushed to github container registry
Start-Sleep -Seconds 250