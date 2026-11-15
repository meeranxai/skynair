@echo off
cd /d "%~dp0"
set "JAVA_HOME=E:\Android Studio\jbr"
set "PATH=%JAVA_HOME%\bin;%PATH%"
echo ========================================
echo Building Skynaire Android APK (Optimized)
echo ========================================
echo.

echo Step 1: Cleaning previous builds...
call flutter clean
echo.

echo Step 2: Getting dependencies...
call flutter pub get
echo.

echo Step 3: Building APK (Release mode with --split-per-abi)...
call flutter build apk --release --split-per-abi
echo.

if errorlevel 1 (
    echo ========================================
    echo ERROR: APK build failed!
    echo ========================================
    pause
    exit /b 1
)

echo ========================================
echo SUCCESS! APKs Built Successfully
echo ========================================
echo.
echo APK Location:
echo build\app\outputs\flutter-apk\
echo.
echo You can now install the appropriate APK on your Android device!
echo (Usually arm64-v8a for modern phones)
echo.
pause
