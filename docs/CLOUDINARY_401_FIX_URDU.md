# Cloudinary 401 Error Fix - Urdu Guide 🔧

## Masla Kya Hai?
```
HTTP 401 Unauthorized
```

Jab aap profile picture ya post image upload karte hain, to ye error aata hai.

## Wajah
Aap ka Cloudinary preset **"Signed"** mode mein hai, lekin app **"Unsigned"** mode use kar raha hai.

## Hal - Sirf 2 Minute Mein ✅

### Step 1: Cloudinary Dashboard Kholo
1. Is link par jao: https://cloudinary.com/console
2. Apne account se login karo

### Step 2: Settings Mein Jao
1. Left side mein **"Settings"** par click karo (gear icon ⚙️)
2. **"Upload"** tab par click karo

### Step 3: Upload Presets Dhundo
1. Neeche scroll karo
2. **"Upload presets"** section dhundo
3. List mein `g_network_preset` dhundo

### Step 4: Preset Edit Karo
1. `g_network_preset` par **click** karo
2. Settings page khulega

### Step 5: Signing Mode Change Karo

**Abhi ye hai (Galat):**
```
Signing Mode: ● Signed    ○ Unsigned  ❌
```

**Isko ye banana hai (Sahi):**
```
Signing Mode: ○ Signed    ● Unsigned  ✅
```

**Kaise:**
- "Unsigned" wale radio button par click karo
- Wo select ho jayega

### Step 6: Save Karo
1. Page ke neeche **"Save"** button par click karo
2. "Preset updated successfully" message aayega

### Step 7: Test Karo
```bash
flutter run
```

1. App kholo
2. Profile edit karo
3. Picture upload karo
4. Ab kaam karega! ✅

## Samajhne Ke Liye

### Signed Mode (Abhi - Galat):
- API key aur secret chahiye
- Server ke liye hai
- App ke paas API secret nahi hai
- Result: **401 Error** ❌

### Unsigned Mode (Chahiye - Sahi):
- API key ki zaroorat nahi
- Mobile app ke liye hai
- Direct upload ho sakta hai
- Result: **Upload Successful** ✅

## Visual Guide

### Kahan Dhundna Hai:

```
Cloudinary Dashboard
    ↓
Settings (⚙️)
    ↓
Upload Tab
    ↓
Upload Presets Section
    ↓
g_network_preset (Click karo)
    ↓
Signing Mode: Unsigned (Select karo)
    ↓
Save Button (Click karo)
    ↓
Done! ✅
```

## Agar Phir Bhi 401 Aaye

### Check 1: Save Hua?
- Preset settings mein wapas jao
- Dekho "Unsigned" selected hai ya nahi
- Agar nahi to phir se save karo

### Check 2: App Restart Kiya?
- App band karo
- `flutter run` phir se chalo
- Upload try karo

### Check 3: Preset Name Sahi Hai?
Code mein check karo:
```dart
final cloudinary = CloudinaryPublic(
  'dqhkwsqhi',           // Ye aap ka cloud name
  'g_network_preset',    // Ye preset name - bilkul same hona chahiye
  cache: false
);
```

### Check 4: Internet Theek Hai?
- VPN band karo agar chalu hai
- Internet connection check karo
- Dusre network par try karo

## Alternative: Naya Preset Banao

Agar edit karna kaam nahi kar raha, to naya banao:

### Step 1: Naya Preset Banao
1. Settings → Upload → Upload presets
2. **"Add upload preset"** par click karo
3. Fill karo:
   ```
   Preset name: gnetwork_unsigned
   Signing mode: Unsigned ✅
   Folder: (khali chhod do)
   ```
4. **"Save"** par click karo

### Step 2: Code Update Karo
File: `lib/core/services/firestore_service.dart`

```dart
// Purana (line 577 aur 609 ke paas)
final cloudinary = CloudinaryPublic(
  'dqhkwsqhi',
  'g_network_preset',  // Purana preset
  cache: false
);

// Naya
final cloudinary = CloudinaryPublic(
  'dqhkwsqhi',
  'gnetwork_unsigned',  // Naya preset
  cache: false
);
```

### Step 3: Test Karo
```bash
flutter run
```

## Quick Test - cURL Se

Terminal mein ye command chalo:
```bash
curl -X POST https://api.cloudinary.com/v1_1/dqhkwsqhi/image/upload -F "file=@test.jpg" -F "upload_preset=g_network_preset"
```

**Agar Unsigned hai**: JSON response milega with `secure_url` ✅
**Agar Signed hai**: 401 error milega ❌

## Summary - Kya Karna Hai

### Zaruri Steps:
1. ✅ Cloudinary Dashboard kholo
2. ✅ Settings → Upload → Upload presets
3. ✅ `g_network_preset` par click karo
4. ✅ "Signing Mode" ko "Unsigned" karo
5. ✅ "Save" par click karo
6. ✅ App restart karo
7. ✅ Upload test karo

### Result:
```
Pehle: HTTP 401 Unauthorized ❌
Baad mein: Upload successful ✅
```

### Time:
2 minute

### Difficulty:
Bahut aasan - sirf ek setting change karni hai!

## Important Notes

### Yaad Rakho:
- Preset name: `g_network_preset`
- Cloud name: `dqhkwsqhi`
- Signing mode: **Unsigned** (zaruri!)
- Save karna mat bhulna

### Kahan Upload Hoga:
- Profile pictures: `profile_pictures/` folder
- Post images: `post_images/` folder
- Stories: `stories/` folder

### Security:
- Unsigned mode safe hai mobile apps ke liye
- API secret code mein nahi hai (good!)
- Cloudinary dashboard se manage kar sakte ho

---

**Agli Step**: Dashboard mein jao aur Signing Mode change karo! 🚀

**Help Chahiye?** Error message share karo, main aur help karunga.
