@echo off
cd /d "%~dp0"
set "JAVA_HOME=E:\Android Studio\jbr"
set "PATH=%JAVA_HOME%\bin;%PATH%"
echo ========================================
echo Quick APK Build - Split Per ABI
echo (Faster than regular build)
echo ========================================
echo.

echo Stopping existing Gradle processes...
taskkill /F /IM java.exe /T 2>nul
taskkill /F /IM gradle.exe /T 2>nul

echo.
echo Cleaning Flutter...
call flutter clean

echo.
echo Getting dependencies...
call flutter pub get

echo.
echo Building split APKs (3 smaller files)...
echo This will take 5-10 minutes...
call flutter build apk --release --split-per-abi

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo.
echo APKs created:
dir build\app\outputs\flutter-apk\*.apk

echo.
echo Which APK to use:
echo - app-arm64-v8a-release.apk (Most modern phones - USE THIS)
echo - app-armeabi-v7a-release.apk (Older phones)
echo - app-x86_64-release.apk (Emulators only)
echo.
pause
