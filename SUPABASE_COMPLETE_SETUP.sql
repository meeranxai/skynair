-- ========================================
-- Supabase Complete Setup - Storage Policies
-- ========================================
-- Run this AFTER creating a user in Dashboard > Authentication > Users
-- Date: January 2026

-- Step 1: Verify user exists
-- Expected: Should return at least 1 row with user ID and email
SELECT id, email, created_at FROM auth.users LIMIT 5;

-- Step 2: Check existing policies
-- Expected: Shows all current policies on storage.objects
SELECT * FROM pg_policies WHERE tablename = 'objects';

-- Step 3: Create storage policies for 'images' bucket
-- These policies allow authenticated users to upload, read, update, and delete images

-- Policy 1: Allow authenticated users to upload images
CREATE POLICY "Allow authenticated users to upload images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'images');

-- Policy 2: Allow users to read all images
CREATE POLICY "Allow users to read all images"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'images');

-- Policy 3: Allow users to update their own images
CREATE POLICY "Allow users to update their own images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'images' AND owner = auth.uid());

-- Policy 4: Allow users to delete their own images
CREATE POLICY "Allow users to delete their own images"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'images' AND owner = auth.uid());

-- Step 4: Verify policies were created
-- Expected: Should show 4 policies for 'images' bucket
SELECT 
  policyname, 
  cmd, 
  qual, 
  with_check 
FROM pg_policies 
WHERE tablename = 'objects' 
AND policyname LIKE '%images%';

-- ========================================
-- Setup Complete!
-- ========================================
-- Next Steps:
-- 1. Login to your Flutter app with the user you created
-- 2. Try uploading a profile image
-- 3. Should work without 403 error
-- ========================================
