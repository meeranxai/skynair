@echo off
echo ========================================
echo Skynaire - APKPure Release Preparation
echo ========================================
echo.

echo Step 1: Cleaning previous builds...
call flutter clean
echo ✓ Clean complete
echo.

echo Step 2: Getting dependencies...
call flutter pub get
echo ✓ Dependencies installed
echo.

echo Step 3: Running code generation...
call flutter packages pub run build_runner build --delete-conflicting-outputs
echo ✓ Code generation complete
echo.

echo Step 4: Building release APK (Universal)...
call flutter build apk --release
echo ✓ Universal APK built
echo.

echo Step 5: Building split APKs (Recommended for APKPure)...
call flutter build apk --release --split-per-abi
echo ✓ Split APKs built
echo.

echo ========================================
echo Build Complete!
echo ========================================
echo.
echo APK Files Location:
echo build\app\outputs\flutter-apk\
echo.
echo Files created:
echo 1. app-release.apk (Universal - ~80MB)
echo 2. app-armeabi-v7a-release.apk (~25MB)
echo 3. app-arm64-v8a-release.apk (~28MB)
echo 4. app-x86_64-release.apk (~30MB)
echo.
echo ========================================
echo Next Steps:
echo ========================================
echo 1. Test APKs on different devices
echo 2. Prepare screenshots (8-10 images)
echo 3. Review APKPURE_LISTING_PACKAGE.md
echo 4. Upload to APKPure
echo.
echo Documentation:
echo - APKPURE_LISTING_PACKAGE.md (Complete guide)
echo - privacy_policy.html (Privacy policy)
echo - terms_of_service.html (Terms of service)
echo.
pause
