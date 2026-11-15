@echo off
echo ========================================
echo Firebase Project Setup
echo ========================================
echo.

echo Step 1: Check Firebase CLI
firebase --version
if errorlevel 1 (
    echo ❌ Firebase CLI not installed!
    echo Please install: npm install -g firebase-tools
    pause
    exit /b 1
)

echo.
echo Step 2: Login to Firebase
firebase login
if errorlevel 1 (
    echo ❌ Firebase login failed
    pause
    exit /b 1
)

echo.
echo Step 3: List available projects
echo Available Firebase projects:
firebase projects:list

echo.
echo Step 4: Initialize or use existing project
echo.
echo Choose option:
echo 1. Use existing project
echo 2. Create new project
echo.
set /p choice="Enter choice (1 or 2): "

if "%choice%"=="1" (
    echo.
    echo Available projects listed above.
    set /p project_id="Enter project ID: "
    firebase use --add %project_id%
    if errorlevel 1 (
        echo ❌ Failed to set project
        pause
        exit /b 1
    )
    echo ✅ Project set successfully
) else if "%choice%"=="2" (
    echo.
    echo Creating new project...
    echo Please go to: https://console.firebase.google.com
    echo 1. Click "Create a project"
    echo 2. Enter project name
    echo 3. Enable Google Analytics (optional)
    echo 4. Wait for project creation
    echo.
    echo After creating project, come back and run this script again with option 1
    pause
    exit /b 0
) else (
    echo ❌ Invalid choice
    pause
    exit /b 1
)

echo.
echo Step 5: Initialize Firebase features
firebase init
if errorlevel 1 (
    echo ❌ Firebase init failed
    pause
    exit /b 1
)

echo.
echo ========================================
echo Firebase Setup Complete!
echo ========================================
echo.
echo ✅ Next steps:
echo 1. Run: fix_follow_button_final.bat
echo 2. Test your app
echo.
pause