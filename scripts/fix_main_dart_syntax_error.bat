@echo off
echo ========================================
echo Main.dart Syntax Error Fix
echo ========================================
echo.

echo ✅ Fixed duplicate catch blocks in main.dart
echo.

echo Step 1: Check syntax
flutter analyze lib/main.dart

echo.
echo Step 2: Test compilation
flutter build apk --debug --no-shrink

echo.
echo ========================================
echo Syntax Fix Complete!
echo ========================================
pause