@echo off
chcp 65001 >nul
echo ========================================
echo Cloudinary 401 Debug - Detailed Check
echo ========================================
echo.
echo Checking all possible issues...
echo.
echo ========================================
echo Step 1: Verify Preset Settings
echo ========================================
echo.
echo Please check in Cloudinary Dashboard:
echo 1. Go to: https://cloudinary.com/console/settings/upload
echo 2. Find: g_network_preset
echo 3. Verify these settings:
echo.
echo    Signing Mode: Unsigned (NOT Signed)
echo    Status: Active (NOT Disabled)
echo.
echo Is the preset showing "Unsigned"? (y/n)
set /p PRESET_CHECK=
echo.
if /i "%PRESET_CHECK%"=="n" (
    echo ERROR: Preset is still in Signed mode!
    echo Please change it to Unsigned and save.
    echo.
    start https://cloudinary.com/console/settings/upload
    pause
    exit /b
)
echo.
echo ========================================
echo Step 2: Check Code Settings
echo ========================================
echo.
echo Checking firestore_service.dart...
echo.
findstr /n /c:"CloudinaryPublic" lib\core\services\firestore_service.dart
echo.
echo Should show:
echo   CloudinaryPublic('dqhkwsqhi', 'g_network_preset', cache: false)
echo.
echo Is this correct? (y/n)
set /p CODE_CHECK=
echo.
if /i "%CODE_CHECK%"=="n" (
    echo ERROR: Code settings are wrong!
    echo Please check the file.
    pause
    exit /b
)
echo.
echo ========================================
echo Step 3: Test Cloudinary Connection
echo ========================================
echo.
echo Testing if Cloudinary is reachable...
echo.
curl -s -o nul -w "Status: %%{http_code}\n" https://api.cloudinary.com/v1_1/dqhkwsqhi/image/list
echo.
echo If status is 200 or 401, Cloudinary is reachable.
echo If status is 000 or timeout, network issue.
echo.
pause
echo.
echo ========================================
echo Step 4: Clean Build
echo ========================================
echo.
echo Cleaning Flutter cache...
echo.
flutter clean
echo.
echo Getting dependencies...
echo.
flutter pub get
echo.
echo ========================================
echo Step 5: Run App with Verbose Logging
echo ========================================
echo.
echo Starting app...
echo Watch for Cloudinary upload errors in console.
echo.
echo Look for these messages:
echo   - "Uploading to Cloudinary..."
echo   - "Cloud Name: dqhkwsqhi"
echo   - "Preset: g_network_preset"
echo   - Any 401 error details
echo.
pause
echo.
flutter run -v
