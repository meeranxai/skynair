# Supabase 403 RLS Error - Complete Debug Guide (Jan 2026)

## مسئلہ (Problem)
```
StorageException (403): new row violates row level security policy
User logged in hai, policies bhi hain, phir bhi profile image upload fail
```

---

## Step 1: Storage vs Database Error - Identify Karo

### Quick Test Method

```dart
// Test 1: Storage Upload (without database update)
Future<void> testStorageOnly() async {
  try {
    final file = File('path/to/image.jpg');
    final bytes = await file.readAsBytes();
    
    // Direct storage upload
    final path = await Supabase.instance.client.storage
        .from('images')
        .uploadBinary(
          'test/${DateTime.now().millisecondsSinceEpoch}.jpg',
          bytes,
        );
    
    print('✅ Storage upload SUCCESS: $path');
  } catch (e) {
    print('❌ Storage upload FAILED: $e');
    // Agar yahan error aaye to STORAGE policy issue hai
  }
}

// Test 2: Database Update (without storage)
Future<void> testDatabaseOnly() async {
  try {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    
    await Supabase.instance.client
        .from('profiles')
        .update({'photo_url': 'https://example.com/test.jpg'})
        .eq('id', userId);
    
    print('✅ Database update SUCCESS');
  } catch (e) {
    print('❌ Database update FAILED: $e');
    // Agar yahan error aaye to DATABASE RLS issue hai
  }
}
```

### Error Message Analysis

```
Error Pattern                          | Issue Location
---------------------------------------|------------------
"storage.objects"                      | Storage Bucket Policy
"public.profiles" or "profiles"        | Database Table RLS
"bucket_id"                            | Storage Policy
"owner" or "user_id"                   | Ownership Check
```

---

## Step 2: Upsert Logic - File Overwrite Issue

### Problem: upsert: false + Existing File = 403

```dart
// ❌ WRONG: Agar file pehle se hai to fail hoga
await supabase.storage
    .from('images')
    .uploadBinary(
      'profile_pictures/profile_$userId.jpg',  // Same name
      bytes,
      fileOptions: FileOptions(
        contentType: 'image/jpeg',
        upsert: false,  // ❌ Existing file ko overwrite nahi karega
      ),
    );

// ✅ CORRECT: Existing file ko replace kar dega
await supabase.storage
    .from('images')
    .uploadBinary(
      'profile_pictures/profile_$userId.jpg',
      bytes,
      fileOptions: FileOptions(
        contentType: 'image/jpeg',
        upsert: true,  // ✅ Overwrite allowed
      ),
    );

// ✅ BEST: Unique filename har baar
await supabase.storage
    .from('images')
    .uploadBinary(
      'profile_pictures/profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      bytes,
      fileOptions: FileOptions(
        contentType: 'image/jpeg',
        upsert: false,  // Safe because filename is unique
      ),
    );
```

### Upsert Policy Requirements

```sql
-- Agar upsert: true use kar rahe ho to UPDATE policy bhi chahiye

-- INSERT policy (for new files)
CREATE POLICY "Allow authenticated users to upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'images');

-- UPDATE policy (for upsert)
CREATE POLICY "Allow users to update their own files"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'images' 
  AND owner = auth.uid()
);
```

---

## Step 3: SQL Policy Verification Queries

### Run These in Supabase SQL Editor

#### 3.1 Check Current User Authentication

```sql
-- Check if you're authenticated
SELECT 
  auth.uid() as current_user_id,
  auth.role() as current_role,
  auth.email() as current_email;

-- Expected Output:
-- current_user_id: <your-uuid>
-- current_role: authenticated
-- current_email: <your-email>
```

#### 3.2 Check Storage Bucket Configuration

```sql
-- Check bucket settings
SELECT 
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets
WHERE name = 'images';

-- Expected:
-- public: true
-- file_size_limit: 8388608 (8MB) or higher
-- allowed_mime_types: ['image/jpeg', 'image/png', 'image/jpg']
```

#### 3.3 Check Storage Policies

```sql
-- List all policies on storage.objects
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'storage' 
  AND tablename = 'objects';

-- You should see at least 4 policies:
-- 1. INSERT policy for authenticated
-- 2. SELECT policy for public
-- 3. UPDATE policy for authenticated
-- 4. DELETE policy for authenticated
```

#### 3.4 Test Storage INSERT Permission

```sql
-- Simulate INSERT as current user
SELECT 
  auth.uid() as user_id,
  'images' as bucket_id,
  'test/file.jpg' as name,
  -- Check if INSERT policy allows this
  (
    SELECT COUNT(*) > 0
    FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND cmd = 'INSERT'
      AND policyname LIKE '%authenticated%'
  ) as has_insert_policy;
```

#### 3.5 Test Storage UPDATE Permission (for upsert)

```sql
-- Check if user can UPDATE their own files
SELECT 
  o.id,
  o.name,
  o.bucket_id,
  o.owner,
  auth.uid() as current_user,
  (o.owner = auth.uid()) as can_update
FROM storage.objects o
WHERE o.bucket_id = 'images'
  AND o.owner = auth.uid()
LIMIT 5;
```

#### 3.6 Check Database Table RLS

```sql
-- Check profiles table policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'profiles';

-- Expected: UPDATE policy for authenticated users
```

#### 3.7 Test Database UPDATE Permission

```sql
-- Test if current user can update their profile
SELECT 
  id,
  email,
  photo_url,
  (id = auth.uid()) as can_update_own_profile
FROM profiles
WHERE id = auth.uid();
```

---

## Step 4: Folder Structure & Path Matching

### Policy Pattern Matching

```sql
-- Common Policy Pattern
CREATE POLICY "Users can upload to their own folder"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'images' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);
```

### Flutter Path Must Match

```dart
// ✅ CORRECT: Matches policy pattern
final userId = Supabase.instance.client.auth.currentUser!.id;

await supabase.storage
    .from('images')
    .uploadBinary(
      '$userId/profile.jpg',  // ✅ First folder = userId
      bytes,
    );

// Path breakdown:
// Full path: "userId/profile.jpg"
// (storage.foldername(name))[1] = "userId" ✅ Matches auth.uid()

// ❌ WRONG: Doesn't match policy
await supabase.storage
    .from('images')
    .uploadBinary(
      'profile_pictures/profile_$userId.jpg',  // ❌ First folder = "profile_pictures"
      bytes,
    );

// Path breakdown:
// Full path: "profile_pictures/profile_userId.jpg"
// (storage.foldername(name))[1] = "profile_pictures" ❌ NOT auth.uid()
```

### Policy vs Path Examples

| Policy Check | Flutter Path | Match? |
|-------------|--------------|--------|
| `(storage.foldername(name))[1] = auth.uid()::text` | `{userId}/file.jpg` | ✅ Yes |
| `(storage.foldername(name))[1] = auth.uid()::text` | `profile/{userId}/file.jpg` | ❌ No (first folder is "profile") |
| `(storage.foldername(name))[2] = auth.uid()::text` | `profile/{userId}/file.jpg` | ✅ Yes (second folder) |
| `name LIKE auth.uid()::text || '%'` | `{userId}_file.jpg` | ✅ Yes |

### Recommended Policy (Flexible)

```sql
-- Option 1: User folder at root
CREATE POLICY "Users upload to own folder"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'images' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Flutter path: '{userId}/profile.jpg'

-- Option 2: Shared folder with user subfolder
CREATE POLICY "Users upload to profile_pictures/userId"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'images' 
  AND (storage.foldername(name))[1] = 'profile_pictures'
  AND (storage.foldername(name))[2] = auth.uid()::text
);

-- Flutter path: 'profile_pictures/{userId}/profile.jpg'

-- Option 3: No folder restriction (simplest)
CREATE POLICY "Authenticated users can upload anywhere"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'images');

-- Flutter path: Any path works
```

---

## Step 5: Dashboard Simulation Feature

### Using Supabase Policy Simulator (2026)

#### 5.1 Navigate to Policies

```
Dashboard → Storage → images bucket → Policies tab
```

#### 5.2 Test Policy Simulation

```sql
-- Click "Test Policy" button

-- Simulation Query:
SELECT 
  auth.uid() as simulated_user,
  'images' as bucket_id,
  'profile_pictures/profile_test.jpg' as file_path,
  -- Test INSERT
  (
    SELECT policy_check('storage', 'objects', 'INSERT', 
      jsonb_build_object(
        'bucket_id', 'images',
        'name', 'profile_pictures/profile_test.jpg',
        'owner', auth.uid()
      )
    )
  ) as insert_allowed;
```

#### 5.3 Check Logs

```
Dashboard → Logs → Storage Logs

Filter by:
- Status: 403
- User: <your-user-id>
- Time: Last 1 hour

Look for:
- Exact error message
- Failed policy name
- Request path
```

---

## Complete Working Example (Jan 2026)

### SQL Policies (Run in SQL Editor)

```sql
-- 1. Enable RLS
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 2. Drop old policies
DROP POLICY IF EXISTS "Allow authenticated upload" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read" ON storage.objects;
DROP POLICY IF EXISTS "Allow user update" ON storage.objects;
DROP POLICY IF EXISTS "Allow user delete" ON storage.objects;

-- 3. Create new policies (Simple & Flexible)

-- INSERT: Any authenticated user can upload
CREATE POLICY "Allow authenticated upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'images');

-- SELECT: Public can read
CREATE POLICY "Allow public read"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'images');

-- UPDATE: Users can update their own files
CREATE POLICY "Allow user update"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'images' 
  AND owner = auth.uid()
);

-- DELETE: Users can delete their own files
CREATE POLICY "Allow user delete"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'images' 
  AND owner = auth.uid()
);

-- 4. Verify
SELECT policyname, cmd FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects';
```

### Flutter Code (Correct Implementation)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseUploadService {
  final _supabase = Supabase.instance.client;

  Future<String> uploadProfileImage(File imageFile) async {
    try {
      // 1. Check authentication
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('✅ User authenticated: ${user.id}');

      // 2. Read file
      final bytes = await imageFile.readAsBytes();
      print('✅ File read: ${bytes.length} bytes');

      // 3. Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_${user.id}_$timestamp.jpg';
      final filePath = 'profile_pictures/$fileName';

      print('📤 Uploading to: $filePath');

      // 4. Upload to storage with proper options
      await _supabase.storage
          .from('images')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/jpeg',
              upsert: true,  // ✅ Allow overwrite
              metadata: {
                'owner': user.id,  // ✅ Set owner metadata
              },
            ),
          );

      print('✅ Storage upload successful');

      // 5. Get public URL
      final publicUrl = _supabase.storage
          .from('images')
          .getPublicUrl(filePath);

      print('✅ Public URL: $publicUrl');

      // 6. Update database (profiles table)
      await _supabase
          .from('profiles')
          .update({'photo_url': publicUrl})
          .eq('id', user.id);

      print('✅ Database updated');

      return publicUrl;
    } on StorageException catch (e) {
      print('❌ Storage Error: ${e.message}');
      print('❌ Status Code: ${e.statusCode}');
      
      if (e.statusCode == '403') {
        print('🔍 RLS Policy Issue - Check:');
        print('   1. User is authenticated');
        print('   2. Storage policies exist');
        print('   3. Bucket name is correct');
        print('   4. Path matches policy pattern');
      }
      
      rethrow;
    } catch (e) {
      print('❌ General Error: $e');
      rethrow;
    }
  }
}
```

---

## Debugging Checklist

- [ ] User is authenticated (`auth.uid()` returns UUID)
- [ ] Bucket 'images' exists and is public
- [ ] Storage RLS is enabled
- [ ] INSERT policy exists for authenticated
- [ ] UPDATE policy exists (if using upsert: true)
- [ ] Path matches policy folder pattern
- [ ] File size within limit
- [ ] MIME type is allowed
- [ ] Owner metadata is set
- [ ] Database RLS allows profile update

---

## Quick Fix Commands

```bash
# Test authentication
curl -X GET 'https://your-project.supabase.co/rest/v1/profiles?select=*' \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Authorization: Bearer YOUR_USER_JWT"

# Test storage upload
curl -X POST 'https://your-project.supabase.co/storage/v1/object/images/test.jpg' \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Authorization: Bearer YOUR_USER_JWT" \
  -H "Content-Type: image/jpeg" \
  --data-binary '@/path/to/image.jpg'
```

---

## Fix Complete! 🎉

Ab aapko pata chal jayega ke error kahan se aa raha hai aur kaise fix karna hai!
