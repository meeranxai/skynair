@echo off
echo ========================================
echo Firebase Storage Rules Deployment
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
echo Deploying Storage Rules...
call firebase deploy --only storage

echo.
echo ========================================
echo Storage Rules Deployed Successfully!
echo ========================================
pause
