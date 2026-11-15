@echo off
echo ========================================
echo Fixing Gradle Issues and Building APK
echo ========================================
echo.

echo Step 1: Killing all Java processes...
taskkill /F /IM java.exe 2>nul
timeout /t 2 >nul

echo.
echo Step 2: Cleaning Flutter build...
call flutter clean

echo.
echo Step 3: Removing Gradle cache...
rmdir /s /q "%USERPROFILE%\.gradle\caches" 2>nul
rmdir /s /q "%USERPROFILE%\.gradle\daemon" 2>nul
rmdir /s /q "android\.gradle" 2>nul
rmdir /s /q "android\build" 2>nul

echo.
echo Step 4: Getting dependencies...
call flutter pub get

echo.
echo Step 5: Generating code...
call flutter pub run build_runner build --delete-conflicting-outputs

echo.
echo Step 6: Building APK with increased memory...
echo This may take 10-15 minutes...
call flutter build apk --release --no-tree-shake-icons

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo.

dir build\app\outputs\flutter-apk\app-release.apk

echo.
pause
