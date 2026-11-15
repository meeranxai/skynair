@echo off
echo G-Network Flutter App - Device Connection
echo ==========================================
echo.

echo Step 1: Checking connected devices...
flutter devices

echo.
echo Step 2: If you see your device listed above, press Enter to continue.
echo         If not, please:
echo         1. Enable USB Debugging on your Android phone
echo         2. Connect via USB cable
echo         3. Run this script again
echo.
pause

echo Step 3: Running app on connected device...
flutter run

pause