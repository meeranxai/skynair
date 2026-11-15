@echo off
echo ========================================
echo Firebase Issues Fix Script
echo ========================================
echo.
echo This script will help you fix:
echo 1. Firestore Indexes
echo 2. Storage Rules
echo 3. Firestore Rules
echo.
echo ========================================
echo Step 1: Checking Firebase Login
echo ========================================
echo.

firebase login:list

echo.
echo ========================================
echo Step 2: Deploying Firestore Indexes
echo ========================================
echo.
echo Deploying indexes from firestore.indexes.json...
echo.

firebase deploy --only firestore:indexes

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Failed to deploy indexes!
    echo.
    echo Please do manually:
    echo 1. Go to https://console.firebase.google.com
    echo 2. Select your project
    echo 3. Go to Firestore Database - Indexes
    echo 4. Create indexes from QUICK_FIX_ALL_ISSUES.md
    echo.
    pause
)

echo.
echo ========================================
echo Step 3: Deploying Storage Rules
echo ========================================
echo.

firebase deploy --only storage

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Failed to deploy storage rules!
    echo.
    echo Please do manually:
    echo 1. Go to https://console.firebase.google.com
    echo 2. Select your project
    echo 3. Go to Storage - Rules
    echo 4. Copy rules from QUICK_FIX_ALL_ISSUES.md
    echo.
    pause
)

echo.
echo ========================================
echo Step 4: Deploying Firestore Rules
echo ========================================
echo.

firebase deploy --only firestore:rules

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Failed to deploy firestore rules!
    echo.
    echo Please do manually:
    echo 1. Go to https://console.firebase.google.com
    echo 2. Select your project
    echo 3. Go to Firestore Database - Rules
    echo 4. Copy rules from QUICK_FIX_ALL_ISSUES.md
    echo.
    pause
)

echo.
echo ========================================
echo All Done!
echo ========================================
echo.
echo Please wait 2-3 minutes for indexes to build.
echo Then restart your app and test:
echo.
echo 1. Upload profile picture
echo 2. Create a post
echo 3. View feed
echo 4. Follow/unfollow
echo.
echo If you see any errors, check:
echo - QUICK_FIX_ALL_ISSUES.md for manual steps
echo - Firebase Console for index status
echo.
pause
