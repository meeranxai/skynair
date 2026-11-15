@echo off
echo ============================================
echo FIXING PROFILE POSTS LOADING ISSUE
echo ============================================
echo.

echo 1. Deploying missing Firestore indexes...
firebase deploy --only firestore:indexes

echo.
echo 2. Checking Firebase project status...
firebase use

echo.
echo 3. Testing profile posts loading...
echo.
echo MANUAL TEST STEPS:
echo 1. Open app: flutter run -d chrome
echo 2. Login with your account
echo 3. Go to your profile (bottom nav)
echo 4. Check if your posts load properly
echo 5. Visit another user's profile
echo 6. Check if their posts load (no spinning error)
echo.

echo 4. Common issues and solutions:
echo.
echo ISSUE: Spinning loader stuck
echo SOLUTION: Wait 2-3 minutes for indexes to build
echo.
echo ISSUE: "Error loading posts"
echo SOLUTION: Check browser console (F12) for errors
echo.
echo ISSUE: Empty profile (no posts showing)
echo SOLUTION: Create a test post first
echo.

echo 5. Browser console debugging:
echo - Press F12 in browser
echo - Go to Console tab
echo - Look for Firestore errors
echo - Check for "Missing index" messages
echo.

echo ============================================
echo FIREBASE CONSOLE LINKS:
echo Indexes: https://console.firebase.google.com/project/studio-2145172646-5b4a0/firestore/indexes
echo Data: https://console.firebase.google.com/project/studio-2145172646-5b4a0/firestore/data
echo ============================================

pause