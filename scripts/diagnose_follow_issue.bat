@echo off
echo ========================================
echo Follow Issue Diagnostic Tool
echo ========================================
echo.
echo This tool will help diagnose why follow is not working.
echo.
echo ========================================
echo Step 1: Check Firestore Rules
echo ========================================
echo.
echo Run this command to check current rules:
echo   firebase firestore:rules:get
echo.
echo Required rules for follows collection:
echo   - allow read: if isAuthenticated()
echo   - allow create: if isAuthenticated() ^&^& request.auth.uid == request.resource.data.followerId
echo   - allow delete: if isAuthenticated() ^&^& request.auth.uid == resource.data.followerId
echo.
echo Required rules for userProfiles:
echo   - allow update for followersCount/followingCount fields
echo.
pause
echo.
echo ========================================
echo Step 2: Check User Profile Fields
echo ========================================
echo.
echo Open Firebase Console and verify:
echo   1. Go to Firestore Database
echo   2. Open userProfiles collection
echo   3. Check your user document
echo   4. Verify these fields exist:
echo      - followersCount: 0
echo      - followingCount: 0
echo.
echo If missing, add them manually in Firebase Console.
echo.
pause
echo.
echo ========================================
echo Step 3: Check Authentication
echo ========================================
echo.
echo Verify user is logged in:
echo   1. Open app
echo   2. Check if user is authenticated
echo   3. Verify user ID is not null
echo.
pause
echo.
echo ========================================
echo Step 4: Test Follow Button
echo ========================================
echo.
echo Testing steps:
echo   1. Navigate to any user profile
echo   2. Open browser console (F12)
echo   3. Click Follow button
echo   4. Check console for errors
echo.
echo Common errors:
echo   - permission-denied: Firestore rules issue
echo   - not-found: User profile missing
echo   - null: Authentication issue
echo.
pause
echo.
echo ========================================
echo Step 5: Deploy Firestore Rules
echo ========================================
echo.
echo If rules are incorrect, deploy updated rules:
echo   firebase deploy --only firestore:rules
echo.
echo This will update the rules in Firebase.
echo.
pause
echo.
echo ========================================
echo Step 6: Run App with Debug
echo ========================================
echo.
echo Running app with verbose logging...
echo Watch console for follow-related messages.
echo.
echo Expected success messages:
echo   ✅ User followed successfully
echo   ✅ Follow notification created
echo   ✅ Socket event emitted
echo.
echo Expected error messages:
echo   ❌ Error following user: [error details]
echo   ❌ Permission denied
echo   ❌ User not found
echo.
echo ========================================
echo Starting Flutter App...
echo ========================================
echo.

flutter run --verbose
