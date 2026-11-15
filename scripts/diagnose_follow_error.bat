@echo off
echo ========================================
echo Diagnosing Follow/Unfollow Error
echo ========================================
echo.

echo COMMON CAUSES:
echo.
echo 1. FIRESTORE RULES - Permission denied
echo 2. NULL USER - Auth state not loaded
echo 3. NETWORK ERROR - Firebase connection issue
echo 4. STREAM ERROR - Provider stream failed
echo.

echo CHECKING STEPS:
echo.
echo Step 1: Run app with console logs
echo   flutter run --verbose
echo.
echo Step 2: Look for these errors:
echo   - "permission-denied"
echo   - "null check operator"
echo   - "Bad state: Stream has already been listened to"
echo   - "Failed host lookup"
echo.
echo Step 3: Check Firestore Rules
echo   firebase deploy --only firestore:rules
echo.
echo Step 4: Check Auth State
echo   - Is user logged in?
echo   - Is user.uid available?
echo   - Is profile loaded?
echo.

echo QUICK FIXES:
echo.
echo Fix 1: Restart app completely
echo   - Close app
echo   - flutter clean
echo   - flutter run
echo.
echo Fix 2: Check internet connection
echo   - Ensure WiFi/Data is on
echo   - Try opening browser
echo.
echo Fix 3: Clear app data
echo   - Uninstall app
echo   - Reinstall
echo   - Login again
echo.

echo EXPECTED CONSOLE LOGS:
echo.
echo When clicking follow button:
echo   🔄 FollowProvider: followUser called for [userId]
echo   📝 Current user: [currentUserId]
echo   ⏳ Loading state set to true
echo   🔄 Calling FollowService.followUser...
echo   ✅ FollowService.followUser completed
echo   ✅ Follow completed successfully
echo.

echo If you see error instead:
echo   ❌ Follow error: [error message]
echo.

echo Please share the EXACT error message from console!
echo.

pause
