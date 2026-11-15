# Supabase 403 Error - Final Fix (Urdu)

## Problem Kya Thi?
```
StorageException (403): new row violates row level security policy
```

## Root Cause
**Supabase mein koi user hi nahi tha!**

SQL query `SELECT id, email, created_at FROM auth.users LIMIT 5;` ne **"No rows returned"** dikhaya.

---

## ✅ Complete Solution (Step by Step)

### Step 1: User Banana (ZARURI!)

#### Option A: Dashboard Se (Recommended)
1. Supabase Dashboard kholo: https://supabase.com/dashboard
2. **Authentication** → **Users** par jao
3. **"Add user"** button click karo
4. Details enter karo:
   - Email: `test@example.com`
   - Password: `Test123456`
   - Auto Confirm User: ✅ (check karo)
5. **"Create user"** click karo

#### Option B: Flutter App Se
1. App run karo: `flutter run`
2. Signup page par jao
3. Naya account banao
4. Email verify karo (agar enabled hai)

---

### Step 2: SQL Policies Lagao

Supabase Dashboard → **SQL Editor** mein jao aur ye paste karo:

```sql
-- 1. Check user ban gaya
SELECT id, email, created_at FROM auth.users LIMIT 5;

-- 2. Storage policies lagao
CREATE POLICY "Allow authenticated users to upload images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'images');

CREATE POLICY "Allow users to read all images"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'images');

CREATE POLICY "Allow users to update their own images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'images' AND owner = auth.uid());

CREATE POLICY "Allow users to delete their own images"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'images' AND owner = auth.uid());
```

**Ya phir**: `SUPABASE_COMPLETE_SETUP.sql` file ko copy-paste karo.

---

### Step 3: Flutter App Mein Test Karo

```bash
# App run karo
flutter run

# Ya test script run karo
test_supabase_user_create.bat
```

#### Test Checklist:
1. ✅ User login karo (jo Dashboard mein banaya)
2. ✅ Profile page par jao
3. ✅ Profile image upload karo
4. ✅ Success message dekho (403 error nahi aana chahiye)

---

## 🔍 Debugging (Agar Phir Bhi Issue Ho)

### Check 1: User Logged In Hai?
```dart
final user = Supabase.instance.client.auth.currentUser;
print('User ID: ${user?.id}'); // NULL nahi hona chahiye
print('User Email: ${user?.email}');
```

### Check 2: Bucket Exist Karta Hai?
1. Dashboard → **Storage** → **Buckets**
2. `images` bucket hona chahiye
3. Agar nahi hai:
   - **"New bucket"** click karo
   - Name: `images`
   - Public: `false` (unchecked)
   - **"Create bucket"** click karo

### Check 3: Owner Metadata Set Hai?
File: `lib/core/services/supabase_service.dart`

Har upload method mein ye hona chahiye:
```dart
metadata: userId != null ? {'owner': userId} : null
```

✅ **Already fixed hai!** (Task 8 mein fix kiya tha)

---

## 📊 Expected Results

### Before Fix:
```
❌ No users in Supabase
❌ 403 error on upload
❌ "new row violates row level security policy"
```

### After Fix:
```
✅ User exists in Supabase
✅ User logged in app mein
✅ Upload successful
✅ Image URL milta hai
```

---

## 📁 Related Files

### Documentation:
- `SUPABASE_USER_CREATE_URDU.md` - Detailed user creation guide
- `SUPABASE_403_DEBUG_COMPLETE_GUIDE_2026.md` - Complete debug guide
- `SUPABASE_SQL_EDITOR_AUTH_FIX.md` - SQL Editor auth explanation

### SQL Scripts:
- `SUPABASE_COMPLETE_SETUP.sql` - Complete setup queries
- `SUPABASE_STORAGE_POLICIES.sql` - Storage policies only

### Test Scripts:
- `test_supabase_user_create.bat` - Step-by-step test guide
- `test_supabase_upload.bat` - Upload test
- `test_profile_image_upload.bat` - Profile image test

### Code Files:
- `lib/core/services/supabase_service.dart` - Upload service (owner metadata ✅)
- `lib/core/config/app_config.dart` - Supabase config
- `.env.supabase` - Environment variables

---

## 🎯 Summary

### Problem:
User nahi tha → RLS policies kaam nahi kar rahe the → 403 error

### Solution:
1. User banao (Dashboard ya App se)
2. SQL policies lagao
3. Login karke test karo

### Result:
✅ Profile image upload successful!

---

## ⚠️ Important Notes

1. **SQL Editor mein `auth.uid()` NULL dikhata hai** - Ye normal hai! SQL Editor service_role key use karta hai, authenticated user nahi.

2. **Real test Flutter app mein karo** - Wahan `currentUser` check karo.

3. **Policies ek baar lagao** - Agar error aaye "policy already exists", ignore karo.

4. **Bucket public nahi hona chahiye** - Security ke liye `public: false` rakho.

---

**Next Step**: Dashboard se user banao aur `test_supabase_user_create.bat` run karo!
