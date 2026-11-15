@echo off
echo ========================================
echo Firestore Collections Manual Setup
echo ========================================
echo.

echo Step 1: Open Firebase Console
echo https://console.firebase.google.com
echo.

echo Step 2: Go to Firestore Database
echo Click on "Firestore Database" in left menu
echo.

echo Step 3: Create "blocks" Collection
echo.
echo - Click "Start collection"
echo - Collection ID: blocks
echo - Document ID: temp_block
echo - Fields:
echo   * blockerId (string): "temp_user1"
echo   * blockedId (string): "temp_user2" 
echo   * createdAt (timestamp): [current time]
echo.

echo Step 4: Create "followRequests" Collection
echo.
echo - Click "Start collection"
echo - Collection ID: followRequests
echo - Document ID: temp_request
echo - Fields:
echo   * followerId (string): "temp_user1"
echo   * followingId (string): "temp_user2"
echo   * status (string): "pending"
echo   * createdAt (timestamp): [current time]
echo.

echo Step 5: Deploy Rules and Indexes
call firebase deploy --only firestore:rules
call firebase deploy --only firestore:indexes

echo.
echo ========================================
echo Collections Created Successfully!
echo ========================================
echo.
echo Next: Test the app - follow button should work now
pause