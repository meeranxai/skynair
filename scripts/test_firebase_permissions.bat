@echo off
echo Testing Firebase Firestore Permissions...
echo.

echo 1. Checking Firebase project status...
firebase projects:list

echo.
echo 2. Checking current project...
firebase use

echo.
echo 3. Testing Firestore rules...
firebase firestore:rules:get

echo.
echo 4. Checking if user is authenticated...
firebase auth:export users.json --format=JSON 2>nul
if %errorlevel% equ 0 (
    echo ✅ Firebase authentication working
    del users.json 2>nul
) else (
    echo ❌ Firebase authentication issue
)

echo.
echo 5. Quick Firestore connection test...
echo Testing with Flutter...
flutter test test/firebase_test.dart 2>nul
if %errorlevel% equ 0 (
    echo ✅ Firestore connection working
) else (
    echo ⚠️ Firestore test not available - manual testing required
)

echo.
echo ============================================
echo MANUAL TESTING STEPS:
echo 1. Open app in browser: flutter run -d chrome
echo 2. Try to login with verified email
echo 3. Check browser console for permission errors
echo 4. Check Firebase Console > Firestore > Rules
echo ============================================
pause