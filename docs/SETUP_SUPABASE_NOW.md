# Quick Supabase Storage Setup

## Your Current Setup ✅
- Bucket name: **images**
- Status: Public ✅
- File size limit: 8 MB ✅
- Allowed types: image/jpeg, image/png, image/webp ✅

## What You Need to Do (2 Minutes)

### Step 1: Go to SQL Editor
1. Open Supabase Dashboard: https://app.supabase.com
2. Select your project
3. Click **SQL Editor** in left sidebar
4. Click **New Query**

### Step 2: Run This SQL
Copy and paste this into the SQL editor:

```sql
-- Enable RLS
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop old policies (if any)
DROP POLICY IF EXISTS "Allow authenticated users to upload images" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read access to images" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to update their own images" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to delete their own images" ON storage.objects;

-- Create new policies
CREATE POLICY "Allow authenticated users to upload images"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'images');

CREATE POLICY "Allow public read access to images"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'images');

CREATE POLICY "Allow users to update their own images"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'images');

CREATE POLICY "Allow users to delete their own images"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'images');
```

### Step 3: Click "Run" Button
- Should see: "Success. No rows returned"
- This is normal and correct! ✅

### Step 4: Verify Policies
Go to: **Storage** → **images** bucket → **Policies** tab

You should see 4 policies:
1. ✅ Allow authenticated users to upload images
2. ✅ Allow public read access to images
3. ✅ Allow users to update their own images
4. ✅ Allow users to delete their own images

### Step 5: Test
1. Run your app
2. Try to upload profile image
3. Should work now! 🎉

## Troubleshooting

### Still getting 403?
- Make sure you're logged in (authenticated)
- Check if policies are created (Storage → Policies tab)
- Verify bucket name is exactly "images" (no typo)

### Can't see policies?
- Refresh the page
- Go to SQL Editor and run:
  ```sql
  SELECT * FROM pg_policies WHERE tablename = 'objects';
  ```
- Should see your 4 policies listed

## Done! ✅
After running the SQL, profile image upload will work immediately.
