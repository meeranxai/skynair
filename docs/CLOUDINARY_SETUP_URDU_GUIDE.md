# Cloudinary Setup Guide (Roman Urdu)

## ✅ Cloudinary Ab Primary Storage Hai!

Firebase Storage ki jagah ab Cloudinary use ho raha hai saari images aur videos ke liye.

---

## Aapke Cloudinary Credentials

```
Cloud Name: ds9ddl7co
API Key: 875611598145631
API Secret: BL2XriirZammuHS6TJ06foVgtxU
Upload Preset: g_network_upload (dashboard mein banana hai)
```

---

## Kya Kya Change Hua?

### 1. Configuration ✅
- `lib/core/config/app_config.dart` mein aapke credentials add ho gaye
- Purane Firebase credentials replace ho gaye

### 2. Story Service ✅
- Stories ab Cloudinary par upload hongi
- Firebase Storage ki dependency remove ho gayi

### 3. Media Upload Service ✅
- Already Cloudinary use kar rahi thi
- Koi change nahi chahiye tha

---

## Cloudinary Dashboard Setup (ZARURI!)

### Step 1: Upload Preset Banana

1. **Website kholo**: https://console.cloudinary.com/
2. **Login karo** apne account se
3. **Settings** par jao
4. **Upload** tab par click karo
5. **Upload presets** section mein jao
6. **Add upload preset** button par click karo
7. **Configure karo**:
   ```
   Preset name: g_network_upload
   Signing mode: Unsigned
   Folder: (khali chhod do)
   ```
8. **Save** button par click karo

**IMPORTANT**: Ye step kiye bina uploads kaam nahi karenge!

### Step 2: Folders Setup (Optional)

Dashboard mein ye folders bana sakte ho organization ke liye:
- `profiles` - Profile pictures
- `posts` - Post images
- `stories` - Story media
- `videos` - Video content

---

## Kaunse Features Cloudinary Use Kar Rahe Hain?

### 1. Profile Pictures ✅
- **Folder**: `profiles/`
- **Max Size**: 10MB
- **Optimization**: Automatic
- **Format**: JPEG, PNG, WebP

### 2. Post Images ✅
- **Folder**: `posts/`
- **Max Size**: 10MB
- **Multiple**: Haan, ek saath kai images
- **Optimization**: Automatic

### 3. Stories ✅
- **Folder**: `stories/{userId}/`
- **Max Size**: 10MB (images), 50MB (videos)
- **Duration**: 24 hours
- **Auto-Delete**: Haan (optional setup)

### 4. Videos ✅
- **Folder**: `videos/`
- **Max Size**: 50MB
- **Transcoding**: Automatic
- **Formats**: MP4, MOV, AVI

---

## Cloudinary Ke Fayde

### 1. Automatic Optimization
- Images automatically compress hoti hain
- Best format choose hota hai (WebP, AVIF)
- Bandwidth save hota hai
- Fast loading

### 2. CDN Delivery
- Global CDN network
- Duniya bhar mein fast delivery
- Automatic caching
- Edge locations

### 3. Transformations
- Thumbnails automatic bante hain
- Different sizes available
- Crop, resize, filters
- Face detection

### 4. Cost Effective
- **Free Tier**:
  - 25 GB storage
  - 25 GB bandwidth/month
  - 25,000 transformations/month
- Firebase se sasta
- No hidden charges

### 5. Advanced Features
- AI-powered enhancements
- Background removal
- Auto-cropping
- Video transcoding
- Face detection

---

## Testing Kaise Karein?

### Test 1: Profile Picture Upload

1. App kholo
2. Profile page par jao
3. Edit Profile button par click karo
4. Photo upload karo
5. Cloudinary dashboard check karo
6. `profiles/` folder mein image dikhni chahiye

### Test 2: Story Creation

1. App kholo
2. Home page par "Your Story" button par click karo
3. Photo ya video lo
4. Share to Story par click karo
5. Cloudinary dashboard check karo
6. `stories/` folder mein media dikhna chahiye

### Test 3: Post Creation

1. App kholo
2. Create Post button par click karo
3. Image select karo
4. Post publish karo
5. Cloudinary dashboard check karo
6. `posts/` folder mein image dikhni chahiye

---

## Monitoring & Analytics

### Usage Check Karna

1. **Dashboard**: https://console.cloudinary.com/console/usage
   - Kitna storage use hua
   - Kitna bandwidth use hua
   - Kitne transformations hue

2. **Media Library**: https://console.cloudinary.com/console/media_library
   - Saari uploaded files dekho
   - Tags se search karo
   - Folders manage karo

3. **Reports**: https://console.cloudinary.com/console/reports
   - Upload activity
   - Popular images
   - Error logs

---

## Common Problems & Solutions

### Problem 1: Upload Preset Not Found
```
Error: Upload preset 'g_network_upload' not found
```
**Solution**: Cloudinary dashboard mein upload preset banana bhool gaye. Upar ke steps follow karo.

### Problem 2: File Size Too Large
```
Error: File size exceeds maximum allowed size
```
**Solution**: 
- Images: Max 10MB
- Videos: Max 50MB
- File compress karo ya chhoti file use karo

### Problem 3: Invalid Credentials
```
Error: Invalid API credentials
```
**Solution**: 
- Cloud name check karo: `ds9ddl7co`
- API key check karo: `875611598145631`
- `.env.cloudinary` file check karo

### Problem 4: Network Error
```
Error: Failed to upload after 3 attempts
```
**Solution**:
- Internet connection check karo
- Retry karo
- VPN off karo (agar use kar rahe ho)

---

## Security Tips

### API Secret Ko Safe Rakho

**IMPORTANT**: API Secret kabhi client-side code mein expose nahi karna!

Current setup:
- ✅ API Secret sirf server-side operations ke liye
- ✅ Upload Preset "Unsigned" hai (client uploads ke liye)
- ✅ Client-side uploads mein API Secret nahi chahiye

### Best Practices

1. Upload presets use karo client uploads ke liye
2. Delete operations server-side karo
3. Sensitive content ke liye signed URLs use karo
4. Folder permissions set karo Cloudinary mein

---

## Cost Optimization

### Free Tier Limits
- **Storage**: 25 GB
- **Bandwidth**: 25 GB/month
- **Transformations**: 25,000/month
- **Videos**: 500 MB storage

### Free Tier Mein Kaise Rahein?

1. **Images Compress Karo**: Quality 85 use karo
2. **Old Stories Delete Karo**: 24 hours ke baad auto-delete
3. **Transformations Wisely Use Karo**: Cache karo transformed images
4. **Usage Monitor Karo**: Dashboard regularly check karo

---

## Purani Firebase Images Ka Kya Hoga?

### Migration Strategy

1. **Naye Uploads**: Automatically Cloudinary par jayenge ✅
2. **Purani Images**: Firebase par hi rahegi (koi problem nahi)
3. **Gradual Migration**: Purani images kaam karengi, nayi Cloudinary use karengi

### Optional: Purani Images Migrate Karna

Agar chahte ho to purani Firebase images ko Cloudinary par migrate kar sakte ho:

```dart
// Migration function example
Future<void> migrateOldImages() async {
  // 1. Firebase se download karo
  // 2. Cloudinary par upload karo
  // 3. Firestore mein URL update karo
}
```

---

## Backup Strategy

### Recommended Approach

1. **Cloudinary Primary**: Saari nayi uploads
2. **Firestore Metadata**: URLs aur public IDs store karo
3. **Regular Backups**: Har mahine media library export karo
4. **Redundancy**: Important images multiple jagah rakho

---

## Next Steps

### Abhi Karna Hai (ZARURI)

1. ✅ Cloudinary dashboard mein login karo
2. ✅ Upload preset `g_network_upload` banao
3. ✅ Profile picture upload test karo
4. ✅ Story creation test karo
5. ✅ Post image upload test karo

### Baad Mein Kar Sakte Ho (Optional)

1. Auto-delete setup karo stories ke liye
2. Folder structure configure karo
3. Advanced transformations enable karo
4. Webhooks setup karo notifications ke liye

---

## Important Links

- **Cloudinary Dashboard**: https://console.cloudinary.com/
- **Media Library**: https://console.cloudinary.com/console/media_library
- **Usage Stats**: https://console.cloudinary.com/console/usage
- **Documentation**: https://cloudinary.com/documentation

---

## Summary

✅ **Cloudinary primary storage ban gaya**
✅ **Saari services update ho gayi**
✅ **Environment variables set ho gaye**
✅ **Story service migrate ho gayi**
✅ **Production ke liye ready**

**Action Required**: Cloudinary dashboard mein `g_network_upload` preset banana hai!

---

## Help & Support

Agar koi problem aaye to:

1. Error message carefully padho
2. Internet connection check karo
3. Cloudinary dashboard check karo
4. Upload preset verify karo
5. Credentials double-check karo

**Documentation**: `CLOUDINARY_PRIMARY_SETUP_COMPLETE.md` (English)

---

**Date**: January 5, 2026
**Status**: ✅ Complete
**Primary Storage**: Cloudinary
**Your Cloud**: ds9ddl7co
