@echo off
echo ========================================
echo 🔒 Deploying Secure Firestore Rules
echo ========================================
echo.

echo 📋 Changes:
echo   ✅ Fixed admin check (custom claims)
echo   ✅ Secured message privacy
echo   ✅ Protected counters
echo   ✅ Fixed chat list rule
echo   ✅ Added spam prevention
echo.

echo ⚠️  IMPORTANT: Set admin custom claims after deployment!
echo    See: FIRESTORE_RULES_SECURITY_FIX.md
echo.

pause

echo.
echo 🚀 Deploying rules...
firebase deploy --only firestore:rules

echo.
if %ERRORLEVEL% EQU 0 (
    echo ✅ Rules deployed successfully!
    echo.
    echo 📝 Next Steps:
    echo    1. Set admin custom claims ^(see guide^)
    echo    2. Test admin access
    echo    3. Test message privacy
    echo    4. Plan Cloud Functions migration
) else (
    echo ❌ Deployment failed!
    echo    Check Firebase CLI is installed and logged in
)

echo.
pause
