@echo off
echo ===========================================
echo   FORCE CLEANING BUILD DIRECTORY
echo ===========================================
echo.

echo 1. Stopping Gradle Daemons...
cd android
call gradlew --stop
cd ..

echo.
echo 2. Killing lingering Java processes (if any)...
taskkill /F /IM java.exe /T 2>NUL
taskkill /F /IM dart.exe /T 2>NUL

echo.
echo 3. Attempting to remove build directory...
rmdir /s /q build
if exist build (
    echo.
    echo WARNING: Could not fully remove 'build' directory.
    echo Some files might still be locked.
    echo.
    echo Please close any other VS Code windows or emulators and try again.
) else (
    echo Build directory removed.
)

echo.
echo 4. Running Flutter Clean...
call flutter clean

echo.
echo 5. Getting Dependencies...
call flutter pub get

echo.
echo ===========================================
echo   READY TO BUILD
echo ===========================================
echo.
pause
