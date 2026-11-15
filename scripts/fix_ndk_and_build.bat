@echo off
echo ========================================
echo NDK Fix and APK Build Script
echo ========================================
echo.

echo [Step 1] Deleting corrupted NDK...
echo Location: E:\x\ndk\27.0.12077973
echo.

if exist "E:\x\ndk\27.0.12077973" (
    echo Deleting NDK folder...
    rmdir /s /q "E:\x\ndk\27.0.12077973"
    echo NDK folder deleted successfully!
) else (
    echo NDK folder not found or already deleted.
)

echo.
echo [Step 2] Cleaning Flutter build cache...
flutter clean

echo.
echo [Step 3] Getting Flutter dependencies...
flutter pub get

echo.
echo [Step 4] Building release APK...
echo Android Gradle Plugin will automatically download NDK...
echo This may take 5-10 minutes...
echo.

flutter build apk --release

echo.
echo ========================================
if %ERRORLEVEL% EQU 0 (
    echo ✅ APK Build Successful!
    echo.
    echo APK Location:
    echo build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo File size:
    dir build\app\outputs\flutter-apk\app-release.apk
) else (
    echo ❌ Build Failed!
    echo.
    echo Troubleshooting:
    echo 1. Check internet connection for NDK download
    echo 2. Run: flutter doctor -v
    echo 3. Check Android SDK installation
    echo 4. Try: flutter clean then flutter build apk
)
echo ========================================

pause
