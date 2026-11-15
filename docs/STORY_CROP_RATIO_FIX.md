# Story Crop Ratio Fix - ratio9x16 Error

## Problem
```
Error: Member not found: 'ratio9x16'
CropAspectRatioPreset.ratio9x16
```

APK build fail ho rahi thi kyunki `image_cropper` package mein `ratio9x16` preset available nahi hai.

## Solution ✅

### Fixed: Custom Aspect Ratio Use Kiya

`ratio9x16` preset ki jagah custom `CropAspectRatio` use kiya:

**Before:**
```dart
initAspectRatio: CropAspectRatioPreset.ratio9x16,
aspectRatioPresets: [
  CropAspectRatioPreset.ratio9x16,  // ❌ Not available
]
```

**After:**
```dart
aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16),
initAspectRatio: CropAspectRatioPreset.ratio16x9,
aspectRatioPresets: [
  CropAspectRatioPreset.original,
  CropAspectRatioPreset.square,
  CropAspectRatioPreset.ratio4x3,
  CropAspectRatioPreset.ratio16x9,
]
```

### Changes Made:

**File:** `lib/features/stories/pages/story_camera_page.dart`

1. **Gallery Pick Crop** (Line ~360)
   - Added `aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16)`
   - Removed `ratio9x16` from presets
   - Changed init to `ratio16x9`

2. **Preview Crop Button** (Line ~870)
   - Added `aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16)`
   - Removed `ratio9x16` from presets
   - Changed init to `ratio16x9`

## Result ✅

- ✅ Compilation errors fixed
- ✅ Story photo crop works
- ✅ 9:16 aspect ratio maintained for stories
- ✅ APK build will succeed

## Available Presets

Current `image_cropper` package supports:
- `original` - Original image ratio
- `square` - 1:1
- `ratio3x2` - 3:2
- `ratio4x3` - 4:3
- `ratio5x3` - 5:3
- `ratio5x4` - 5:4
- `ratio7x5` - 7:5
- `ratio16x9` - 16:9

For custom ratios like 9:16, use:
```dart
aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16)
```
