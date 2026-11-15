# Fix Supabase Storage 403 Error

## Problem
```
StorageException: new row violates row level security policy
Status code: 403 - Unauthorized
```

This happens because Supabase Storage doesn't have proper policies set up.

## Quick Fix (Supabase Dashboard)

### Step 1: Create Storage Buckets

1. Go to Supabase Dashboard: https://app.supabase.com
2. Select your project: **g-network-community**
3. Go to **Storage** in left sidebar
4. Click **New Bucket**

Create these buckets:
- **Bucket name:** `profile-images`
- **Public bucket:** ✅ Yes (check this)
- Click **Create bucket**

Repeat for:
- **Bucket name:** `post-images`
- **Public bucket:** ✅ Yes

### Step 2: Set Storage Policies

1. Go to **Storage** → Click on `profile-images` bucket
2. Click **Policies** tab
3. Click **New Policy**
4. Choose **For full customization**

#### Policy 1: Allow Upload
```sql
Policy name: Allow authenticated uploads
Allowed operation: INSERT
Target roles: authenticated

WITH CHECK expression:
bucket_id = 'profile-images' AND auth.uid()::text = (storage.foldername(name))[1]
```

#### Policy 2: Allow Public Read
```sql
Policy name: Allow public read
Allowed operation: SELECT
Target roles: public

USING expression:
bucket_id = 'profile-images'
```

#### Policy 3: Allow Delete Own Files
```sql
Policy name: Allow delete own files
Allowed operation: DELETE
Target roles: authenticated

USING expression:
bucket_id = 'profile-images' AND auth.uid()::text = (storage.foldername(name))[1]
```

### Step 3: Repeat for post-images bucket

Do the same 3 policies for `post-images` bucket (just change bucket_id to 'post-images')

## Alternative: Use SQL Editor

1. Go to **SQL Editor** in Supabase Dashboard
2. Click **New Query**
3. Copy and paste from `SUPABASE_STORAGE_POLICIES.sql`
4. Click **Run**

## Test After Setup

1. Run the app
2. Try to edit profile and upload image
3. Should work now! ✅

## Common Issues

### Issue: Bucket not found
**Solution:** Make sure bucket names are exactly:
- `profile-images` (with hyphen, not underscore)
- `post-images`

### Issue: Still getting 403
**Solution:** 
1. Check if buckets are marked as **Public**
2. Verify policies are created (Storage → Bucket → Policies tab)
3. Make sure you're logged in (authenticated)

### Issue: Wrong bucket name in code
**Solution:** Check `lib/core/services/supabase_service.dart` - bucket names should match

## Verify Setup

After setup, you should see:
- ✅ 2 buckets created (profile-images, post-images)
- ✅ Both marked as Public
- ✅ 3 policies per bucket (INSERT, SELECT, DELETE)
- ✅ Profile image upload works

## Need Help?

If still not working:
1. Check Supabase logs (Dashboard → Logs)
2. Verify `.env.supabase` has correct credentials
3. Make sure user is authenticated before uploading
