@echo off
echo ========================================
echo Firestore Connection Fix
echo ========================================
echo.
echo This will try to fix Firestore connection issues.
echo.
echo Step 1: Cleaning build cache...
echo ========================================
flutter clean

echo.
echo Step 2: Getting dependencies...
echo ========================================
flutter pub get

echo.
echo Step 3: Checking Firestore rules...
echo ========================================
type firestore.rules

echo.
echo Step 4: Checking Firebase config...
echo ========================================
type lib\core\config\firebase_config.dart

echo.
echo Step 5: Deploying Firestore rules (if needed)...
echo ========================================
echo Run this command manually if rules need update:
echo firebase deploy --only firestore:rules
echo.

echo.
echo ========================================
echo Fix Complete!
echo ========================================
echo.
echo Now try running the app:
echo flutter run
echo.
pause
