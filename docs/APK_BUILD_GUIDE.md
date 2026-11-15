# APK Build Guide for Social Media App

## Quick Android Setup

### Step 1: Install Android Studio
1. Download Android Studio from: https://developer.android.com/studio
2. Run the installer and follow the setup wizard
3. Make sure to install:
   - Android SDK
   - Android SDK Platform-Tools
   - Android SDK Build-Tools
   - Android Emulator (optional)

### Step 2: Configure Flutter
After Android Studio installation, run:
```cmd
flutter doctor --android-licenses
```
Accept all licenses by typing 'y' when prompted.

### Step 3: Build APK
Navigate to your project directory and run:
```cmd
cd social_media_app
flutter build apk --release
```

The APK will be created at: `build/app/outputs/flutter-apk/app-release.apk`

### Step 4: Install on Device
- Enable Developer Options on your Android device
- Enable USB Debugging
- Connect device via USB
- Run: `flutter install --release`

## Alternative: Build without Android Studio

### Using Command Line Tools Only
1. Download Android Command Line Tools from: https://developer.android.com/studio#command-tools
2. Extract to `C:\Android\cmdline-tools\latest\`
3. Set environment variables:
   - `ANDROID_HOME=C:\Android`
   - Add `C:\Android\cmdline-tools\latest\bin` to PATH
4. Install SDK: `sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"`
5. Run: `flutter config --android-sdk C:\Android`

## Troubleshooting

### Common Issues:
- **Gradle build failed**: Run `flutter clean` then `flutter pub get`
- **SDK not found**: Verify ANDROID_HOME environment variable
- **License not accepted**: Run `flutter doctor --android-licenses`

### Build Variants:
- **Debug APK**: `flutter build apk --debug`
- **Release APK**: `flutter build apk --release`
- **Split APKs**: `flutter build apk --split-per-abi`