@echo off
echo ========================================
echo Firebase Firestore Indexes Deployment
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
echo Deploying Firestore Indexes...
call firebase deploy --only firestore:indexes

echo.
echo ========================================
echo Firestore Indexes Deployed Successfully!
echo ========================================
echo.
echo Note: Indexes may take 5-10 minutes to build.
echo Check status in Firebase Console:
echo https://console.firebase.google.com/project/studio-2145172646-5b4a0/firestore/indexes
echo.
pause
