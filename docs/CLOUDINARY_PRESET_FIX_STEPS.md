# Cloudinary Preset Fix - Exact Steps ✅

## Current Status
Aap ne `g_network_preset` ko default preset set kar diya hai, lekin wo **Signed mode** mein hai. Isko **Unsigned mode** mein change karna hai.

## Problem
```
HTTP 401 Unauthorized
```
Matlab: Preset "Signed" mode mein hai, lekin app "Unsigned" mode use kar raha hai.

## Solution - Exact Steps

### Step 1: Find Your Preset

1. Cloudinary Dashboard mein jao: https://cloudinary.com/console
2. **Settings** → **Upload** tab
3. Scroll down to **"Upload presets"** section
4. List mein `g_network_preset` dhundo

### Step 2: Edit Preset

1. `g_network_preset` par **click** karo
2. Preset settings page khulega
3. **"Signing Mode"** option dhundo (top section mein hoga)

### Step 3: Change to Unsigned

Current setting:
```
Signing Mode: Signed ❌
```

Change to:
```
Signing Mode: Unsigned ✅
```

### Step 4: Save

1. Page ke bottom par **"Save"** button par click karo
2. Confirmation message aayega: "Preset updated successfully"

### Step 5: Verify

Preset list mein wapas jao aur check karo:
```
g_network_preset
Mode: Unsigned ✅
```

## Visual Guide

### Before (Wrong):
```
┌─────────────────────────────────────┐
│ Upload Preset: g_network_preset    │
│                                     │
│ Signing Mode: ● Signed    ○ Unsigned│  ← Wrong!
│                                     │
│ [Save]                              │
└─────────────────────────────────────┘
```

### After (Correct):
```
┌─────────────────────────────────────┐
│ Upload Preset: g_network_preset    │
│                                     │
│ Signing Mode: ○ Signed    ● Unsigned│  ← Correct!
│                                     │
│ [Save]                              │
└─────────────────────────────────────┘
```

## Why This Matters

### Signed Mode (Current - Wrong):
- Requires API key and secret
- For server-side uploads
- App doesn't have API secret (security)
- Result: **401 Unauthorized** ❌

### Unsigned Mode (Needed - Correct):
- No API key needed
- For client-side uploads
- App can upload directly
- Result: **Upload successful** ✅

## After Changing

### Test Upload:
```bash
flutter run
```

1. Open app
2. Go to profile
3. Edit profile
4. Upload picture
5. Should work now! ✅

## If Still Getting 401

### Check 1: Preset Saved?
- Go back to preset settings
- Verify "Signing Mode" shows "Unsigned"
- If not, save again

### Check 2: App Restarted?
- Close app completely
- Run `flutter run` again
- Try upload

### Check 3: Correct Preset Name?
Check code:
```dart
// In firestore_service.dart
final cloudinary = CloudinaryPublic(
  'dqhkwsqhi',           // Cloud name
  'g_network_preset',    // Preset name - must match exactly
  cache: false
);
```

### Check 4: Network Issue?
- Try on different network
- Disable VPN if active
- Check internet connection

## Alternative: Create New Unsigned Preset

If editing doesn't work, create a new one:

### Step 1: Create New Preset
1. Settings → Upload → Upload presets
2. Click **"Add upload preset"**
3. Fill in:
   ```
   Preset name: gnetwork_unsigned
   Signing mode: Unsigned ✅
   Folder: (leave empty)
   ```
4. Click **"Save"**

### Step 2: Update Code
```dart
// Change preset name
final cloudinary = CloudinaryPublic(
  'dqhkwsqhi',
  'gnetwork_unsigned',  // New preset name
  cache: false
);
```

### Step 3: Update in 3 Places

**File 1**: `lib/core/services/firestore_service.dart`
```dart
// Profile upload
final cloudinary = CloudinaryPublic('dqhkwsqhi', 'gnetwork_unsigned', cache: false);

// Post upload  
final cloudinary = CloudinaryPublic('dqhkwsqhi', 'gnetwork_unsigned', cache: false);
```

**File 2**: `lib/features/stories/services/story_service.dart`
```dart
// Story upload (if using CloudinaryPublic)
final cloudinary = CloudinaryPublic('dqhkwsqhi', 'gnetwork_unsigned', cache: false);
```

## Quick Test

### Test with cURL:
```bash
curl -X POST \
  https://api.cloudinary.com/v1_1/dqhkwsqhi/image/upload \
  -F "file=@test.jpg" \
  -F "upload_preset=g_network_preset"
```

**If Unsigned**: Returns JSON with `secure_url` ✅
**If Signed**: Returns 401 error ❌

## Summary

### What to Do:
1. ✅ Go to Cloudinary Dashboard
2. ✅ Settings → Upload → Upload presets
3. ✅ Click on `g_network_preset`
4. ✅ Change "Signing Mode" to "Unsigned"
5. ✅ Click "Save"
6. ✅ Restart app
7. ✅ Test upload

### Expected Result:
```
Before: HTTP 401 Unauthorized ❌
After:  Upload successful ✅
```

### Time Required:
2 minutes

### Difficulty:
Very Easy - Just one setting change!

---

**Next Step**: Change signing mode to Unsigned and test! 🚀
