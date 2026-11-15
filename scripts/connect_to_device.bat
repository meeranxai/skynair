@echo off
echo ========================================
echo G-Network Flutter - Device Connection
echo ========================================
echo.

echo Step 1: Checking Flutter installation...
flutter --version
echo.

echo Step 2: Checking connected devices...
flutter devices
echo.

echo Step 3: If you see your Android device above, great!
echo         If not, please follow these steps:
echo.
echo   Android Device Setup:
echo   1. Enable Developer Options (Settings > About Phone > Tap Build Number 7 times)
echo   2. Enable USB Debugging (Settings > Developer Options > USB Debugging ON)
echo   3. Connect USB cable
echo   4. Allow USB Debugging when prompted on phone
echo.

pause

echo Step 4: Running app on connected device...
echo.
flutter run

pause