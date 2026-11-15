# Phase 1: Isolated Features - Complete Restore Guide

## 📋 Overview

This document contains **exact details** of what was isolated/disabled in Phase 1 and **step-by-step instructions** to restore everything in Phase 2.

---

## 🚫 What Was Isolated/Disabled

### 1. Media Feed Tab
- **Status**: Disabled (shows "Coming Soon" page)
- **Original Route**: `/home`
- **Current Route**: `/coming-soon-media`
- **Features Affected**: 
  - Photo posts viewing
  - Stories viewing
  - Media feed scrolling
  - All media interactions

### 2. Media Post Creation
- **Status**: Disabled in create dialog
- **Original**: Clickable option
- **Current**: Grayed out with "Coming Soon in Phase 2" message
- **Features Affected**:
  - Photo upload in posts
  - Media post creation
  - Image editing before post

### 3. Stories Feature
- **Status**: Isolated (part of media feed)
- **Original**: Accessible via media feed
- **Current**: Not accessible (media feed disabled)
- **Features Affected**:
  - Story creation
  - Story viewing
  - Story bar

---

## 📁 Files Modified

### File 1: `lib/core/router/layouts/main_layout.dart`

#### Location 1: Navigation Items (Line ~33)
**What Changed**: Media tab route

**Original Code**:
```dart
NavigationItem(
  icon: Icons.photo_library_outlined,
  selectedIcon: Icons.photo_library,
  label: 'Media',
  route: '/home', // ← Original route
),
```

**Current Code**:
```dart
NavigationItem(
  icon: Icons.photo_library_outlined,
  selectedIcon: Icons.photo_library,
  label: 'Media', // Coming Soon in Phase 2
  route: '/coming-soon-media', // ← Changed route
),
```

**To Restore**: Change route back to `/home`

---

#### Location 2: Create Post Dialog (Line ~65)
**What Changed**: Media post option disabled

**Original Code**:
```dart
ListTile(
  leading: const Icon(Icons.photo_library),
  title: const Text('Media Post'),
  subtitle: const Text('Post with image (required)'),
  onTap: () {
    Navigator.pop(context);
    context.go('/create?type=media');
  },
),
```

**Current Code**:
```dart
// Media Post - Disabled in Phase 1
ListTile(
  leading: Icon(
    Icons.photo_library,
    color: Theme.of(context).disabledColor, // ← Grayed out
  ),
  title: Text(
    'Media Post',
    style: TextStyle(
      color: Theme.of(context).disabledColor, // ← Grayed out
    ),
  ),
  subtitle: Text(
    'Coming Soon in Phase 2', // ← Changed subtitle
    style: TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontSize: 12,
    ),
  ),
  enabled: false, // ← Disabled
),
```

**To Restore**: 
1. Remove `color: Theme.of(context).disabledColor` from icon
2. Remove `style` from title
3. Change subtitle back to `'Post with image (required)'`
4. Remove `enabled: false`
5. Add back `onTap` handler

---

### File 2: `lib/core/router/router_provider.dart`

#### Location 1: Imports (Line ~1)
**What Changed**: Added coming soon page import

**Added Code**:
```dart
import '../../features/coming_soon/pages/coming_soon_page.dart';
```

**To Restore**: Can keep this import (won't hurt)

---

#### Location 2: Routes (Line ~105)
**What Changed**: Added coming soon route

**Added Code**:
```dart
// Phase 1: Coming Soon pages
GoRoute(
  path: '/coming-soon-media',
  builder: (context, state) => const ComingSoonPage(
    featureName: 'Media Feed',
    description:
        'Photo posts, stories, and media sharing will be available in Phase 2',
    icon: Icons.photo_library,
  ),
),
```

**To Restore**: Can keep this route (won't be accessed after restore)

---

### File 3: `lib/features/coming_soon/pages/coming_soon_page.dart`

#### What Changed**: New file created

**Purpose**: Shows "Coming Soon" placeholder page

**To Restore**: Can keep this file (useful for future features)

---

## 🔄 Complete Restoration Steps

### Step 1: Restore Media Tab Navigation

**File**: `lib/core/router/layouts/main_layout.dart`  
**Line**: ~33-40

**Find**:
```dart
NavigationItem(
  icon: Icons.photo_library_outlined,
  selectedIcon: Icons.photo_library,
  label: 'Media', // Coming Soon in Phase 2
  route: '/coming-soon-media',
),
```

**Replace With**:
```dart
NavigationItem(
  icon: Icons.photo_library_outlined,
  selectedIcon: Icons.photo_library,
  label: 'Media',
  route: '/home', // ← Restored
),
```

---

### Step 2: Restore Media Post Creation

**File**: `lib/core/router/layouts/main_layout.dart`  
**Line**: ~70-90

**Find**:
```dart
// Media Post - Disabled in Phase 1
ListTile(
  leading: Icon(
    Icons.photo_library,
    color: Theme.of(context).disabledColor,
  ),
  title: Text(
    'Media Post',
    style: TextStyle(
      color: Theme.of(context).disabledColor,
    ),
  ),
  subtitle: Text(
    'Coming Soon in Phase 2',
    style: TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontSize: 12,
    ),
  ),
  enabled: false,
),
```

**Replace With**:
```dart
ListTile(
  leading: const Icon(Icons.photo_library),
  title: const Text('Media Post'),
  subtitle: const Text('Post with image (required)'),
  onTap: () {
    Navigator.pop(context);
    context.go('/create?type=media');
  },
),
```

---

### Step 3: Test Restoration

After making changes, test:

1. **Media Tab**:
   - Click Media tab
   - Should show media feed (not coming soon page)
   - Should see photo posts
   - Should see stories

2. **Create Button**:
   - Click Create button
   - Media Post option should be clickable
   - Should navigate to media post creation
   - Should allow photo upload

3. **Stories**:
   - Should see story bar in media feed
   - Should be able to create stories
   - Should be able to view stories

---

## 📊 Quick Reference Table

| Feature | Original State | Phase 1 State | File Location | Line Number |
|---------|---------------|---------------|---------------|-------------|
| Media Tab Route | `/home` | `/coming-soon-media` | `main_layout.dart` | ~38 |
| Media Tab Label | "Media" | "Media" (same) | `main_layout.dart` | ~37 |
| Media Post Option | Enabled | Disabled | `main_layout.dart` | ~70-90 |
| Media Post Subtitle | "Post with image" | "Coming Soon Phase 2" | `main_layout.dart` | ~82 |
| Coming Soon Page | N/A | Created | `coming_soon_page.dart` | New File |
| Coming Soon Route | N/A | Added | `router_provider.dart` | ~105 |

---

## 🔍 Verification Checklist

### Before Restoration (Phase 1):
- [ ] Media tab shows "Coming Soon" page
- [ ] Media post option is grayed out
- [ ] Create dialog shows "Coming Soon in Phase 2"
- [ ] Stories not accessible
- [ ] Articles feed is main tab

### After Restoration (Phase 2):
- [ ] Media tab shows media feed
- [ ] Media post option is clickable
- [ ] Can create media posts
- [ ] Can upload photos
- [ ] Stories are accessible
- [ ] Story bar visible in media feed

---

## 🎯 Files That Were NOT Modified

These files contain media features but were **NOT changed**:

### Preserved Files:
- `lib/features/home/pages/home_page.dart` - Media feed page (intact)
- `lib/features/stories/pages/story_camera_page.dart` - Story creation (intact)
- `lib/features/stories/providers/story_provider.dart` - Story logic (intact)
- `lib/features/stories/services/story_service.dart` - Story service (intact)
- `lib/features/home/widgets/story_bar.dart` - Story bar widget (intact)
- `lib/features/home/widgets/feed_card.dart` - Media post card (intact)
- `lib/core/services/supabase_service.dart` - Image upload (intact)
- `lib/core/services/media_upload_service.dart` - Media upload (intact)
- `lib/core/providers/media_upload_provider.dart` - Upload provider (intact)

**All media code is preserved and ready to use!**

---

## ⚠️ Important Notes

### 1. No Code Deleted
- All media features are **intact**
- Only **routes changed**
- Only **UI disabled**
- **Zero code removal**

### 2. Easy Restoration
- Only **2 locations** to change
- Only **2 files** to modify
- Takes **less than 5 minutes**

### 3. Safe to Test
- Can restore anytime
- Can re-disable anytime
- No data loss
- No breaking changes

---

## 🚀 Quick Restore Commands

### Option 1: Manual (Recommended)
1. Open `lib/core/router/layouts/main_layout.dart`
2. Change line ~38: `/coming-soon-media` → `/home`
3. Change lines ~70-90: Restore media post ListTile
4. Save and run: `flutter run`

### Option 2: Search & Replace
Search for: `route: '/coming-soon-media'`  
Replace with: `route: '/home'`

Search for: `enabled: false,` (in media post ListTile)  
Replace with: Remove this line and restore onTap

---

## 📝 Restoration Checklist

Use this checklist when restoring:

```
Phase 2 Restoration Checklist:

[ ] Step 1: Open main_layout.dart
[ ] Step 2: Find NavigationItem for Media tab
[ ] Step 3: Change route from '/coming-soon-media' to '/home'
[ ] Step 4: Find _showPostTypeDialog method
[ ] Step 5: Find Media Post ListTile
[ ] Step 6: Remove disabled styling
[ ] Step 7: Change subtitle back to original
[ ] Step 8: Remove 'enabled: false'
[ ] Step 9: Add back onTap handler
[ ] Step 10: Save file
[ ] Step 11: Run flutter run
[ ] Step 12: Test media tab
[ ] Step 13: Test create button
[ ] Step 14: Test media post creation
[ ] Step 15: Test stories
[ ] Step 16: Verify all features work
```

---

## 🎨 Visual Comparison

### Phase 1 (Current):
```
Navigation:
[Feed] [Explore] [Create] [Media*] [Profile]
                           ↓
                    Coming Soon Page

Create Dialog:
┌─────────────────────┐
│ 📷 Media Post       │ ← Grayed out
│    Coming Soon...   │
├─────────────────────┤
│ 📄 Article          │ ← Active
└─────────────────────┘
```

### Phase 2 (After Restore):
```
Navigation:
[Feed] [Explore] [Create] [Media] [Profile]
                           ↓
                    Media Feed Page

Create Dialog:
┌─────────────────────┐
│ 📷 Media Post       │ ← Active
│    Post with image  │
├─────────────────────┤
│ 📄 Article          │ ← Active
└─────────────────────┘
```

---

## 🔗 Related Documentation

- `PHASE1_MEDIA_DISABLED_COMPLETE.md` - Complete Phase 1 changes
- `PHASE1_ARTICLES_FOCUS_COMPLETE.md` - Articles focus details
- `lib/features/coming_soon/pages/coming_soon_page.dart` - Coming soon page code

---

## ✅ Summary

**What Was Done**:
- Changed 1 route in navigation
- Disabled 1 option in create dialog
- Created 1 coming soon page
- Added 1 route for coming soon

**What Was NOT Done**:
- No code deleted
- No features removed
- No files deleted
- No breaking changes

**Restoration Time**: ~5 minutes  
**Restoration Difficulty**: Easy  
**Risk Level**: Zero  

---

**Last Updated**: January 2026  
**Phase**: 1 (Articles Focus)  
**Status**: Isolated & Documented  
**Restore Ready**: ✅ Yes
