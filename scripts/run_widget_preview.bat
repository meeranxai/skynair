@echo off
echo Starting Flutter Widget Preview Mode on Web...
echo.

REM Check if Chrome is available
flutter devices | findstr "chrome" >nul
if %errorlevel% neq 0 (
    echo Chrome not found. Please make sure Chrome is installed.
    pause
    exit /b 1
)

echo Running widget preview on Chrome...
echo This will open your widgets in a web browser for preview and inspection.
echo.

REM Run the widget preview app on Chrome
flutter run lib/preview/main_preview.dart -d chrome

if %errorlevel% neq 0 (
    echo.
    echo Failed to start widget preview. Trying alternative approach...
    echo.
    
    REM Try running the main app instead
    flutter run lib/main.dart -d chrome
)

pause