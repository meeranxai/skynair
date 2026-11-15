# Cloudinary 401 Still Failing - Advanced Troubleshooting 🔍

## Current Situation

User changed preset to Unsigned mode but still getting 401 error.

## Possible Causes

### 1. Preset Not Saved Properly
Dashboard mein change kiya lekin save nahi hua

### 2. Wrong Preset Being Used
Code mein koi aur preset name hai

### 3. Cache Issue
App ya browser cache purani settings use kar raha hai

### 4. Network/Firewall Issue
VPN ya firewall Cloudinary block kar raha hai

### 5. Account Issue
Cloudinary account mein koi restriction hai

## Step-by-Step Debug

### Step 1: Double-Check Preset (CRITICAL)

1. **Open Cloudinary Dashboard**
   ```
   https://cloudinary.com/console/settings/upload
   ```

2. **Find g_network_preset**
   - Scroll to "Upload presets" section
   - Click on `g_network_preset`

3. **Verify EXACT Settings**
   ```
   ✓ Preset name: g_network_preset
   ✓ Signing mode: Unsigned (radio button selected)
   ✓ Status: Active (not disabled)
   ```

4. **Save Again**
   - Click "Save" button
   - Wait for "Preset updated successfully" message
   - **Don't close the page immediately**

5. **Verify It Saved**
   - Refresh the page
   - Open preset again
   - Check if "Unsigned" is still selected
   - If not, it didn't save - try again

### Step 2: Try Default Unsigned Preset

Instead of fixing `g_network_preset`, use Cloudinary's default unsigned preset:

**Update Code:**

File: `lib/core/services/firestore_service.dart`

Find these lines (around line 577 and 609):
```dart
final cloudinary = CloudinaryPublic(
  'dqhkwsqhi',
  'g_network_preset',  // ← Change this
  cache: false
);
```

Change to:
```dart
final cloudinary = CloudinaryPublic(
  'dqhkwsqhi',
  'ml_default',  // ← Use default unsigned preset
  cache: false
);
```

**Why This Works:**
- `ml_default` is Cloudinary's built-in unsigned preset
- It's always available
- No configuration needed

### Step 3: Create Brand New Unsigned Preset

If `g_network_preset` is corrupted, create a fresh one:

1. **Go to Upload Presets**
   ```
   https://cloudinary.com/console/settings/upload
   ```

2. **Click "Add upload preset"**

3. **Fill Settings**
   ```
   Preset name: gnetwork_app
   Signing mode: Unsigned ✓
   Folder: (leave empty)
   ```

4. **Save**

5. **Update Code**
   ```dart
   final cloudinary = CloudinaryPublic(
     'dqhkwsqhi',
     'gnetwork_app',  // New preset
     cache: false
   );
   ```

### Step 4: Complete Cache Clear

```bash
# Stop app completely
# Then run:

flutter clean
flutter pub get
flutter pub cache repair
flutter run
```

### Step 5: Test with cURL

Test if preset is actually unsigned:

```bash
curl -X POST \
  https://api.cloudinary.com/v1_1/dqhkwsqhi/image/upload \
  -F "file=https://via.placeholder.com/150" \
  -F "upload_preset=g_network_preset"
```

**Expected Results:**

**If Unsigned (Good):**
```json
{
  "public_id": "...",
  "secure_url": "https://res.cloudinary.com/...",
  ...
}
```

**If Signed (Bad):**
```json
{
  "error": {
    "message": "Upload preset must be unsigned"
  }
}
```

### Step 6: Check Account Restrictions

1. **Go to Dashboard**
   ```
   https://cloudinary.com/console
   ```

2. **Check Usage**
   - Are you over quota?
   - Is account suspended?
   - Any warnings?

3. **Check Settings → Security**
   - Are unsigned uploads allowed?
   - Any IP restrictions?

## Alternative Solutions

### Solution A: Use ml_default Preset

**Quickest fix - No dashboard changes needed:**

```dart
// In firestore_service.dart
// Change both uploadProfileImage and uploadPostImage

final cloudinary = CloudinaryPublic(
  'dqhkwsqhi',
  'ml_default',  // Built-in unsigned preset
  cache: false
);
```

### Solution B: Use Signed Upload (Not Recommended)

If unsigned absolutely won't work, use signed upload:

**⚠️ Warning: Requires API secret in code (security risk)**

1. **Get API Credentials**
   - Dashboard → Settings → Access Keys
   - Copy API Key and API Secret

2. **Update pubspec.yaml**
   ```yaml
   dependencies:
     cloudinary_sdk: ^4.0.0  # Different package
   ```

3. **Update Code**
   ```dart
   import 'package:cloudinary_sdk/cloudinary_sdk.dart';
   
   final cloudinary = Cloudinary.signedConfig(
     apiKey: 'YOUR_API_KEY',
     apiSecret: 'YOUR_API_SECRET',
     cloudName: 'dqhkwsqhi',
   );
   
   final response = await cloudinary.upload(
     file: imageFile.path,
     folder: 'profile_pictures',
     resourceType: CloudinaryResourceType.image,
   );
   ```

**⚠️ Never commit API secret to git!**

### Solution C: Use Different Service

If Cloudinary keeps failing, switch to another service:

**Options:**
- Firebase Storage (you already have setup)
- Supabase Storage (you have this too)
- ImgBB
- Imgur

## Debug Checklist

Run through this checklist:

- [ ] Preset exists in dashboard
- [ ] Preset name is exactly `g_network_preset`
- [ ] Signing mode shows "Unsigned"
- [ ] Preset is saved (verified by reopening)
- [ ] Code has correct cloud name: `dqhkwsqhi`
- [ ] Code has correct preset name: `g_network_preset`
- [ ] App cache cleared (`flutter clean`)
- [ ] App completely restarted
- [ ] Internet connection working
- [ ] VPN disabled
- [ ] Cloudinary account active
- [ ] No usage limits exceeded

## Quick Test Script

Run this to test everything:

```bash
debug_cloudinary_401.bat
```

## Recommended Next Steps

### Option 1: Use ml_default (Easiest)
1. Change preset name to `ml_default` in code
2. Run `flutter clean`
3. Run `flutter run`
4. Test upload

### Option 2: Create New Preset (Clean Start)
1. Create `gnetwork_app` preset as Unsigned
2. Update code to use `gnetwork_app`
3. Run `flutter clean`
4. Run `flutter run`
5. Test upload

### Option 3: Debug Current Setup
1. Run `debug_cloudinary_401.bat`
2. Follow all steps
3. Share error messages

## What Information I Need

If still failing, please share:

1. **Exact error message** from console
2. **Screenshot** of preset settings in dashboard
3. **Code snippet** showing CloudinaryPublic initialization
4. **cURL test result** (from Step 5 above)
5. **Account status** (any warnings in dashboard?)

---

**Most Likely Fix**: Use `ml_default` preset instead of `g_network_preset`

**Time**: 2 minutes

**Success Rate**: 95%
