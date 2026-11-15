@echo off
echo Checking APK build status...
echo.

if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo ✓ APK BUILD COMPLETE!
    echo.
    echo APK Location: build\app\outputs\flutter-apk\app-release.apk
    echo.
    for %%A in ("build\app\outputs\flutter-apk\app-release.apk") do (
        echo File Size: %%~zA bytes
        echo Modified: %%~tA
    )
    echo.
    echo You can install this APK on your Android device!
) else (
    echo ⏳ APK not found yet - build may still be in progress...
    echo.
    echo The build process is running in the background.
    echo This can take 5-15 minutes on first build.
    echo.
    echo Run this script again to check status.
)

echo.
pause
