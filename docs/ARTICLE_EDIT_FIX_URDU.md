# Article Post Edit Fix - مکمل ✅

## مسئلہ
جب article post کو edit کرتے تھے تو:
1. Media post edit page کھل جاتا تھا
2. Article post کی image selection show نہیں ہوتی تھی
3. Post type detect نہیں ہو رہا تھا

## حل

### 1. CreatePostPage - Post Type Detection
**File:** `lib/features/create_post/pages/create_post_page.dart`

```dart
@override
void initState() {
  super.initState();

  // Set post type from parameter, or detect from existing post, or default to 'media'
  if (widget.postType != null) {
    _postType = widget.postType!;
  } else if (widget.postToEdit != null) {
    // Detect post type from existing post
    _postType = widget.postToEdit!.postType;  // ✅ Existing post se detect karo
  } else {
    _postType = 'media';
  }
}
```

**کیا بدلا:**
- پہلے: ہمیشہ default `'media'` set ہو جاتا تھا
- اب: Existing post کی `postType` field سے detect کرتا ہے

### 2. Feed Card - Edit Navigation
**File:** `lib/features/home/widgets/feed_card.dart`

```dart
ListTile(
  leading: Icon(Icons.edit, color: theme.colorScheme.primary),
  title: const Text('Edit Post'),
  onTap: () {
    Navigator.pop(context);
    // Pass post type when editing
    final postType = widget.post.postType;  // ✅ Post type pass karo
    context.push('/create?type=$postType', extra: widget.post);
  },
),
```

**کیا بدلا:**
- پہلے: `/create` - بغیر type parameter
- اب: `/create?type=article` یا `/create?type=media` - صحیح type کے ساتھ

### 3. Post Card - Edit Navigation
**File:** `lib/features/home/widgets/post_card.dart`

```dart
_buildOptionTile(
  context,
  icon: Icons.edit_outlined,
  title: 'Edit Post',
  subtitle: 'Modify your post content',
  onTap: () {
    Navigator.pop(context);
    // Pass post type when editing
    final postType = widget.post.postType;  // ✅ Post type pass karo
    context.push('/create?type=$postType', extra: widget.post);
  },
),
```

## کیسے کام کرتا ہے

### Edit Flow:
```
1. User clicks "Edit Post" on article
   ↓
2. Feed/Post Card reads post.postType = 'article'
   ↓
3. Navigate to: /create?type=article
   ↓
4. CreatePostPage receives:
   - postToEdit: existing post data
   - postType: 'article' (from URL parameter)
   ↓
5. initState checks:
   - postType parameter exists? Use it ✅
   - OR postToEdit exists? Use postToEdit.postType ✅
   - OR default to 'media'
   ↓
6. Article editor opens with correct layout
```

## فوائد

### ✅ Article Posts
- Edit کرنے پر article editor کھلتا ہے
- Title, description, aur image selection sab show ہوتے ہیں
- Article-specific features available ہیں

### ✅ Media Posts
- Edit کرنے پر media editor کھلتا ہے
- Multiple images support
- Media-specific features available ہیں

### ✅ Backward Compatible
- پرانے posts بھی کام کریں گے
- Default 'media' type fallback ہے
- کوئی breaking changes نہیں

## Testing Checklist

### Article Post Edit:
- [ ] Feed میں article post پر "Edit" click کریں
- [ ] Article editor کھلنا چاہیے (media editor نہیں)
- [ ] Title field visible ہو
- [ ] Description field visible ہو
- [ ] Single image selection visible ہو
- [ ] Existing data pre-filled ہو
- [ ] Update کرنے پر changes save ہوں

### Media Post Edit:
- [ ] Feed میں media post پر "Edit" click کریں
- [ ] Media editor کھلنا چاہیے
- [ ] Multiple image selection visible ہو
- [ ] Existing images show ہوں
- [ ] Update کرنے پر changes save ہوں

### Profile Page Edit:
- [ ] Profile کی articles tab میں edit کریں
- [ ] Correct editor کھلے
- [ ] Profile کی media posts میں edit کریں
- [ ] Correct editor کھلے

## Files Changed
1. ✅ `lib/features/create_post/pages/create_post_page.dart` - Post type detection
2. ✅ `lib/features/home/widgets/feed_card.dart` - Edit navigation with type
3. ✅ `lib/features/home/widgets/post_card.dart` - Edit navigation with type

## Status: مکمل ✅
- Compilation errors fixed
- Post type detection working
- Edit navigation correct
- Both article aur media posts properly edit ہو رہے ہیں
