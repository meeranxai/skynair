@echo off
echo ========================================
echo Delete Corrupted NDK
echo ========================================
echo.

echo Corrupted NDK Location: E:\x\ndk\27.0.12077973
echo.

echo This will delete the corrupted NDK folder.
echo Gradle will auto-download a fresh copy.
echo.

pause

echo.
echo Deleting corrupted NDK...
echo.

if exist "E:\x\ndk\27.0.12077973" (
    rmdir /s /q "E:\x\ndk\27.0.12077973"
    echo ✅ Deleted: E:\x\ndk\27.0.12077973
) else (
    echo ⚠️ Folder not found: E:\x\ndk\27.0.12077973
)

echo.
echo Now run: flutter clean
echo Then run: flutter run
echo.

pause
