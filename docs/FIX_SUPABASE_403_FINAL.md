# Fix Supabase 403 Error - Final Solution

## Current Problem
Photo upload still giving 403 error despite policies being added.

## Root Cause
Multiple duplicate policies with wrong configurations are conflicting.

## Step-by-Step Fix

### Step 1: Clean All Policies
1. Go to Supabase Dashboard
2. Storage → images bucket → Policies tab
3. **Delete ALL existing policies** (click trash icon on each)
4. Confirm deletion

### Step 2: Add Only These 4 Policies

#### Policy 1: Allow Upload
```
Name: authenticated_insert
Operation: INSERT ✓
Target role: authenticated
Policy definition: WITH CHECK
Expression: bucket_id = 'images'
```

#### Policy 2: Allow Read
```
Name: public_select
Operation: SELECT ✓
Target role: public
Policy definition: USING
Expression: bucket_id = 'images'
```

#### Policy 3: Allow Update
```
Name: authenticated_update
Operation: UPDATE ✓
Target role: authenticated
Policy definition: USING
Expression: bucket_id = 'images'
```

#### Policy 4: Allow Delete
```
Name: authenticated_delete
Operation: DELETE ✓
Target role: authenticated
Policy definition: USING
Expression: bucket_id = 'images'
```

### Step 3: Verify RLS is Enabled
1. Go to: Database → Tables
2. Find: storage.objects
3. Check: RLS should be enabled ✓

If not enabled:
- Click on table
- Enable RLS toggle

### Step 4: Test Upload

Run this test:
```bash
flutter run -d 055812505M001846
```

Then:
1. Login to app
2. Go to Profile
3. Click Edit
4. Try to upload photo
5. Should work! ✓

## Common Issues & Solutions

### Issue 1: Still 403 after adding policies
**Solution:** 
- Make sure you're logged in (authenticated)
- Check if user session is valid
- Try logout and login again

### Issue 2: Policies not working
**Solution:**
- Delete ALL old policies first
- Add fresh policies one by one
- Make sure expressions are exactly: `bucket_id = 'images'`

### Issue 3: Wrong role selected
**Solution:**
- INSERT → authenticated (NOT public)
- SELECT → public (anyone can read)
- UPDATE → authenticated
- DELETE → authenticated

### Issue 4: Expression errors
**Solution:**
Use exactly this expression for all:
```sql
bucket_id = 'images'
```

NOT:
- `bucket_id = 'images' AND auth.uid()...` (too restrictive)
- `bucket_id = 'profile-images'` (wrong bucket name)

## Verify Your Setup

After setup, you should have:
- ✓ 4 policies total (no more, no less)
- ✓ 1 INSERT policy (authenticated)
- ✓ 1 SELECT policy (public)
- ✓ 1 UPDATE policy (authenticated)
- ✓ 1 DELETE policy (authenticated)
- ✓ All use expression: `bucket_id = 'images'`

## Debug Checklist

If still not working, check:

1. **User Authentication**
   ```dart
   // In app logs, look for:
   ✓ User signed in: user@email.com
   ✓ Supabase initialized successfully
   ```

2. **Bucket Name**
   - Dashboard: `images` ✓
   - Code: `images` ✓
   - Must match exactly!

3. **Internet Connection**
   - Supabase needs internet
   - Check WiFi/data

4. **File Size**
   - Max: 8 MB
   - Check if image is too large

5. **File Type**
   - Allowed: jpeg, png, webp
   - Check if correct format

## Alternative: Use Firebase Storage

If Supabase keeps giving issues, switch to Firebase Storage:

1. Already configured in your app
2. No policy setup needed
3. Works out of the box

To switch:
- Comment out Supabase upload code
- Use Firebase Storage instead
- Already in `storage.rules` file

## Need More Help?

Check Supabase logs:
1. Dashboard → Logs
2. Look for 403 errors
3. See exact reason for rejection

Or share the exact error message for more specific help!
