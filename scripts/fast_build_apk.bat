@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
color 0B

echo.
echo  ╔════════════════════════════════════════════════════════════╗
echo  ║         SKYNAIRE APK BUILDER v2.0                          ║
echo  ║         (Turbo-Optimized Release Build)                    ║
echo  ╚════════════════════════════════════════════════════════════╝
echo.

:: Get start time
set START_TIME=%TIME%

:: FORCE JAVA VERSION (JDK 21 from Android Studio)
:: This prevents compatibility issues with system Java 25
set "JAVA_HOME=E:\Android Studio\jbr"
set "PATH=%JAVA_HOME%\bin;%PATH%"

:: Environment Verification
echo [INFO] Verifying environment...
java -version 2>tmp_java_ver.txt
set /p JAVA_VER=<tmp_java_ver.txt
del tmp_java_ver.txt
echo [INFO] Local Java detected: %JAVA_VER%

echo [INFO] Gradle Configuration:
echo [INFO] - Parallel Execution: ENABLED
echo [INFO] - Configuration Cache: ENABLED
echo [INFO] - JVM Toolchain: JDK 11 (Project Default)

:: Check dependencies
echo [DEPS] Updating dependencies...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to get dependencies.
    pause
    exit /b 1
)

:: Build runner (only if needed)
echo [GEN] Checking for code generation...
call flutter pub run build_runner build --delete-conflicting-outputs
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Code generation issues, but trying to build anyway...
)

:: Build APK with Optimizations
echo [BUILD] Starting Optimized APK Build...
echo [INFO] Building with --split-per-abi for performance and size...

:: Use split-per-abi to speed up and reduce individual APK sizes
call flutter build apk --release --split-per-abi

if %ERRORLEVEL% NEQ 0 (
    color 0C
    echo [ERROR] Build failed. 
    echo [FIX] 1. Check if 'android/app/build.gradle.kts' jvmTarget is set to 11.
    echo [FIX] 2. Run 'flutter clean' and try again.
    pause
    exit /b 1
)

echo.
echo [SUCCESS] APKs built successfully!
echo [INFO] Folder: build\app\outputs\flutter-apk\

:: Get build time
set END_TIME=%TIME%
echo [INFO] Build started at: %START_TIME%
echo [INFO] Build finished at: %END_TIME%

echo [INFO] Opening APK folder...
start "" "build\app\outputs\flutter-apk\"

echo.
echo Press any key to exit...
pause >nul
exit /b 0
