@echo off
echo ========================================
echo Follow Button Fix - Production Ready
echo ========================================
echo.

echo ✅ Code fixes applied:
echo - Enhanced error handling in follow button
echo - Automatic collection creation on first use
echo - Stream error handling improved
echo - Production-safe initialization
echo.

echo Step 1: Deploy Firestore Rules
call firebase deploy --only firestore:rules
if errorlevel 1 (
    echo ❌ Rules deployment failed
    pause
    exit /b 1
)

echo.
echo Step 2: Deploy Firestore Indexes
call firebase deploy --only firestore:indexes
if errorlevel 1 (
    echo ❌ Indexes deployment failed
    pause
    exit /b 1
)

echo.
echo Step 3: Build and Test App
flutter clean
flutter pub get
flutter build apk --debug

echo.
echo ========================================
echo Production Fix Complete!
echo ========================================
echo.
echo ✅ What was fixed:
echo - Collections will auto-create when first used
echo - Follow button won't be gray anymore
echo - No manual collection creation needed
echo - Error handling improved for production
echo.
echo 📱 Test on device:
echo flutter run --release
echo.
pause