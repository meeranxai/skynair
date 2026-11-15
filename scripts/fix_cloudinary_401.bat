@echo off
chcp 65001 >nul
echo ========================================
echo Cloudinary 401 Error Fix
echo ========================================
echo.
echo URDU GUIDE: CLOUDINARY_401_FIX_URDU.md
echo ENGLISH GUIDE: CLOUDINARY_PRESET_FIX_STEPS.md
echo.
echo ========================================
echo Quick Steps (2 minutes):
echo ========================================
echo.
echo 1. Cloudinary Dashboard kholo
echo 2. Settings → Upload → Upload presets
echo 3. g_network_preset par click karo
echo 4. Signing Mode: Unsigned select karo
echo 5. Save button par click karo
echo.
echo ========================================
echo Current Settings:
echo ========================================
echo Cloud Name: dqhkwsqhi
echo Preset Name: g_network_preset
echo Required Mode: Unsigned ✓
echo.
echo ========================================
echo Press any key to open Cloudinary...
pause >nul
start https://cloudinary.com/console/settings/upload
echo.
echo ✓ Cloudinary dashboard opened in browser
echo.
echo ========================================
echo After changing to Unsigned mode:
echo ========================================
echo 1. Click Save in Cloudinary
echo 2. Come back here
echo 3. Press any key to test upload
echo.
pause >nul
echo.
echo Starting app to test upload...
echo.
flutter run
