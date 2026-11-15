# Connect Flutter App to Mobile Device

## Method 1: USB Connection (Android)

### Step 1: Enable Developer Options
1. Open **Settings** on your Android phone
2. Go to **About Phone** (or **About Device**)
3. Find **Build Number** and tap it **7 times**
4. You'll see "You are now a developer!"
5. Go back to **Settings** → **Developer Options**
6. Enable **USB Debugging**

### Step 2: Connect via USB
1. Connect your phone to computer with USB cable
2. On your phone, allow USB debugging when prompted
3. Run this command to check connection:
   ```bash
   flutter devices
   ```

### Step 3: Run App on Device
```bash
flutter run
```
Then select your device from the list.

## Method 2: Wireless Connection (Android 11+)

### Step 1: Enable Wireless Debugging
1. In **Developer Options**, enable **Wireless Debugging**
2. Tap **Wireless Debugging** → **Pair device with pairing code**
3. Note the IP address and port

### Step 2: Connect Wirelessly
```bash
adb pair [IP_ADDRESS]:[PORT]
# Enter the pairing code when prompted
```

## Method 3: iOS Device

### Step 1: Prerequisites
- Xcode installed on Mac
- Apple Developer account (free tier works)
- iOS device with iOS 9.0+

### Step 2: Connect
1. Connect iPhone/iPad via USB
2. Trust the computer when prompted
3. Run: `flutter run`

## Method 4: Use Android Emulator

### Create Virtual Device
```bash
flutter emulators
flutter emulators --launch [emulator_name]
```

## Troubleshooting

### Device Not Detected
```bash
flutter doctor
flutter devices --device-timeout 10
```

### Permission Issues
- Make sure USB debugging is enabled
- Try different USB cable
- Restart both devices

### Network Issues (Wireless)
- Ensure both devices on same WiFi
- Check firewall settings
- Try USB connection first