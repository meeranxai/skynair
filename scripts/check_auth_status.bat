@echo off
echo ========================================
echo Checking Authentication Status
echo ========================================
echo.
echo This will help diagnose if you're logged in or not.
echo.
echo Please check in your app:
echo.
echo 1. Are you on the LOGIN screen?
echo    - If YES: You need to login again
echo    - If NO: Continue to step 2
echo.
echo 2. Can you see your profile picture in top-right?
echo    - If YES: You are logged in
echo    - If NO: You are logged out
echo.
echo 3. Try to logout and login again:
echo    - Go to Settings
echo    - Click Logout
echo    - Login with your email/password
echo    - Check if data loads now
echo.
echo ========================================
echo Common Reasons for Permission Denied:
echo ========================================
echo.
echo 1. NOT LOGGED IN
echo    - Solution: Login again
echo.
echo 2. AUTH TOKEN EXPIRED
echo    - Solution: Logout and login again
echo.
echo 3. WRONG FIREBASE PROJECT
echo    - Solution: Check firebase_options.dart
echo.
echo 4. INTERNET CONNECTION
echo    - Solution: Check WiFi/mobile data
echo.
echo 5. FIREBASE RULES NOT DEPLOYED
echo    - Solution: Run deploy_firestore_rules.bat
echo.
pause
