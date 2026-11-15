@echo off
echo ========================================
echo Block/Unblock aur Follow Request Indexes Deploy
echo ========================================
echo.

echo Step 1: Firebase login check...
call firebase login:list
if errorlevel 1 (
    echo Firebase login required!
    call firebase login
)

echo.
echo Step 2: Deploying indexes...
call firebase deploy --only firestore:indexes

echo.
echo ========================================
echo Deployment Complete!
echo ========================================
echo.
echo Indexes deployed:
echo - blockList (blockerId + blockedAt)
echo - blockList (blockedId + blockedAt)
echo - followRequests (toUserId + status + createdAt)
echo - followRequests (fromUserId + status + createdAt)
echo.
echo Firebase Console mein check karein:
echo https://console.firebase.google.com/project/_/firestore/indexes
echo.
pause
