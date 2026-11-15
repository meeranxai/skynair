@echo off
echo ========================================
echo Firebase Firestore Indexes Deployment
echo ========================================
echo.

echo Step 1: Login to Firebase (if not already logged in)
firebase login

echo.
echo Step 2: List available projects
firebase projects:list

echo.
echo Step 3: Set your project (replace YOUR_PROJECT_ID with your actual project ID)
echo firebase use YOUR_PROJECT_ID

echo.
echo Step 4: Deploy indexes
echo firebase deploy --only firestore:indexes

echo.
echo ========================================
echo Manual Steps Required:
echo 1. Run: firebase login
echo 2. Run: firebase use YOUR_PROJECT_ID
echo 3. Run: firebase deploy --only firestore:indexes
echo ========================================
pause