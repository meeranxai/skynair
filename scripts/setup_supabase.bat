@echo off
echo ========================================
echo Supabase Setup for G-Network
echo ========================================
echo.

echo Step 1: Install Dependencies
echo ========================================
echo Running flutter pub get...
call flutter pub get
echo.

echo Step 2: Clean Build
echo ========================================
echo Running flutter clean...
call flutter clean
echo.

echo Step 3: Get Dependencies Again
echo ========================================
echo Running flutter pub get...
call flutter pub get
echo.

echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo IMPORTANT: Before running the app, you need to:
echo.
echo 1. Create a Supabase project at https://supabase.com
echo 2. Create a storage bucket named 'gnetwork-media'
echo 3. Set up bucket policies (see SUPABASE_SETUP_GUIDE.md)
echo 4. Update .env.supabase with your credentials:
echo    - SUPABASE_URL=your_project_url
echo    - SUPABASE_ANON_KEY=your_anon_key
echo.
echo 5. Or update lib/core/config/app_config.dart directly
echo.
echo For detailed instructions, see: SUPABASE_SETUP_GUIDE.md
echo.
echo ========================================

pause
