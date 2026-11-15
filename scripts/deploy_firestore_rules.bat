@echo off
echo ========================================
echo Deploying Firestore Rules to Firebase
echo ========================================
echo.
echo This will deploy your local firestore.rules to Firebase Console
echo.
echo Step 1: Checking if Firebase CLI is installed...
echo ========================================
firebase --version

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Firebase CLI not installed!
    echo.
    echo Please install Firebase CLI:
    echo npm install -g firebase-tools
    echo.
    echo Then login:
    echo firebase login
    echo.
    pause
    exit /b 1
)

echo.
echo Step 2: Checking Firebase login...
echo ========================================
firebase projects:list

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Not logged in to Firebase!
    echo.
    echo Please login:
    echo firebase login
    echo.
    pause
    exit /b 1
)

echo.
echo Step 3: Deploying Firestore rules...
echo ========================================
firebase deploy --only firestore:rules

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo SUCCESS! Firestore rules deployed!
    echo ========================================
    echo.
    echo Your app should work now.
    echo Try running: flutter run
    echo.
) else (
    echo.
    echo ========================================
    echo ERROR: Failed to deploy rules!
    echo ========================================
    echo.
    echo Please check:
    echo 1. You are logged in: firebase login
    echo 2. Project is selected: firebase use studio-2145172646-5b4a0
    echo 3. You have permission to deploy
    echo.
)

pause
