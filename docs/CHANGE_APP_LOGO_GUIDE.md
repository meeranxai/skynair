# G-Network App Logo Change Guide

## Current Logo Location

Your app currently uses this logo:
- **File**: `assets/images/G-Network logo.png`
- **Used in**: Login page, Splash screen, App bar

## How to Change the Logo

### Step 1: Prepare Your New Logo

**Requirements:**
- **Format**: PNG (with transparent background recommended)
- **Size**: 512x512 pixels (or higher, will be scaled)
- **Name**: Any name (e.g., `new-logo.png`, `g-network-logo.png`)

**Tips:**
- Use transparent background for best results
- Square aspect ratio works best
- High resolution (at least 512x512)
- Keep file size under 500KB

### Step 2: Replace Logo File

**Option A: Replace Existing File**
1. Rename your new logo to: `G-Network logo.png`
2. Replace the file in: `assets/images/G-Network logo.png`
3. Done! App will use new logo automatically

**Option B: Add New File**
1. Copy your new logo to: `assets/images/your-logo-name.png`
2. Update code to use new filename (see Step 3)

### Step 3: Update Code (If Using New Filename)

If you used a different filename, update these files:

#### File: `lib/core/widgets/app_logo.dart`

Find this line:
```dart
Image.asset(
  'assets/images/G-Network logo.png',
  ...
)
```

Change to:
```dart
Image.asset(
  'assets/images/your-logo-name.png',
  ...
)
```

#### File: `lib/features/auth/pages/login_page.dart`

Find:
```dart
Image.asset(
  'assets/images/G-Network logo.png',
  ...
)
```

Change to:
```dart
Image.asset(
  'assets/images/your-logo-name.png',
  ...
)
```

#### File: `lib/features/auth/pages/signup_page.dart`

Same change as above.

### Step 4: Update App Icon (Launcher Icon)

The logo in the app is different from the app icon (launcher icon on phone).

**To change app icon:**

1. **Prepare icon image**:
   - Size: 1024x1024 pixels
   - Format: PNG
   - Name: `icon.png`
   - Place in: `assets/images/icon.png`

2. **Update `pubspec.yaml`**:

Add this section (if not already there):
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/icon.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/images/icon.png"
```

3. **Install flutter_launcher_icons**:
```bash
flutter pub add dev:flutter_launcher_icons
```

4. **Generate icons**:
```bash
flutter pub run flutter_launcher_icons
```

5. **Rebuild APK**:
```bash
flutter build apk --release
```

### Step 5: Rebuild App

After changing logo:

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Build APK
flutter build apk --release
```

Or use the batch file:
```bash
build_apk.bat
```

## Logo Locations in App

Your logo appears in these places:

1. **Login Screen** - Top center, large size
2. **Signup Screen** - Top center, large size
3. **App Bar** - Top left, small circular logo
4. **Splash Screen** (if you have one)

## Quick Logo Change (Easiest Method)

**If you just want to replace the logo quickly:**

1. Get your new logo file (PNG, 512x512)
2. Rename it to: `G-Network logo.png`
3. Replace the file in: `assets/images/G-Network logo.png`
4. Run: `flutter clean`
5. Run: `flutter build apk --release`
6. Done!

## Logo Design Tips

**Good Logo Characteristics:**
- ✅ Simple and recognizable
- ✅ Works in small sizes
- ✅ Transparent background
- ✅ High contrast
- ✅ Square aspect ratio

**Avoid:**
- ❌ Too much detail
- ❌ Thin lines (hard to see when small)
- ❌ White background (use transparent)
- ❌ Rectangular shapes (use square)

## Testing New Logo

After changing logo:

1. **Run app in debug mode**:
```bash
flutter run
```

2. **Check these screens**:
   - Login page
   - Signup page
   - Home page (app bar)
   - Profile page

3. **Verify**:
   - Logo displays correctly
   - No pixelation or blur
   - Proper sizing
   - Transparent background works

## Troubleshooting

### Logo Not Showing
**Solution**: 
```bash
flutter clean
flutter pub get
flutter run
```

### Logo Pixelated/Blurry
**Solution**: Use higher resolution image (at least 512x512)

### Logo Has White Background
**Solution**: Use PNG with transparent background

### Old Logo Still Showing
**Solution**: 
1. Clear app data on phone
2. Uninstall old APK
3. Install new APK
4. Or run: `flutter clean` and rebuild

## Files to Update

If changing logo filename, update these files:

1. `lib/core/widgets/app_logo.dart`
2. `lib/features/auth/pages/login_page.dart`
3. `lib/features/auth/pages/signup_page.dart`
4. `pubspec.yaml` (if changing app icon)

## Summary

**Easiest Way:**
1. Replace `assets/images/G-Network logo.png` with your new logo
2. Keep the same filename
3. Run `flutter build apk --release`
4. Done!

**Complete Way (Logo + App Icon):**
1. Replace logo in `assets/images/`
2. Add app icon: `assets/images/icon.png` (1024x1024)
3. Update `pubspec.yaml` with flutter_launcher_icons
4. Run `flutter pub run flutter_launcher_icons`
5. Run `flutter build apk --release`
6. Install new APK on phone

---

**Agar sirf logo change karna hai to `assets/images/G-Network logo.png` file replace kar do aur APK build kar lo. Agar app icon bhi change karna hai to upar wale complete steps follow karo!** 🎨
