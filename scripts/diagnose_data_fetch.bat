@echo off
echo ========================================
echo G-Network Data Fetch Diagnostic
echo ========================================
echo.
echo This will help diagnose data fetching issues.
echo.
echo Checking:
echo 1. Code compilation
echo 2. Firebase configuration
echo 3. Network connectivity
echo.
echo ========================================
echo Step 1: Analyzing code...
echo ========================================
echo.

flutter analyze lib/core/services/firestore_service.dart lib/core/providers/posts_provider.dart

echo.
echo ========================================
echo Step 2: Checking Firebase config...
echo ========================================
echo.

type lib\core\config\firebase_config.dart

echo.
echo ========================================
echo Step 3: Check connected devices...
echo ========================================
echo.

flutter devices

echo.
echo ========================================
echo Diagnostic Complete!
echo ========================================
echo.
echo If you see errors above, that's the issue.
echo If no errors, then:
echo 1. Make sure device is connected
echo 2. Make sure internet is working
echo 3. Check Firebase console for data
echo.
pause
