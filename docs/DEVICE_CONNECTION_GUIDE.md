# 📱 Connect G-Network Flutter App to Your Mobile Device

## 🚀 Quick Start (5 minutes)

### Method 1: USB Connection (Recommended)

#### Step 1: Enable Developer Mode on Android
1. **Open Settings** on your Android phone
2. **Go to About Phone** (or About Device)
3. **Find Build Number** and **tap it 7 times rapidly**
4. You'll see "You are now a developer!"

#### Step 2: Enable USB Debugging
1. **Go back to Settings**
2. **Find Developer Options** (usually near bottom)
3. **Turn ON USB Debugging**
4. **Turn ON Install via USB** (if available)

#### Step 3: Connect Your Phone
1. **Connect USB cable** from phone to computer
2. **On your phone**: Allow USB Debugging popup → **Always allow** → **OK**
3. **Run the connection script**: Double-click `connect_to_device.bat`

#### Step 4: Run the App
```bash
flutter devices
flutter run
```

---

## 🌐 Method 2: Wireless Connection (Android 11+)

### Enable Wireless Debugging
1. **Developer Options** → **Wireless Debugging** → **ON**
2. **Tap Wireless Debugging** → **Pair device with pairing code**
3. **Note the IP and Port** shown

### Connect Wirelessly
```bash
adb pair [IP_ADDRESS]:[PORT]
# Enter pairing code when prompted
flutter run
```

---

## 🍎 Method 3: iOS Device (Mac Required)

### Prerequisites
- **Mac computer** with Xcode installed
- **Apple Developer account** (free tier works)
- **iOS device** with iOS 9.0+

### Steps
1. **Connect iPhone/iPad** via USB
2. **Trust computer** when prompted on device
3. **Run**: `flutter run`

---

## 🖥️ Method 4: Use Emulator

### Android Emulator
```bash
# List available emulators
flutter emulators

# Launch emulator
flutter emulators --launch [emulator_name]

# Run app
flutter run
```

### Create New Emulator
1. **Install Android Studio**
2. **Open AVD Manager**
3. **Create Virtual Device**
4. **Choose device and API level**

---

## 🔧 Troubleshooting

### Device Not Detected?
```bash
# Check Flutter setup
flutter doctor

# Check devices with timeout
flutter devices --device-timeout 10

# Check ADB connection
adb devices
```

### Common Issues & Solutions

#### "Device not found"
- ✅ **USB Debugging enabled?**
- ✅ **USB cable working?** (try different cable)
- ✅ **Allow USB Debugging** popup accepted?
- ✅ **Developer Options** still enabled?

#### "Permission denied"
- ✅ **Restart both devices**
- ✅ **Revoke USB debugging authorizations** in Developer Options
- ✅ **Reconnect and allow again**

#### "Build failed"
- ✅ **Run**: `flutter clean && flutter pub get`
- ✅ **Check**: `flutter doctor` for issues
- ✅ **Update**: `flutter upgrade`

#### "App won't install"
- ✅ **Enable Install via USB** in Developer Options
- ✅ **Allow from unknown sources**
- ✅ **Check storage space** on device

---

## 📋 Pre-Connection Checklist

### ✅ Computer Setup
- [ ] Flutter SDK installed
- [ ] Android SDK installed (via Android Studio)
- [ ] USB drivers installed
- [ ] ADB in system PATH

### ✅ Phone Setup
- [ ] Developer Options enabled
- [ ] USB Debugging enabled
- [ ] Install via USB enabled
- [ ] USB cable connected
- [ ] USB Debugging allowed

### ✅ Network Setup (for wireless)
- [ ] Same WiFi network
- [ ] Firewall allows ADB
- [ ] Port 5555 open

---

## 🎯 Expected Results

### Successful Connection
```
Found 2 connected devices:
  SM-G973F (mobile) • RZ8M802WY0X • android-arm64 • Android 11 (API 30)
  Chrome (web)      • chrome      • web-javascript • Google Chrome 91.0
```

### App Running
```
Flutter run key commands.
r Hot reload.
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).
```

---

## 🚀 Next Steps After Connection

1. **Test all features** on your device
2. **Hot reload** with `r` for instant updates
3. **Debug** using Flutter DevTools
4. **Build APK** for distribution: `flutter build apk`
5. **Build App Bundle**: `flutter build appbundle`

---

## 📞 Need Help?

### Quick Commands
```bash
# Check everything
flutter doctor -v

# List devices
flutter devices

# Run with specific device
flutter run -d [device-id]

# Clean and rebuild
flutter clean && flutter pub get && flutter run
```

### Useful Links
- [Flutter Device Setup](https://flutter.dev/docs/get-started/install)
- [Android Developer Options](https://developer.android.com/studio/debug/dev-options)
- [ADB Commands](https://developer.android.com/studio/command-line/adb)

**Happy coding! 🎉**