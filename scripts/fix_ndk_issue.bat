@echo off
echo ========================================
echo Fixing NDK Issue
echo ========================================
echo.

echo Problem: Corrupted NDK download at E:\x\ndk\27.0.12077973
echo Solution: Remove NDK version specification, let Gradle auto-download
echo.

echo Step 1: Clean build
echo -----------------------------------------
flutter clean
echo.

echo Step 2: Delete corrupted NDK (optional)
echo -----------------------------------------
echo If issue persists, manually delete:
echo E:\x\ndk\27.0.12077973
echo.
echo Then Gradle will auto-download correct version
echo.

echo Step 3: Rebuild
echo -----------------------------------------
flutter pub get
flutter run
echo.

pause
