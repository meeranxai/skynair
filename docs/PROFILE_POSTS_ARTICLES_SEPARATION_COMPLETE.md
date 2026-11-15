# Profile Posts & Articles Separation Complete

## Changes Made

### 1. UserModel - Added articlesCount Field
- Added `articlesCount` field to track articles separately from media posts
- `postsCount` now only counts media posts (postType == 'media')
- `articlesCount` counts articles (postType == 'article')
- Updated constructor, copyWith, toMap, and fromMap methods
- HiveField(16) assigned to articlesCount

### 2. Profile Stats Widget - Separate Counts
Before: Posts | Followers | Following
After: Posts | Articles | Followers | Following

- Posts stat shows media posts count only
- Articles stat shows articles count separately
- Updated icons:
  - Posts: Icons.photo_library_outlined
  - Articles: Icons.article_outlined

### 3. FirestoreService - Separate Streams
Added two methods:
- `getUserPostsStream()` - Returns only media posts (postType == 'media')
- `getUserArticlesStream()` - Returns only articles (postType == 'article')

Both methods:
- Filter by authorId and postType
- Order by createdAt descending
- Include fallback for missing indexes

### 4. Posts Provider - New Provider
- `userPostsProvider` - Streams media posts only
- `userArticlesProvider` - Streams articles only (NEW)

### 5. Profile Content Tabs - Fixed Tabs
**Posts Tab:**
- Shows media posts in Instagram-style grid (3 columns)
- Uses `userPostsProvider`
- Empty state: "No media posts yet"

**Articles Tab:**
- Shows articles in list view
- Uses `userArticlesProvider` (NEW)
- Empty state: "No articles yet"

**Media Tab:**
- Same as Posts tab (duplicate for now)
- Can be removed or repurposed later

## Database Impact

### Firestore Indexes Needed
You may need to create these composite indexes:

```
Collection: posts
Fields:
1. authorId (Ascending) + postType (Ascending) + createdAt (Descending)
```

If you get index errors, Firebase will provide a link to create them automatically.

### User Document Updates
Existing users will have `articlesCount: 0` by default (handled in fromMap).
When users create new articles/posts, the counts will update correctly.

## Files Modified

1. `lib/core/models/user_model.dart`
   - Added articlesCount field
   - Updated all methods

2. `lib/features/profile/widgets/profile_stats.dart`
   - Added Articles stat
   - Updated layout to 4 stats

3. `lib/core/services/firestore_service.dart`
   - Added getUserArticlesStream method
   - Updated getUserPostsStream to filter media only

4. `lib/core/providers/posts_provider.dart`
   - Added userArticlesProvider

5. `lib/features/profile/widgets/profile_content_tabs.dart`
   - Fixed Posts tab to show grid of media posts
   - Fixed Articles tab to use userArticlesProvider
   - Updated imports

## Testing

1. Create a media post (with image)
   - Should appear in Posts tab (grid)
   - Should increment postsCount

2. Create an article (text only or with optional image)
   - Should appear in Articles tab (list)
   - Should increment articlesCount

3. Check profile stats
   - Posts count should show media posts only
   - Articles count should show articles only

## Notes

- Posts and Media tabs are currently identical (both show media posts grid)
- Consider removing Media tab or repurposing it
- Articles are displayed in list format for better readability
- Media posts are displayed in grid format (Instagram style)
