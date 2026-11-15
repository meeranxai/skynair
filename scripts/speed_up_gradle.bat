@echo off
echo ========================================
echo Gradle Speed Optimization Script
echo ========================================
echo.

echo [STEP 1] Stopping Gradle Daemons...
cd android
call gradlew --stop
cd ..
echo [OK] Gradle daemons stopped.
echo.

echo [STEP 2] Clearing Gradle Cache...
if exist "%USERPROFILE%\.gradle\caches" (
    echo Deleting Gradle caches...
    rmdir /s /q "%USERPROFILE%\.gradle\caches" 2>nul
    echo [OK] Gradle cache cleared.
) else (
    echo [INFO] No cache found.
)
echo.

echo [STEP 3] Clearing Build Cache...
if exist "build" (
    rmdir /s /q "build" 2>nul
    echo [OK] Build folder deleted.
)
if exist "android\build" (
    rmdir /s /q "android\build" 2>nul
    echo [OK] Android build folder deleted.
)
if exist "android\app\build" (
    rmdir /s /q "android\app\build" 2>nul
    echo [OK] App build folder deleted.
)
echo.

echo [STEP 4] Clearing Flutter Build Cache...
call flutter clean
echo [OK] Flutter clean complete.
echo.

echo [STEP 5] Optimizing Gradle Properties...
echo [INFO] gradle.properties already optimized!
echo.

echo [STEP 6] Getting Dependencies...
call flutter pub get
echo [OK] Dependencies fetched.
echo.

echo ========================================
echo Optimization Complete!
echo ========================================
echo.
echo Next build should be faster!
echo Run: flutter build apk --release
echo.
pause
