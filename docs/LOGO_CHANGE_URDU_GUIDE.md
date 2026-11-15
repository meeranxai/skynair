# G-Network App Logo Change Kaise Karein - Urdu Guide

## Current Logo Kahan Hai?

Tumhara app yeh logo use kar raha hai:
- **File**: `assets/images/G-Network logo.png`
- **Dikhta hai**: Login page, Signup page, App bar mein

## Logo Change Karne Ka Aasan Tareeqa

### Step 1: Naya Logo Tayyar Karo

**Zaroorat:**
- **Format**: PNG (transparent background best hai)
- **Size**: 512x512 pixels (ya zyada)
- **Quality**: High resolution

**Tips:**
- Transparent background use karo (white nahi)
- Square shape (512x512, 1024x1024)
- File size 500KB se kam
- Simple aur clear design

### Step 2: Logo File Replace Karo

**Sabse Aasan Tareeqa:**

1. Apna naya logo file ka naam change karo: `G-Network logo.png`
2. Yeh file replace karo: `assets/images/G-Network logo.png`
3. Bas! Ho gaya

**Ya Phir:**

1. Naya logo copy karo: `assets/images/` folder mein
2. Koi bhi naam de sakte ho (e.g., `my-logo.png`)
3. Code mein filename update karo (neeche dekho)

### Step 3: Code Update Karo (Agar Naya Naam Diya)

Agar tumne alag filename use kiya, to yeh files update karo:

#### File 1: `lib/core/widgets/app_logo.dart`

Yeh line dhundo:
```dart
Image.asset(
  'assets/images/G-Network logo.png',
```

Isko change karo:
```dart
Image.asset(
  'assets/images/my-logo.png',
```

#### File 2: `lib/features/auth/pages/login_page.dart`

Same change karo (upar wali line dhundo aur replace karo)

#### File 3: `lib/features/auth/pages/signup_page.dart`

Same change karo

### Step 4: APK Build Karo

```bash
# Clean karo
flutter clean

# Dependencies get karo
flutter pub get

# APK build karo
flutter build apk --release
```

**Ya batch file use karo:**
```bash
build_new_apk.bat
```

## App Icon Bhi Change Karna Hai? (Phone Pe Dikhne Wala Icon)

App icon alag cheez hai (phone ki home screen pe dikhta hai).

### App Icon Change Karne Ke Steps:

1. **Icon image tayyar karo**:
   - Size: 1024x1024 pixels
   - Format: PNG
   - Transparent background
   - Save as: `assets/images/icon.png`

2. **Package install karo**:
```bash
flutter pub add dev:flutter_launcher_icons
```

3. **pubspec.yaml mein add karo**:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/icon.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/images/icon.png"
```

4. **Icons generate karo**:
```bash
flutter pub run flutter_launcher_icons
```

5. **APK build karo**:
```bash
flutter build apk --release
```

## Logo Kahan Kahan Dikhta Hai?

1. **Login Screen** - Upar center mein, bara size
2. **Signup Screen** - Upar center mein, bara size
3. **App Bar** - Upar left corner, chota circular logo
4. **Splash Screen** - Agar hai to

## Quick Summary (Sabse Aasan)

**Sirf Logo Change Karna Hai:**

1. ✅ Naya logo file tayyar karo (PNG, 512x512)
2. ✅ Naam change karo: `G-Network logo.png`
3. ✅ File replace karo: `assets/images/G-Network logo.png`
4. ✅ Run karo: `build_new_apk.bat`
5. ✅ Ho gaya!

**Logo + App Icon Dono Change Karna Hai:**

1. ✅ Logo replace karo (upar wala step)
2. ✅ App icon banao (1024x1024)
3. ✅ Save karo: `assets/images/icon.png`
4. ✅ `flutter_launcher_icons` install karo
5. ✅ `pubspec.yaml` update karo
6. ✅ Icons generate karo
7. ✅ APK build karo

## Logo Design Tips

**Acha Logo:**
- ✅ Simple aur clear
- ✅ Chote size mein bhi achha dikhe
- ✅ Transparent background
- ✅ High contrast colors
- ✅ Square shape

**Avoid Karo:**
- ❌ Zyada detail
- ❌ Patli lines (chote size mein nahi dikhti)
- ❌ White background (transparent use karo)
- ❌ Rectangular shape (square best hai)

## Testing

Logo change karne ke baad:

1. **App run karo**:
```bash
flutter run
```

2. **Yeh screens check karo**:
   - Login page
   - Signup page
   - Home page (app bar)

3. **Verify karo**:
   - Logo sahi dikh raha hai
   - Blur nahi hai
   - Size theek hai
   - Background transparent hai

## Problems Aur Solutions

### Logo Nahi Dikh Raha
**Solution**: 
```bash
flutter clean
flutter pub get
flutter run
```

### Logo Blur/Pixelated Hai
**Solution**: Higher resolution image use karo (kam se kam 512x512)

### Logo Ka Background White Hai
**Solution**: PNG with transparent background use karo

### Purana Logo Abhi Bhi Dikh Raha
**Solution**: 
1. Phone se app uninstall karo
2. Naya APK install karo
3. Ya `flutter clean` run karo aur rebuild karo

## Files Jo Update Karni Hain

Agar filename change kar rahe ho:

1. ✅ `lib/core/widgets/app_logo.dart`
2. ✅ `lib/features/auth/pages/login_page.dart`
3. ✅ `lib/features/auth/pages/signup_page.dart`
4. ✅ `pubspec.yaml` (agar app icon change kar rahe ho)

## Batch Files

Main ne yeh files banaye hain:

1. **`build_new_apk.bat`** - Naya APK build karne ke liye
2. **`CHANGE_APP_LOGO_GUIDE.md`** - Complete English guide
3. **`LOGO_CHANGE_URDU_GUIDE.md`** - Yeh file (Urdu guide)

---

**Khaas Baat: Sabse aasan tareeqa hai `assets/images/G-Network logo.png` file replace kar do aur `build_new_apk.bat` run kar do. Bas!** 🎨

**APK build ho raha hai background mein. Thoda wait karo, phir `build\app\outputs\flutter-apk\app-release.apk` check karo!** 📱
