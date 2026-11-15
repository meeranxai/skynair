@echo off
echo ========================================
echo Fixing Gradle Deprecated Option
echo ========================================
echo.

echo [INFO] The error was caused by deprecated option:
echo        android.enableBuildCache=true
echo.
echo [FIX] This option has been removed from gradle.properties
echo       Using org.gradle.caching=true instead (already enabled)
echo.

echo [1/2] Cleaning build cache...
flutter clean
echo.

echo [2/2] Rebuilding...
echo.
echo Ready to build! Run: build_new_apk.bat
echo.
pause
