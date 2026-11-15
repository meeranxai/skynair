# Image Cropper Complete Setup Guide (Android 14/15 + iOS 17+)
## Jan 2026 - Latest Configuration

## مسئلہ (Problem)
App crash ho jati hai jab `ImageCropper().cropImage()` call karte hain. Android 14/15 aur iOS 17+ ke liye proper configuration nahi hai.

---

## حل (Complete Solution)

### Step 1: AndroidManifest.xml Configuration

**File:** `android/app/src/main/AndroidManifest.xml`

`<application>` tag ke **ANDAR** yeh code add karein:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions (manifest tag ke andar, application se bahar) -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.CAMERA" />
    
    <application
        android:label="G-Network"
        android:name="${applicationName}"
        android:icon="@mipmap/launcher_icon">
        
        <!-- Your existing MainActivity -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme" />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <!-- ✅ UCropActivity for image_cropper (ZAROORI!) -->
        <activity
            android:name="com.yalantis.ucrop.UCropActivity"
            android:screenOrientation="portrait"
            android:theme="@style/Theme.AppCompat.Light.NoActionBar"
            android:exported="false" />

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>

    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
        <!-- ✅ Image picker queries -->
        <intent>
            <action android:name="android.intent.action.GET_CONTENT" />
        </intent>
        <intent>
            <action android:name="android.media.action.IMAGE_CAPTURE" />
        </intent>
    </queries>
</manifest>
```

---

### Step 2: build.gradle.kts Configuration

**File:** `android/app/build.gradle.kts`

Yeh configuration use karein:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.social_media_app"
    compileSdk = 35  // ✅ Android 15 support
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.social_media_app"
        minSdk = 24  // ✅ Android 7.0+
        targetSdk = 35  // ✅ Android 15
        versionCode = 1
        versionName = "1.0.0"
        
        // ✅ MultiDex support (agar app bari hai)
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            minifyEnabled = false
            shrinkResources = false
        }
    }

    // ✅ Packaging options (conflicts avoid karne ke liye)
    packaging {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/ASL2.0",
                "META-INF/*.kotlin_module"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ AppCompat for UCrop (ZAROORI!)
    implementation("androidx.appcompat:appcompat:1.7.0")
}
```

---

### Step 3: iOS Configuration

**File:** `ios/Runner/Info.plist`

`<dict>` tag ke andar yeh permissions add karein:

```xml
<dict>
    <!-- Existing keys... -->
    
    <!-- ✅ Camera Permission -->
    <key>NSCameraUsageDescription</key>
    <string>We need camera access to take photos for your profile and posts</string>
    
    <!-- ✅ Photo Library Permission (iOS 14+) -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>We need photo library access to select images</string>
    
    <!-- ✅ Photo Library Add Permission -->
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>We need permission to save edited images</string>
    
    <!-- Existing keys... -->
</dict>
```

---

### Step 4: Dart Code (Latest Syntax)

**Correct Implementation:**

```dart
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

Future<void> pickAndCropImage() async {
  try {
    // 1. Pick image
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    // 2. Crop image
    final CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      // ✅ Custom aspect ratio (9:16 for stories)
      aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16),
      uiSettings: [
        // ✅ Android Settings
        AndroidUiSettings(
          toolbarTitle: 'Crop Photo',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          backgroundColor: Colors.black,
          activeControlsWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        // ✅ iOS Settings
        IOSUiSettings(
          title: 'Crop Photo',
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
          aspectRatioPickerButtonHidden: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
      ],
    );

    if (croppedFile != null) {
      // ✅ Use cropped image
      print('Cropped image path: ${croppedFile.path}');
      // Upload or display image
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

---

### Step 5: Flutter Clean & Rebuild

Terminal mein yeh commands run karein:

```bash
# 1. Clean project
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Rebuild (Android)
cd android
./gradlew clean
cd ..

# 4. Run app
flutter run

# 5. Build APK (release)
flutter build apk --release
```

---

## Common Issues & Solutions

### Issue 1: "UCropActivity not found"
**Solution:** AndroidManifest.xml mein UCropActivity add karein (Step 1 dekhen)

### Issue 2: "Theme.AppCompat not found"
**Solution:** build.gradle.kts mein `androidx.appcompat` dependency add karein

### Issue 3: App crash on Android 14+
**Solution:** 
- `compileSdk = 35` set karein
- `targetSdk = 35` set karein
- Permissions properly add karein

### Issue 4: iOS crash
**Solution:** Info.plist mein camera aur photo library permissions add karein

### Issue 5: "ratio9x16 not found"
**Solution:** Custom aspect ratio use karein:
```dart
aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16)
```

---

## Testing Checklist

- [ ] AndroidManifest.xml mein UCropActivity added
- [ ] build.gradle.kts mein compileSdk = 35
- [ ] build.gradle.kts mein appcompat dependency
- [ ] iOS Info.plist mein permissions
- [ ] flutter clean run kiya
- [ ] App run ho rahi hai without crash
- [ ] Crop screen properly open ho rahi hai
- [ ] Cropped image save ho rahi hai

---

## Package Versions (Jan 2026)

```yaml
dependencies:
  image_cropper: ^8.0.2  # ✅ Latest
  image_picker: ^1.1.2   # ✅ Latest
  camera: ^0.10.6        # ✅ Latest
```

---

## Summary

✅ **AndroidManifest.xml:** UCropActivity + Permissions
✅ **build.gradle.kts:** compileSdk 35 + appcompat dependency  
✅ **Info.plist:** Camera + Photo Library permissions
✅ **Dart Code:** Latest null-safe syntax with proper uiSettings
✅ **Custom Ratios:** Use `CropAspectRatio(ratioX, ratioY)`

Ab aapki app crash nahi hogi! 🎉
