@echo off
echo ========================================
echo Fixing All Build Errors
echo ========================================
echo.

echo [INFO] Fixed Issues:
echo   1. Updated compileSdk: 35 -^> 36
echo   2. Updated targetSdk: 35 -^> 36
echo   3. Removed deprecated android.enableBuildCache
echo   4. Configured Java 17 toolchain
echo.

echo [STEP 1/3] Cleaning build cache...
flutter clean
if errorlevel 1 (
    echo [ERROR] Flutter clean failed
    pause
    exit /b 1
)
echo [OK] Clean complete
echo.

echo [STEP 2/3] Getting dependencies...
flutter pub get
if errorlevel 1 (
    echo [ERROR] Pub get failed
    pause
    exit /b 1
)
echo [OK] Dependencies fetched
echo.

echo [STEP 3/3] Ready to build!
echo.
echo ========================================
echo All fixes applied successfully!
echo ========================================
echo.
echo Next step: Run build_new_apk.bat
echo.
echo Note: If Java 17 error persists:
echo   - Gradle will auto-download Java 17
echo   - Or install Java 17 manually from:
echo     https://adoptium.net/temurin/releases/
echo.
pause
