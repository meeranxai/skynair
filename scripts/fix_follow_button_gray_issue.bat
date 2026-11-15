@echo off
echo ========================================
echo Follow Button Gray Issue Fix
echo ========================================
echo.

echo Step 1: Creating missing Firestore collections...
echo.

echo Creating blocks collection...
echo - Open Firebase Console
echo - Go to Firestore Database
echo - Create collection: blocks
echo - Add dummy document: temp_doc with field: temp = true
echo.

echo Creating followRequests collection...
echo - Create collection: followRequests  
echo - Add dummy document: temp_doc with field: temp = true
echo.

echo Step 2: Deploy Firestore rules...
call firebase deploy --only firestore:rules

echo.
echo Step 3: Deploy indexes...
call firebase deploy --only firestore:indexes

echo.
echo Step 4: Test follow button...
echo - Open app
echo - Go to any user profile
echo - Check if follow button is working
echo.

echo ========================================
echo Fix Complete!
echo ========================================
pause