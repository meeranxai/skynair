# Quick Mobile Device Connection

## Connect Your Android Phone NOW (No Android Studio needed)

### Step 1: Enable Developer Mode on Your Phone
1. Open **Settings** on your Android phone
2. Scroll to **About Phone** (or **About Device**)
3. Find **Build Number** and tap it **7 times rapidly**
4. You'll see "You are now a developer!"

### Step 2: Enable USB Debugging
1. Go back to **Settings**
2. Look for **Developer Options** (usually near the bottom)
3. Turn on **USB Debugging**
4. Turn on **Install via USB** (if available)

### Step 3: Connect Phone to Computer
1. Use a USB cable to connect your phone to this computer
2. On your phone, you'll see a popup asking to "Allow USB Debugging"
3. Check "Always allow from this computer" and tap **OK**

### Step 4: Test Connection
Run this in the terminal:
```bash
flutter devices
```

### Step 5: Run the App
If your device appears in the list:
```bash
flutter run
```
Then select your device number when prompted.

## Alternative: Use Your Phone's Browser

If the above doesn't work, you can run the web version:

1. Make sure your phone and computer are on the same WiFi
2. Run: `flutter run -d chrome --web-port 8080`
3. On your phone's browser, go to: `http://[YOUR_COMPUTER_IP]:8080`

To find your computer's IP:
```bash
ipconfig
```
Look for "IPv4 Address" under your WiFi adapter.