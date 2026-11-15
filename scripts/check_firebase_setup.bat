@echo off
echo ========================================
echo Firebase Setup Checker
echo ========================================
echo.

echo Step 1: Check Firebase CLI
firebase --version
if errorlevel 1 (
    echo ❌ Firebase CLI not installed
    echo Install with: npm install -g firebase-tools
    echo.
    goto :end
)
echo ✅ Firebase CLI installed

echo.
echo Step 2: Check login status
firebase login:list
if errorlevel 1 (
    echo ❌ Not logged in to Firebase
    echo Run: firebase login
    echo.
    goto :end
)
echo ✅ Logged in to Firebase

echo.
echo Step 3: Check active project
firebase use
if errorlevel 1 (
    echo ❌ No active Firebase project
    echo.
    echo Solutions:
    echo 1. List projects: firebase projects:list
    echo 2. Use project: firebase use PROJECT_ID
    echo 3. Or run: setup_firebase_project.bat
    echo.
    goto :end
)
echo ✅ Active Firebase project found

echo.
echo Step 4: Check firebase.json
if exist firebase.json (
    echo ✅ firebase.json exists
) else (
    echo ❌ firebase.json missing
    echo Run: firebase init
    echo.
    goto :end
)

echo.
echo ========================================
echo Firebase Setup Status: ✅ READY
echo ========================================
echo.
echo You can now run:
echo - firebase deploy --only firestore:rules
echo - firebase deploy --only firestore:indexes
echo - fix_follow_button_production.bat
echo.
goto :end

:end
pause