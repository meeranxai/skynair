# Phase 1: Article System - Quick Start Implementation

## 🎯 Quick Summary

**Goal**: Text-only article platform with AI recommendations

**Timeline**: Phase 1 (Current)

**Key Limits**:
- Content: 400-1500 chars
- Title: 50-100 chars (optional)
- Comments: 200-300 chars
- No images (Phase 2)

---

## 📝 Implementation Order

### Step 1: Update Article Model (30 min)
```dart
// lib/core/models/article_model.dart
class ArticleModel {
  String? title;              // NEW: Optional 50-100 chars
  List<String> categories;    // NEW: Tags for filtering
  // Remove: imageUrl (Phase 2)
}
```

### Step 2: Update Create Article Page (2 hours)
- Add title field (optional)
- Add category selector
- Update validation (400-1500 chars)
- Remove image upload
- Add character counters

### Step 3: Update Article Feed (3 hours)
- Add MySpace tab
- Add ForYou tab (AI recommendations)
- Add category filter
- Update article card (show preview)
- Add tags display

### Step 4: Update Comment System (1 hour)
- Limit to 300 characters
- Add character counter
- Update validation

### Step 5: Add Feedback System (2 hours)
- Create feedback form
- Add feedback types
- Add report article feature
- Store in Firestore

---

## 🔧 Key Code Changes

### 1. Article Validation

```dart
// lib/core/utils/article_validator.dart
class ArticleValidator {
  static const int minContent = 400;
  static const int maxContent = 1500;
  static const int minTitle = 50;
  static const int maxTitle = 100;
  
  static String? validateContent(String content) {
    if (content.length < minContent) {
      return 'Article must be at least $minContent characters';
    }
    if (content.length > maxContent) {
      return 'Article cannot exceed $maxContent characters';
    }
    return null;
  }
  
  static String? validateTitle(String? title) {
    if (title == null || title.isEmpty) return null; // Optional
    if (title.length < minTitle) {
      return 'Title must be at least $minTitle characters';
    }
    if (title.length > maxTitle) {
      return 'Title cannot exceed $maxTitle characters';
    }
    return null;
  }
}
```

### 2. Article Preview

```dart
// lib/core/utils/text_utils.dart
String getArticlePreview(String content, {int maxLines = 3}) {
  const int charsPerLine = 40;
  const int maxChars = charsPerLine * maxLines;
  
  if (content.length <= maxChars) return content;
  
  int cutoff = content.lastIndexOf(' ', maxChars);
  if (cutoff == -1) cutoff = maxChars;
  
  return '${content.substring(0, cutoff)}...';
}
```

### 3. Category Enum

```dart
// lib/core/models/article_category.dart
enum ArticleCategory {
  technology,
  business,
  lifestyle,
  health,
  education,
  entertainment,
  sports,
  politics,
  science,
  other;
  
  String get displayName {
    switch (this) {
      case ArticleCategory.technology:
        return 'Technology';
      case ArticleCategory.business:
        return 'Business & Finance';
      // ... etc
    }
  }
}
```

---

## 📱 UI Updates

### Create Article Page

**Add**:
- Title TextField (optional)
- Category chips (multi-select)
- Character counters
- Validation indicators

**Remove**:
- Image picker
- Media upload button

**Update**:
- Content min: 400 chars
- Content max: 1500 chars

### Article Feed Page

**Add**:
- MySpace tab
- ForYou tab
- Category filter dropdown
- Article preview (2-3 lines)
- Tags display

**Update**:
- Article card layout
- Show title if provided
- Show preview instead of full text

### Comment Section

**Update**:
- Max length: 300 chars
- Add character counter
- Update validation

---

## 🗄️ Firestore Structure

### Articles Collection

```
articles/{articleId}
  - userId: string
  - content: string (400-1500)
  - title: string? (50-100, optional)
  - categories: array<string>
  - createdAt: timestamp
  - updatedAt: timestamp
  - likeCount: number
  - commentCount: number
  - viewCount: number
  - saveCount: number
```

### Feedback Collection

```
feedback/{feedbackId}
  - userId: string
  - type: string (bug/suggestion/content/ui/other)
  - message: string (max 500)
  - articleId: string? (optional)
  - createdAt: timestamp
```

### Reports Collection

```
reports/{reportId}
  - articleId: string
  - reportedBy: string
  - reason: string
  - description: string? (max 200)
  - status: string (pending/reviewed/resolved)
  - createdAt: timestamp
```

---

## 🎨 UI Components to Create

### 1. CategorySelector Widget
```dart
class CategorySelector extends StatelessWidget {
  final List<ArticleCategory> selected;
  final Function(List<ArticleCategory>) onChanged;
  // Multi-select chip widget
}
```

### 2. CharacterCounter Widget
```dart
class CharacterCounter extends StatelessWidget {
  final int current;
  final int min;
  final int max;
  // Shows: "400/1500 characters"
}
```

### 3. ArticlePreviewCard Widget
```dart
class ArticlePreviewCard extends StatelessWidget {
  final ArticleModel article;
  // Shows: title, preview, tags, actions
}
```

### 4. FeedbackDialog Widget
```dart
class FeedbackDialog extends StatelessWidget {
  // Feedback form with type selector
}
```

### 5. ReportDialog Widget
```dart
class ReportDialog extends StatelessWidget {
  final String articleId;
  // Report form with reason selector
}
```

---

## 🔍 Testing Priority

### High Priority:
1. Content validation (400-1500)
2. Title validation (50-100, optional)
3. Article preview display
4. Category filtering
5. Comment length (300 max)

### Medium Priority:
6. MySpace feed
7. ForYou feed
8. Feedback submission
9. Report submission
10. Character counters

### Low Priority:
11. Empty states
12. Loading states
13. Error messages
14. UI polish

---

## 📊 Success Metrics

### Phase 1 Goals:
- [ ] Users can create text articles
- [ ] Articles have 400-1500 characters
- [ ] Optional titles work
- [ ] Categories filter correctly
- [ ] MySpace shows user's articles
- [ ] ForYou shows recommendations
- [ ] Comments limited to 300 chars
- [ ] Feedback system works
- [ ] Report system works

---

## 🚀 Quick Start Commands

```bash
# 1. Update models
# Edit: lib/core/models/post_model.dart

# 2. Update create page
# Edit: lib/features/create_post/pages/create_post_page.dart

# 3. Update feed page
# Edit: lib/features/articles/pages/articles_page.dart

# 4. Test
flutter run

# 5. Verify
# - Create article with 400+ chars
# - Add optional title
# - Select categories
# - View in MySpace
# - View in ForYou
# - Add comment (max 300)
# - Submit feedback
# - Report article
```

---

## 📚 Reference Documents

- `PHASE1_ARTICLE_SYSTEM_SPEC.md` - Complete specification
- `PHASE1_ISOLATE_RESTORE_GUIDE.md` - Media isolation guide
- `PHASE1_MEDIA_DISABLED_COMPLETE.md` - Phase 1 changes

---

## ⏱️ Estimated Timeline

| Task | Time | Priority |
|------|------|----------|
| Update models | 30 min | High |
| Create article page | 2 hours | High |
| Article feed | 3 hours | High |
| Comment system | 1 hour | Medium |
| Feedback system | 2 hours | Medium |
| Testing | 2 hours | High |
| **Total** | **~10 hours** | |

---

## ✅ Ready to Start!

Follow the implementation order above and refer to the complete spec for details.

**Next Step**: Update `lib/core/models/post_model.dart` to add title and categories fields.
