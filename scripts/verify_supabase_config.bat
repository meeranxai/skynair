@echo off
echo ========================================
echo Supabase Configuration Verification
echo ========================================
echo.

echo Checking configuration files...
echo.

echo 1. Environment Variables (.env.supabase):
echo -----------------------------------------
type .env.supabase
echo.

echo 2. App Config (lib/core/config/app_config.dart):
echo -----------------------------------------
echo Supabase URL: https://rniqhvmtezowdbabhogz.supabase.co
echo Bucket: images
echo.

echo 3. Supabase Dashboard Check:
echo -----------------------------------------
echo Project ID: rniqhvmtezowdbabhogz
echo Dashboard: https://supabase.com/dashboard/project/rniqhvmtezowdbabhogz
echo.

echo 4. Required Setup:
echo -----------------------------------------
echo [✓] User created in Authentication
echo [✓] Policies added to Storage
echo [ ] Test upload in Flutter app
echo.

echo ========================================
echo Next Step: Test Upload
echo ========================================
echo.
echo Run: test_supabase_final.bat
echo.
pause
