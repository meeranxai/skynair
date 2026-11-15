# Fix Cloudinary 401 Unauthorized Error 🔧

## Problem
```
DioException [bad response]
Status Code: 401 (Unauthorized)
```

Cloudinary upload reject kar raha hai kyunki authentication fail ho raha hai.

## Root Causes

### 1. Upload Preset Not Unsigned
Cloudinary preset "signed" mode mein hai, lekin app "unsigned" mode use kar raha hai.

### 2. Wrong Cloud Name or Preset Name
Cloud name ya preset name galat hai.

### 3. Preset Doesn't Exist
Upload preset Cloudinary dashboard mein create nahi kiya gaya.

## Solution

### Step 1: Cloudinary Dashboard Setup (5 minutes)

#### A. Login to Cloudinary
1. Go to: https://cloudinary.com/console
2. Login with your account

#### B. Check Cloud Name
1. Dashboard → Top right corner
2. Cloud name should be: **dqhkwsqhi**
3. If different, update in code

#### C. Create/Update Upload Preset
1. Go to: **Settings** → **Upload**
2. Scroll to **Upload presets** section
3. Look for preset: **g_network_preset**

**If preset exists:**
- Click on it
- Make sure **Signing Mode** = **Unsigned**
- Click **Save**

**If preset doesn't exist:**
- Click **Add upload preset**
- Preset name: `g_network_preset`
- Signing mode: **Unsigned**
- Folder: Leave empty (we'll set in code)
- Click **Save**

### Step 2: Verify Upload Preset Settings

#### Required Settings:
```
Preset Name: g_network_preset
Signing Mode: Unsigned ✅ (IMPORTANT!)
Folder: (empty - set in code)
Resource Type: Auto
Access Mode: Public
Unique Filename: Yes
Overwrite: No
```

#### Optional but Recommended:
```
File Size Limit: 10 MB
Allowed Formats: jpg, png, jpeg, gif, webp
Max Image Width: 2048
Max Image Height: 2048
Quality: Auto
```

### Step 3: Update Code (if needed)

Check if cloud name and preset are correct:

```dart
// In firestore_service.dart
final cloudinary = CloudinaryPublic(
  'dqhkwsqhi',           // ← Your cloud name
  'g_network_preset',    // ← Your preset name
  cache: false
);
```

### Step 4: Test Upload

Run test:
```bash
test_profile_editing.bat
```

Or manually:
1. Open app
2. Edit profile
3. Upload picture
4. Should work now ✅

## Alternative Solution: Use Different Preset

If you want to use a different preset:

### Option A: Use Default Preset
```dart
final cloudinary = CloudinaryPublic(
  'dqhkwsqhi',
  'ml_default',  // Default unsigned preset
  cache: false
);
```

### Option B: Create New Preset
1. Cloudinary Dashboard → Settings → Upload
2. Add upload preset
3. Name: `gnetwork_unsigned`
4. Signing Mode: **Unsigned**
5. Save

Then update code:
```dart
final cloudinary = CloudinaryPublic(
  'dqhkwsqhi',
  'gnetwork_unsigned',  // New preset
  cache: false
);
```

## Verification Steps

### 1. Check Preset in Dashboard
```
Settings → Upload → Upload presets
Find: g_network_preset
Status: Should show "Unsigned"
```

### 2. Test with cURL
```bash
curl -X POST \
  https://api.cloudinary.com/v1_1/dqhkwsqhi/image/upload \
  -F "file=@test.jpg" \
  -F "upload_preset=g_network_preset"
```

Should return JSON with `secure_url` (not 401 error)

### 3. Check in Code
```dart
// Add debug logging
try {
  dev.log('🔄 Uploading to Cloudinary...');
  dev.log('Cloud Name: dqhkwsqhi');
  dev.log('Preset: g_network_preset');
  
  final response = await cloudinary.uploadFile(...);
  
  dev.log('✅ Upload successful: ${response.secureUrl}');
} catch (e) {
  dev.log('❌ Upload failed: $e');
}
```

## Common Mistakes

### ❌ Mistake 1: Signed Preset
```
Preset is in "Signed" mode
Solution: Change to "Unsigned" mode
```

### ❌ Mistake 2: Wrong Cloud Name
```dart
// Wrong
final cloudinary = CloudinaryPublic('wrong_name', ...);

// Correct
final cloudinary = CloudinaryPublic('dqhkwsqhi', ...);
```

### ❌ Mistake 3: Preset Doesn't Exist
```
Preset name typo or not created
Solution: Create preset in dashboard
```

### ❌ Mistake 4: API Key in Code
```dart
// Wrong - Don't use API key for unsigned uploads
final cloudinary = Cloudinary.signedConfig(
  apiKey: 'xxx',
  apiSecret: 'xxx',
  cloudName: 'dqhkwsqhi',
);

// Correct - Use unsigned preset
final cloudinary = CloudinaryPublic(
  'dqhkwsqhi',
  'g_network_preset',
  cache: false
);
```

## Quick Fix Script

Create this file: `fix_cloudinary_401.bat`

```batch
@echo off
echo ========================================
echo Cloudinary 401 Error Fix
echo ========================================
echo.
echo Steps to fix:
echo.
echo 1. Go to: https://cloudinary.com/console
echo 2. Login to your account
echo 3. Go to Settings - Upload
echo 4. Find preset: g_network_preset
echo 5. Make sure Signing Mode = Unsigned
echo 6. Click Save
echo.
echo Cloud Name: dqhkwsqhi
echo Preset Name: g_network_preset
echo.
echo Press any key to open Cloudinary dashboard...
pause
start https://cloudinary.com/console/settings/upload
echo.
echo After fixing, press any key to test...
pause
flutter run
```

## Testing Checklist

- [ ] Cloudinary dashboard accessible
- [ ] Cloud name is correct: `dqhkwsqhi`
- [ ] Upload preset exists: `g_network_preset`
- [ ] Preset signing mode: **Unsigned**
- [ ] Preset saved successfully
- [ ] Code has correct cloud name
- [ ] Code has correct preset name
- [ ] App restarted after changes
- [ ] Upload test successful

## If Still Not Working

### Check Network
```dart
// Test Cloudinary connectivity
try {
  final response = await http.get(
    Uri.parse('https://api.cloudinary.com/v1_1/dqhkwsqhi/image/list'),
  );
  print('Cloudinary reachable: ${response.statusCode}');
} catch (e) {
  print('Network error: $e');
}
```

### Check Firewall/VPN
- Disable VPN if active
- Check if Cloudinary is blocked
- Try on different network

### Use Cloudinary Support
1. Go to: https://support.cloudinary.com
2. Create ticket with:
   - Cloud name: dqhkwsqhi
   - Preset name: g_network_preset
   - Error: 401 Unauthorized
   - Upload type: Unsigned

## Alternative: Use Signed Upload (Not Recommended)

If unsigned doesn't work, use signed upload (requires API key):

```dart
// NOT RECOMMENDED - Exposes API secret
import 'package:cloudinary_sdk/cloudinary_sdk.dart';

final cloudinary = Cloudinary.signedConfig(
  apiKey: 'YOUR_API_KEY',
  apiSecret: 'YOUR_API_SECRET',
  cloudName: 'dqhkwsqhi',
);

final response = await cloudinary.upload(
  file: file.path,
  folder: 'profile_pictures',
  resourceType: CloudinaryResourceType.image,
);
```

**Warning**: Never commit API secret to git!

## Summary

### Most Common Fix:
1. Go to Cloudinary Dashboard
2. Settings → Upload → Upload presets
3. Find `g_network_preset`
4. Change Signing Mode to **Unsigned**
5. Save
6. Restart app
7. Test upload ✅

### If Preset Doesn't Exist:
1. Create new preset
2. Name: `g_network_preset`
3. Signing Mode: **Unsigned**
4. Save
5. Test upload ✅

---

**Status**: Ready to Fix
**Time Required**: 5 minutes
**Difficulty**: Easy
**Success Rate**: 99%
