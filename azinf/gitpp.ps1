#commit the updated app.js
git add ../content-web/app.js
git commit -m "updated aiInstKey in app.js"
git push
#wait 5 minutes to make sure new container has been pushed to github container registry
Start-Sleep -Seconds 250