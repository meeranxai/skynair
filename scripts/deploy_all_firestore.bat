@echo off
echo ========================================
echo Firebase Firestore Complete Deployment
echo (Rules + Indexes)
echo ========================================
echo.

echo Checking Firebase CLI...
firebase --version
if errorlevel 1 (
    echo ERROR: Firebase CLI not installed!
    echo Install: npm install -g firebase-tools
    pause
    exit /b 1
)

echo.
echo Logging in to Firebase...
call firebase login

echo.
echo Selecting project: studio-2145172646-5b4a0
call firebase use studio-2145172646-5b4a0

echo.
echo Deploying Firestore Rules and Indexes...
call firebase deploy --only firestore

echo.
echo ========================================
echo Firestore Deployment Complete!
echo ========================================
echo.
echo Deployed:
echo - Security Rules (firestore.rules)
echo - Indexes (firestore.indexes.json)
echo.
echo Note: Indexes may take 5-10 minutes to build.
echo Check status: https://console.firebase.google.com/project/studio-2145172646-5b4a0/firestore
echo.
pause
