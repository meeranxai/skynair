@echo off
echo Checking APK build status...
echo.

if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo ========================================
    echo APK BUILD COMPLETE!
    echo ========================================
    echo.
    dir "build\app\outputs\flutter-apk\*.apk"
    echo.
    echo APK Location: build\app\outputs\flutter-apk\app-release.apk
    echo.
) else (
    echo Build still in progress...
    echo.
    echo Checking Java/Gradle processes:
    tasklist | findstr /i "java.exe gradle"
    echo.
    echo Run this script again in a few minutes to check status.
)

pause
