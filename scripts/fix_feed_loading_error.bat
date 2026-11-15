@echo off
echo ============================================
echo FIXING FEED LOADING ERROR
echo ============================================
echo.

echo 1. Deploying Firestore indexes...
firebase deploy --only firestore:indexes

echo.
echo 2. Checking Firebase project status...
firebase use

echo.
echo 3. Testing app with fresh build...
flutter clean
flutter pub get

echo.
echo 4. Running app in debug mode...
echo Choose your platform:
echo [1] Chrome (Web)
echo [2] Android Device
echo [3] Windows Desktop
echo.
set /p choice="Enter choice (1-3): "

if "%choice%"=="1" (
    echo Starting on Chrome...
    flutter run -d chrome --debug
) else if "%choice%"=="2" (
    echo Starting on Android...
    flutter run -d android --debug
) else if "%choice%"=="3" (
    echo Starting on Windows...
    flutter run -d windows --debug
) else (
    echo Invalid choice. Starting on Chrome by default...
    flutter run -d chrome --debug
)

echo.
echo ============================================
echo TROUBLESHOOTING STEPS IF STILL FAILING:
echo 1. Check browser console for errors (F12)
echo 2. Verify user is logged in and email verified
echo 3. Check Firebase Console for Firestore data
echo 4. Wait 2-3 minutes for indexes to build
echo ============================================
pause