# G-Network Release & Firebase Configuration Guide

This document contains essential information for building and releasing the G-Network Android application to the Play Store or APKPure.

## 🔑 Keystore Information (Release)
**File Location:** `android/app/release-keystore.jks`
*   **Alias:** `release`
*   **Keystore Password:** `password123`
*   **Key Password:** `password123`

> **IMPORTANT:** Never lose the `.jks` file. If lost, you cannot update your app on the Play Store.

---

## 🛡️ Fingerprints (SHA Keys)
Add these to your **Firebase Console** under Project Settings > Android App.

### **1. Debug Fingerprints (For Development)**
*   **SHA-1:** `F1:0E:AE:37:6C:55:23:9E:4D:3B:F7:8A:BF:51:2F:0E:2F:41:59:A6`
*   **SHA-256:** `62:2D:E5:5C:BE:EB:D4:40:63:A3:5A:42:2F:AE:80:49:7A:05:E1:3C:71:CD:1A:E5:F7:4E:70:CB:02:16:07:01`

### **2. Release Fingerprints (For Play Store/Production)**
*   **SHA-1:** `6A:6E:FC:E8:B1:02:1C:99:0E:5C:8B:50:AC:0F:FF:1F:32:94:51:C8`
*   **SHA-256:** `D9:69:60:A7:20:F0:DD:BD:60:A3:B1:27:C1:82:0F:F5:65:9A:B6:29:0A:3A:C1:C3:0D:FD:DE:20:45:EC:43:F5`

---

## ⚙️ Configuration Files

### **key.properties**
Location: `android/key.properties` (Currently GIT IGNORED for security).
Contents:
```properties
storePassword=password123
keyPassword=password123
keyAlias=release
storeFile=release-keystore.jks
```

### **google-services.json**
Location: `android/app/google-services.json`
*   This file connects your app to Firebase. If you change SHA keys in Firebase, you **must** redownload and replace this file.

---

## 🚀 How to Build Release APK
Run the following command in your project terminal:

```powershell
flutter build apk --release
```
The output file will be located at:
`build\app\outputs\flutter-apk\app-release.apk`

---

## 📝 Next Steps for Play Store
1. Create a **Developer Account** on Google Play Console.
2. Upload the `app-release.apk` (or use `flutter build appbundle` for modern Play Store requirements).
3. Ensure the **Package Name** (`com.example.social_media_app`) matches exactly between Play Console and Firebase.
