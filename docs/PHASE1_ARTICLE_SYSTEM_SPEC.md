# Phase 1: Article System - Complete Specification

## 📋 Overview

Text-based article platform with AI-powered recommendations, categories, and basic engagement features.

---

## 1️⃣ Post Creation

### Article Creation Form

#### Required Fields:
- **Content** (Main text)
  - Min: 400 characters
  - Max: 1500 characters
  - Validation: Real-time character count
  - Error: Show warning if below min or above max

#### Optional Fields:
- **Title**
  - Min: 50 characters
  - Max: 100 characters
  - Placeholder: "Give your article a catchy title..."
  - Optional: Can be left empty

- **Tags/Categories**
  - Multiple selection allowed
  - Used for filtering and trending
  - Predefined categories (see below)

#### Image Upload:
- **Status**: Disabled in Phase 1
- **Message**: "Image upload coming in Phase 2"
- **Implementation**: Hide/disable image picker

---

### Categories/Tags

Predefined categories for filtering:

```dart
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
  other,
}
```

**Display Names**:
- Technology
- Business & Finance
- Lifestyle
- Health & Wellness
- Education
- Entertainment
- Sports
- Politics & Society
- Science
- Other

---

### Validation Rules

```dart
// Content validation
minContentLength = 400
maxContentLength = 1500

// Title validation (optional)
minTitleLength = 50
maxTitleLength = 100

// Character counter display
"${currentLength}/${maxLength} characters"

// Error messages
if (content.length < 400) {
  "Article must be at least 400 characters"
}
if (content.length > 1500) {
  "Article cannot exceed 1500 characters"
}
if (title.isNotEmpty && title.length < 50) {
  "Title must be at least 50 characters"
}
if (title.length > 100) {
  "Title cannot exceed 100 characters"
}
```

---

## 2️⃣ Feed/Display

### Feed Types

#### 1. MySpace (User's Own Content)
- **Route**: `/articles?tab=myspace`
- **Content**: User's own articles only
- **Sort**: Newest first (createdAt DESC)
- **Features**:
  - Edit button on each article
  - Delete button on each article
  - View count
  - Engagement stats

#### 2. ForYou (AI/Trending)
- **Route**: `/articles?tab=foryou`
- **Content**: AI-powered recommendations
- **Algorithm**:
  - User preferences (liked categories)
  - Trending articles (high engagement)
  - Recent articles (last 7 days)
  - Followed users' articles
- **Sort**: Relevance score + recency

#### 3. Categories
- **Route**: `/articles?category={categoryName}`
- **Content**: Filtered by selected category
- **Sort**: Newest first
- **Features**:
  - Category filter chips
  - Easy switching between categories

---

### Article Card Display

Each article shows:

```
┌─────────────────────────────────────┐
│ 👤 Author Name        • 2h ago      │
├─────────────────────────────────────┤
│ 📰 Article Title (if provided)      │
│                                     │
│ First 2-3 lines of content preview  │
│ with ellipsis if longer...         │
│                                     │
│ 🏷️ #Technology #AI                 │
├─────────────────────────────────────┤
│ ❤️ 24  💬 5  🔖 Save  📤 Share     │
└─────────────────────────────────────┘
```

**Components**:
1. **Header**:
   - Author avatar (small)
   - Author name
   - Time ago (e.g., "2h ago", "1d ago")

2. **Title** (if provided):
   - Bold, larger font
   - Max 2 lines with ellipsis

3. **Preview**:
   - First 2-3 lines of content
   - Ellipsis (...) if longer
   - Tap to expand/read full

4. **Tags**:
   - Show up to 3 tags
   - Clickable to filter by tag

5. **Actions**:
   - Like count + button
   - Comment count + button
   - Save button
   - Share button

---

### Preview Logic

```dart
String getPreview(String content, {int maxLines = 3}) {
  // Calculate approximate characters for 3 lines
  const int charsPerLine = 40;
  const int maxChars = charsPerLine * maxLines;
  
  if (content.length <= maxChars) {
    return content;
  }
  
  // Find last space before maxChars
  int cutoff = content.lastIndexOf(' ', maxChars);
  if (cutoff == -1) cutoff = maxChars;
  
  return '${content.substring(0, cutoff)}...';
}
```

---

## 3️⃣ Text Limits

### Content Limits

```dart
class ArticleLimits {
  // Content
  static const int minContentLength = 400;
  static const int maxContentLength = 1500;
  
  // Title (optional)
  static const int minTitleLength = 50;
  static const int maxTitleLength = 100;
  
  // Preview
  static const int previewLines = 3;
  static const int previewCharsPerLine = 40;
  
  // Tags
  static const int maxTags = 5;
  static const int maxTagLength = 20;
}
```

### Readability Guidelines

**Why 400-1500 characters?**
- **400 min**: Ensures substantial content
- **1500 max**: Keeps articles scannable
- **Average**: ~200-300 words
- **Read time**: 1-2 minutes

**Character Count Display**:
```
Writing: 245/1500 characters
✅ Minimum reached: 400/1500
⚠️ Too short: 150/400 (need 250 more)
❌ Too long: 1600/1500 (remove 100)
```

---

## 4️⃣ Interactions

### Basic Engagement

#### 1. Like
- **Action**: Toggle like/unlike
- **Display**: Heart icon + count
- **Storage**: Firestore `likes` subcollection
- **Realtime**: Update count immediately

#### 2. Comment
- **Action**: Open comment sheet
- **Display**: Comment icon + count
- **Limit**: 200-300 characters per comment
- **Features**:
  - View all comments
  - Add new comment
  - Delete own comment
  - Like comments (optional)

#### 3. Save
- **Action**: Bookmark article
- **Display**: Bookmark icon (filled when saved)
- **Storage**: User's `savedArticles` array
- **Access**: View saved articles in profile

---

### Comment System

#### Comment Limits

```dart
class CommentLimits {
  static const int minLength = 1;
  static const int maxLength = 300; // Phase 1: 200-300 chars
  static const int recommendedMax = 200;
}
```

#### Comment Display

```
┌─────────────────────────────────────┐
│ 👤 User Name        • 5m ago        │
│ Comment text here with max 300      │
│ characters for Phase 1...           │
│ ❤️ 3                                │
└─────────────────────────────────────┘
```

#### Comment Features:
- Character counter while typing
- Warning at 250 characters
- Error at 300 characters
- Real-time validation

---

## 5️⃣ Navigation

### Feed Navigation

#### Tab Structure

```
┌─────────────────────────────────────┐
│ [MySpace] [ForYou] [Categories ▼]   │
└─────────────────────────────────────┘
```

**Tabs**:
1. **MySpace**: User's own articles
2. **ForYou**: AI-recommended feed
3. **Categories**: Dropdown with all categories

#### Scrollable Feed

**Features**:
- Infinite scroll (load more on scroll)
- Pull to refresh
- Smooth scrolling
- Skeleton loaders while loading
- Empty state messages

**Performance**:
```dart
// Pagination
const int articlesPerPage = 10;

// Load more trigger
scrollController.addListener(() {
  if (scrollController.position.pixels >= 
      scrollController.position.maxScrollExtent - 200) {
    loadMoreArticles();
  }
});
```

---

## 6️⃣ Feedback & Reporting

### Feedback System

#### Feedback Types

```dart
enum FeedbackType {
  bug,           // Technical issue
  suggestion,    // Feature request
  content,       // Content quality
  ui,            // UI/UX feedback
  other,         // General feedback
}
```

#### Feedback Form

```
┌─────────────────────────────────────┐
│ Give Feedback                       │
├─────────────────────────────────────┤
│ Type: [Dropdown]                    │
│ ○ Bug Report                        │
│ ○ Suggestion                        │
│ ○ Content Feedback                  │
│ ○ UI/UX Feedback                    │
│ ○ Other                             │
│                                     │
│ Message:                            │
│ ┌─────────────────────────────────┐ │
│ │ Describe your feedback...       │ │
│ │                                 │ │
│ │ (Max 500 characters)            │ │
│ └─────────────────────────────────┘ │
│                                     │
│ [Cancel]              [Submit]      │
└─────────────────────────────────────┘
```

---

### Article Reporting

#### Report Reasons

```dart
enum ReportReason {
  spam,              // Spam or misleading
  inappropriate,     // Inappropriate content
  harassment,        // Harassment or hate
  misinformation,    // False information
  copyright,         // Copyright violation
  other,             // Other reason
}
```

#### Report Flow

1. **Trigger**: Long press on article or menu button
2. **Dialog**: Show report reasons
3. **Optional**: Add description (max 200 chars)
4. **Submit**: Send to moderation queue
5. **Confirmation**: "Thank you for reporting"

#### Report Storage

```dart
// Firestore structure
reports/{reportId}
  - articleId: string
  - reportedBy: userId
  - reason: ReportReason
  - description: string (optional)
  - timestamp: DateTime
  - status: 'pending' | 'reviewed' | 'resolved'
```

---

### Feedback Usage

**Phase 2 Refinement**:
- Analyze feedback patterns
- Identify most requested features
- Prioritize improvements
- A/B test changes
- Measure impact

**Metrics to Track**:
- Feedback submission rate
- Common feedback themes
- Feature request frequency
- Bug report patterns
- User satisfaction trends

---

## 7️⃣ Data Models

### Article Model

```dart
class ArticleModel {
  final String id;
  final String userId;
  final String content;          // 400-1500 chars
  final String? title;           // Optional, 50-100 chars
  final List<String> categories; // Tags/categories
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final int saveCount;
  
  // Metadata
  final Map<String, dynamic> metadata;
  
  // Phase 1: No images
  // final String? imageUrl; // Phase 2
}
```

### Comment Model

```dart
class CommentModel {
  final String id;
  final String articleId;
  final String userId;
  final String content;          // Max 300 chars
  final DateTime createdAt;
  final int likeCount;
}
```

### Feedback Model

```dart
class FeedbackModel {
  final String id;
  final String userId;
  final FeedbackType type;
  final String message;          // Max 500 chars
  final DateTime createdAt;
  final String? articleId;       // Optional: related article
}
```

### Report Model

```dart
class ReportModel {
  final String id;
  final String articleId;
  final String reportedBy;
  final ReportReason reason;
  final String? description;     // Max 200 chars
  final DateTime createdAt;
  final String status;           // pending/reviewed/resolved
}
```

---

## 8️⃣ UI Components

### Create Article Page

```dart
CreateArticlePage
├── AppBar
│   ├── Back button
│   ├── Title: "Create Article"
│   └── Post button (enabled when valid)
├── Body
│   ├── Title TextField (optional)
│   │   ├── Hint: "Title (optional)"
│   │   ├── Counter: "50/100"
│   │   └── Validation indicator
│   ├── Content TextField
│   │   ├── Hint: "Write your article..."
│   │   ├── Counter: "400/1500"
│   │   ├── Min length indicator
│   │   └── Validation indicator
│   ├── Category Selector
│   │   ├── Label: "Categories (optional)"
│   │   ├── Chips: Multi-select
│   │   └── Max 5 categories
│   └── Image Upload (Disabled)
│       └── Message: "Coming in Phase 2"
└── Bottom
    └── Character count summary
```

---

### Article Feed Page

```dart
ArticleFeedPage
├── AppBar
│   ├── Title: "Articles"
│   ├── Search icon
│   └── Filter icon
├── Tabs
│   ├── MySpace
│   ├── ForYou
│   └── Categories (dropdown)
├── Body
│   ├── RefreshIndicator
│   └── ListView
│       ├── ArticleCard (repeated)
│       ├── LoadingIndicator
│       └── EndOfFeedMessage
└── FAB
    └── Create Article button
```

---

### Article Card Widget

```dart
ArticleCard
├── Header
│   ├── Avatar
│   ├── Author name
│   ├── Time ago
│   └── Menu button (3 dots)
├── Content
│   ├── Title (if provided)
│   ├── Preview (2-3 lines)
│   └── "Read more" link
├── Tags
│   └── Category chips (max 3)
└── Actions
    ├── Like button + count
    ├── Comment button + count
    ├── Save button
    └── Share button
```

---

## 9️⃣ Implementation Checklist

### Phase 1 Tasks

#### Article Creation:
- [ ] Create article form with validation
- [ ] Title field (optional, 50-100 chars)
- [ ] Content field (required, 400-1500 chars)
- [ ] Category selector (multi-select)
- [ ] Character counters (real-time)
- [ ] Validation messages
- [ ] Disable image upload
- [ ] Post button (enabled when valid)

#### Feed Display:
- [ ] MySpace tab (user's articles)
- [ ] ForYou tab (AI recommendations)
- [ ] Category filter
- [ ] Article card component
- [ ] Preview logic (2-3 lines)
- [ ] Infinite scroll
- [ ] Pull to refresh
- [ ] Skeleton loaders

#### Interactions:
- [ ] Like functionality
- [ ] Comment system (max 300 chars)
- [ ] Save/bookmark feature
- [ ] Share functionality
- [ ] View count tracking

#### Feedback & Reporting:
- [ ] Feedback form
- [ ] Feedback types
- [ ] Report article feature
- [ ] Report reasons
- [ ] Moderation queue

#### Navigation:
- [ ] Tab navigation
- [ ] Category dropdown
- [ ] Smooth scrolling
- [ ] Empty states
- [ ] Error handling

---

## 🔟 Testing Checklist

### Functional Testing:
- [ ] Create article with min length (400)
- [ ] Create article with max length (1500)
- [ ] Create article with title
- [ ] Create article without title
- [ ] Select multiple categories
- [ ] View MySpace feed
- [ ] View ForYou feed
- [ ] Filter by category
- [ ] Like article
- [ ] Unlike article
- [ ] Add comment (max 300 chars)
- [ ] Save article
- [ ] Unsave article
- [ ] Share article
- [ ] Report article
- [ ] Submit feedback

### Validation Testing:
- [ ] Content below 400 chars (error)
- [ ] Content above 1500 chars (error)
- [ ] Title below 50 chars (warning)
- [ ] Title above 100 chars (error)
- [ ] Comment above 300 chars (error)
- [ ] Empty content (error)

### UI/UX Testing:
- [ ] Character counters update
- [ ] Validation messages show
- [ ] Preview displays correctly
- [ ] Tags display correctly
- [ ] Infinite scroll works
- [ ] Pull to refresh works
- [ ] Loading states show
- [ ] Empty states show

---

## Summary

**Phase 1 Focus**: Text-based articles with basic engagement

**Key Features**:
- ✅ Article creation (400-1500 chars)
- ✅ Optional title (50-100 chars)
- ✅ Categories/tags
- ✅ MySpace & ForYou feeds
- ✅ Like, comment, save
- ✅ Feedback & reporting
- ❌ Image upload (Phase 2)

**Character Limits**:
- Content: 400-1500
- Title: 50-100 (optional)
- Comment: 200-300
- Feedback: 500
- Report: 200

**Ready for Implementation**: ✅
