@echo off
echo Setting up Android SDK for APK build...
echo.

REM Check if Android Studio is installed
if exist "C:\Program Files\Android\Android Studio\bin\studio64.exe" (
    echo Android Studio found!
    goto :build_apk
)

if exist "%LOCALAPPDATA%\Android\Sdk" (
    echo Android SDK found in local directory
    flutter config --android-sdk "%LOCALAPPDATA%\Android\Sdk"
    goto :build_apk
)

echo Android SDK not found. Please install Android Studio first.
echo Download from: https://developer.android.com/studio
echo.
echo After installation, run this script again.
pause
exit /b 1

:build_apk
echo Building APK...
flutter clean
flutter pub get
flutter build apk --release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✓ APK built successfully!
    echo Location: build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo To install on device:
    echo 1. Enable Developer Options on your Android device
    echo 2. Enable USB Debugging
    echo 3. Connect device via USB
    echo 4. Run: flutter install --release
) else (
    echo.
    echo ✗ APK build failed. Check the error messages above.
    echo Try running: flutter doctor
)

pause