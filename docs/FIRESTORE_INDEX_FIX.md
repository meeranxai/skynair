# Firestore Index Error Fix

## Problem
You're getting this error: `[cloud_firestore/failed-precondition] The query requires an index`

For simple `orderBy('createdAt')` queries, you only need a **single field index**, not a composite index.

## Solutions (Choose One)

### Option 1: Firebase Console - Single Field Index (Recommended)
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `g-network-community`
3. Go to Firestore Database → Indexes
4. Click **Single field** tab (not "Composite")
5. Find `posts` collection or click **Add field**
6. Set:
   - **Collection**: `posts`
   - **Field path**: `createdAt`
   - **Query scopes**: ✅ Collection
   - **Order**: ✅ Enable (both Ascending and Descending)
7. Click **Save**

### Option 2: Use Error Link (Quick)
1. Click the URL in the error message
2. It will suggest creating a composite index
3. **Instead**, go to Single field tab and create the simple index above

### Option 3: Deploy via CLI
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login: `firebase login`
3. Run: `deploy_indexes.bat`

## What I've Done

1. ✅ Updated `firestore.indexes.json` with correct single field indexes
2. ✅ Added error handling to Firestore service (temporary fallback)
3. ✅ Created deployment script (`deploy_indexes.bat`)

## Current Status

Your app will work even without the indexes (using local sorting as fallback), but for better performance, create the single field index.

## Required Indexes

**Single Field Indexes:**
- `posts.createdAt` (ascending + descending)
- `userProfiles.username` (ascending)
- `posts.title` (ascending)

**Composite Index (only for user posts):**
- `posts`: `authorId` (ascending) + `createdAt` (descending)

The simple `orderBy('createdAt')` query only needs the single field index!