# Manual APK Build Steps - G-Network

## Issue: Build Taking Too Long

The automated build is taking longer than expected. Here's how to build manually.

## Manual Build Steps

### Step 1: Stop All Gradle Processes

```bash
taskkill /F /IM java.exe /T
taskkill /F /IM gradle.exe /T
```

### Step 2: Clean Gradle Cache

```bash
cd android
gradlew clean
cd ..
```

### Step 3: Clean Flutter

```bash
flutter clean
```

### Step 4: Get Dependencies

```bash
flutter pub get
```

### Step 5: Build APK (Simple Method)

```bash
flutter build apk --release --split-per-abi
```

This creates 3 smaller APKs instead of 1 large one:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM) ← **Use this for most phones**
- `app-x86_64-release.apk` (64-bit x86)

### Step 6: Check Build Output

```bash
dir build\app\outputs\flutter-apk\
```

## Alternative: Build Using Gradle Directly

If Flutter build fails, try building with Gradle:

```bash
cd android
gradlew assembleRelease
cd ..
```

APK will be at: `build\app\outputs\apk\release\app-release.apk`

## Quick Build Script

I've created a batch file for you:

```bash
quick_build_apk.bat
```

## Troubleshooting

### Build Stuck at "Running Gradle task"

**Solution 1: Increase Gradle Memory**

Edit `android/gradle.properties`, add:
```
org.gradle.jvmargs=-Xmx4096m -XX:MaxPermSize=512m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8
org.gradle.parallel=true
org.gradle.daemon=true
```

**Solution 2: Disable Gradle Daemon**

```bash
cd android
gradlew --stop
cd ..
```

Then rebuild.

### Build Fails with "Out of Memory"

Increase heap size in `android/gradle.properties`:
```
org.gradle.jvmargs=-Xmx8192m
```

### Build Fails with "Execution failed"

Check error message and:
1. Update Gradle: `cd android && gradlew wrapper --gradle-version=8.0`
2. Update Android Gradle Plugin in `android/build.gradle`

## Recommended: Split APK Build

This is faster and creates smaller files:

```bash
flutter build apk --release --split-per-abi
```

**Advantages:**
- Faster build time
- Smaller APK size (15-20 MB each vs 56 MB)
- Better for distribution

**Which APK to use:**
- **arm64-v8a** - Most modern phones (2018+)
- **armeabi-v7a** - Older phones (2015-2018)
- **x86_64** - Emulators only

## Current Build Status

Your build is running but taking very long. This usually means:
1. Gradle is downloading dependencies
2. First build after clean (takes longer)
3. Low system resources

**Recommendation**: Let it finish (may take 15-20 minutes) or stop and use split-per-abi method.

## Quick Commands

**Stop build:**
```bash
taskkill /F /IM java.exe /T
```

**Build split APKs (faster):**
```bash
flutter build apk --release --split-per-abi
```

**Check if APK exists:**
```bash
dir build\app\outputs\flutter-apk\*.apk
```

---

**Agar build zyada time le raha hai to Ctrl+C press karo aur `flutter build apk --release --split-per-abi` use karo. Yeh 3 chote APKs banayega jo jaldi ban jayenge!** ⚡
