@echo off
setlocal enabledelayedexpansion
color 0A

:: ========================================
:: Skynaire APK Builder v2.0
:: Production-Ready Build Script
:: ========================================

echo.
echo  ╔════════════════════════════════════════════════════════════╗
echo  ║         SKYNAIRE APK BUILDER v2.0                          ║
echo  ║         Production-Ready Build System                      ║
echo  ╚════════════════════════════════════════════════════════════╝
echo.

:: Get start time
set START_TIME=%TIME%

:: Check if Flutter is installed
echo [CHECK] Verifying Flutter installation...
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    color 0C
    echo [ERROR] Flutter not found! Please install Flutter first.
    echo Visit: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)
echo [OK] Flutter found!
echo.

:: Check Flutter version
echo [INFO] Flutter version:
flutter --version | findstr "Flutter"
echo.

:: ========================================
:: STEP 1: Pre-Build Checks
:: ========================================
echo ╔════════════════════════════════════════════════════════════╗
echo ║ STEP 1: Pre-Build Checks                                  ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

:: Check for corrupted NDK
echo [CHECK] Checking for corrupted NDK...
if exist "E:\x\ndk\27.0.12077973" (
    if not exist "E:\x\ndk\27.0.12077973\source.properties" (
        echo [WARNING] Corrupted NDK detected!
        echo [FIX] Deleting corrupted NDK...
        rmdir /s /q "E:\x\ndk\27.0.12077973" 2>nul
        echo [OK] Corrupted NDK removed. Will auto-download fresh copy.
    ) else (
        echo [OK] NDK is valid.
    )
) else (
    echo [INFO] NDK not found. Will auto-download during build.
)
echo.

:: Check disk space
echo [CHECK] Checking disk space...
for /f "tokens=3" %%a in ('dir /-c ^| find "bytes free"') do set FREE_SPACE=%%a
echo [INFO] Free disk space: %FREE_SPACE% bytes
echo.

:: Check internet connection
echo [CHECK] Checking internet connection...
ping -n 1 google.com >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Internet connection available.
) else (
    echo [WARNING] No internet connection. NDK download may fail.
)
echo.

:: ========================================
:: STEP 2: Clean Previous Build
:: ========================================
echo ╔════════════════════════════════════════════════════════════╗
echo ║ STEP 2: Cleaning Previous Build                           ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

echo [CLEAN] Removing build artifacts...
if exist "build" (
    rmdir /s /q "build" 2>nul
    echo [OK] Build folder deleted.
) else (
    echo [INFO] No previous build found.
)

echo [CLEAN] Running flutter clean...
call flutter clean
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Flutter clean had issues, continuing...
)
echo [OK] Clean complete!
echo.

:: ========================================
:: STEP 3: Get Dependencies
:: ========================================
echo ╔════════════════════════════════════════════════════════════╗
echo ║ STEP 3: Getting Dependencies                              ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

echo [DEPS] Fetching Flutter packages...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    color 0C
    echo [ERROR] Failed to get dependencies!
    echo [FIX] Try: flutter pub cache repair
    pause
    exit /b 1
)
echo [OK] Dependencies fetched successfully!
echo.

:: ========================================
:: STEP 4: Code Generation (Optional)
:: ========================================
echo ╔════════════════════════════════════════════════════════════╗
echo ║ STEP 4: Code Generation (Optional)                        ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

:: Check if build_runner is needed
if exist "pubspec.yaml" (
    findstr /C:"build_runner" pubspec.yaml >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo [GEN] Running build_runner...
        call flutter pub run build_runner build --delete-conflicting-outputs
        if %ERRORLEVEL% NEQ 0 (
            echo [WARNING] Code generation had issues, continuing...
        ) else (
            echo [OK] Code generation complete!
        )
    ) else (
        echo [INFO] build_runner not configured, skipping...
    )
)
echo.

:: ========================================
:: STEP 5: Build Release APK
:: ========================================
echo ╔════════════════════════════════════════════════════════════╗
echo ║ STEP 5: Building Release APK                              ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

echo [BUILD] Starting APK build...
echo [INFO] This may take 5-15 minutes depending on your system.
echo [INFO] NDK will auto-download if needed (2-5 min first time).
echo.
echo [PROGRESS] Building... Please wait...
echo.

call flutter build apk --release

if %ERRORLEVEL% NEQ 0 (
    color 0C
    echo.
    echo ╔════════════════════════════════════════════════════════════╗
    echo ║ BUILD FAILED!                                              ║
    echo ╚════════════════════════════════════════════════════════════╝
    echo.
    echo [ERROR] APK build failed with error code: %ERRORLEVEL%
    echo.
    echo Common Solutions:
    echo 1. NDK Issue: Run fix_ndk_and_build.bat
    echo 2. Gradle Issue: Delete .gradle folder and retry
    echo 3. Memory Issue: Close other apps and retry
    echo 4. Internet Issue: Check connection for NDK download
    echo.
    echo For detailed logs, check:
    echo - Flutter logs above
    echo - android\app\build\outputs\logs\
    echo.
    pause
    exit /b 1
)

:: ========================================
:: STEP 6: Verify APK
:: ========================================
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║ STEP 6: Verifying APK                                      ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

set APK_PATH=build\app\outputs\flutter-apk\app-release.apk

if exist "%APK_PATH%" (
    echo [OK] APK file found!
    echo.
    echo [INFO] APK Details:
    echo ─────────────────────────────────────────────────────────────
    dir "%APK_PATH%" | findstr "app-release.apk"
    echo ─────────────────────────────────────────────────────────────
    
    :: Get file size in MB
    for %%A in ("%APK_PATH%") do set APK_SIZE=%%~zA
    set /a APK_SIZE_MB=!APK_SIZE! / 1048576
    echo [INFO] APK Size: !APK_SIZE_MB! MB
    
    :: Get build time
    set END_TIME=%TIME%
    echo [INFO] Build completed at: !END_TIME!
    echo [INFO] Started at: %START_TIME%
    
) else (
    color 0C
    echo [ERROR] APK file not found!
    echo [ERROR] Expected location: %APK_PATH%
    echo.
    pause
    exit /b 1
)

:: ========================================
:: SUCCESS SUMMARY
:: ========================================
echo.
color 0A
echo ╔════════════════════════════════════════════════════════════╗
echo ║ ✓ BUILD SUCCESSFUL!                                        ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo [SUCCESS] G-Network APK built successfully!
echo.
echo ┌────────────────────────────────────────────────────────────┐
echo │ APK LOCATION:                                              │
echo │ %APK_PATH%                │
echo └────────────────────────────────────────────────────────────┘
echo.
echo ┌────────────────────────────────────────────────────────────┐
echo │ INSTALLATION OPTIONS:                                      │
echo │                                                            │
echo │ Option 1: USB Installation                                │
echo │   1. Connect phone via USB                                │
echo │   2. Enable USB debugging                                 │
echo │   3. Run: flutter install                                 │
echo │                                                            │
echo │ Option 2: Manual Installation                             │
echo │   1. Copy APK to phone                                    │
echo │   2. Open APK file on phone                               │
echo │   3. Allow installation from unknown sources              │
echo │                                                            │
echo │ Option 3: Share via ADB                                   │
echo │   adb install %APK_PATH%                                  │
echo └────────────────────────────────────────────────────────────┘
echo.
echo ┌────────────────────────────────────────────────────────────┐
echo │ NEXT STEPS:                                                │
echo │                                                            │
echo │ • Test APK on device                                       │
echo │ • Check app functionality                                  │
echo │ • Verify Firebase connection                               │
echo │ • Test all features                                        │
echo │ • Ready for distribution!                                  │
echo └────────────────────────────────────────────────────────────┘
echo.

:: Open APK folder
echo [INFO] Opening APK folder...
start "" "build\app\outputs\flutter-apk\"

echo.
echo Press any key to exit...
pause >nul
exit /b 0
