# Design Document: Phase 1 Article System

## Overview

This design document specifies the architecture and implementation details for Phase 1 of the Article System. The system provides a text-based article platform with AI-powered recommendations, category filtering, and basic engagement features. Phase 1 focuses exclusively on text content (400-1500 characters) with optional titles, deliberately excluding image uploads to establish core functionality first.

The system is designed using Flutter with Riverpod for state management, Firestore for data persistence, and follows a clean architecture pattern with clear separation between UI, business logic, and data layers.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Article System                            │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Presentation Layer (UI)                  │  │
│  │  - Create Article Page                                │  │
│  │  - Article Feed Pages (MySpace, ForYou, Categories)  │  │
│  │  - Article Detail Page                                │  │
│  │  - Comment Sheet                                      │  │
│  └───────────────────────────────────────────────────────┘  │
│                            │                                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Business Logic Layer (Providers)         │  │
│  │  - ArticleProvider                                    │  │
│  │  - FeedProvider (MySpace, ForYou, Category)          │  │
│  │  - EngagementProvider (Likes, Comments, Saves)       │  │
│  │  - FeedbackProvider                                   │  │
│  └───────────────────────────────────────────────────────┘  │
│                            │                                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Data Layer (Services)                    │  │
│  │  - ArticleService                                     │  │
│  │  - RecommendationService (AI/Trending)               │  │
│  │  - EngagementService                                  │  │
│  │  - FeedbackService                                    │  │
│  └───────────────────────────────────────────────────────┘  │
│                            │                                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Firestore Database                       │  │
│  │  - articles collection                                │  │
│  │  - comments subcollection                             │  │
│  │  - likes subcollection                                │  │
│  │  - feedback collection                                │  │
│  │  - reports collection                                 │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### State Management Strategy

The system uses Riverpod for state management with the following provider structure:

- **ArticleStateProvider**: Manages article creation and editing state
- **FeedStateProvider**: Manages feed data for MySpace, ForYou, and Category feeds
- **EngagementStateProvider**: Manages like, comment, and save states
- **FeedbackStateProvider**: Manages feedback and report submissions


## Components and Interfaces

### 1. Create Article Page

**Purpose:** Provide an interface for creating and editing text-based articles with validation.

**Component Structure:**
```dart
class CreateArticlePage extends ConsumerStatefulWidget {
  final String? articleId; // null for new, ID for editing
  
  // Features:
  // - Optional title field (50-100 chars)
  // - Required content field (400-1500 chars)
  // - Category selector (multi-select, max 5)
  // - Real-time character counters
  // - Validation feedback
  // - Disabled image upload with Phase 2 message
  // - Post/Update button (enabled when valid)
}
```

**Validation Logic:**
```dart
class ArticleValidator {
  static const int minContentLength = 400;
  static const int maxContentLength = 1500;
  static const int minTitleLength = 50;
  static const int maxTitleLength = 100;
  static const int maxCategories = 5;
  
  static ValidationResult validateContent(String content) {
    if (content.trim().isEmpty) {
      return ValidationResult.error('Content is required');
    }
    if (content.length < minContentLength) {
      int needed = minContentLength - content.length;
      return ValidationResult.error('Need $needed more characters (minimum $minContentLength)');
    }
    if (content.length > maxContentLength) {
      int excess = content.length - maxContentLength;
      return ValidationResult.error('Remove $excess characters (maximum $maxContentLength)');
    }
    return ValidationResult.success();
  }
  
  static ValidationResult validateTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return ValidationResult.success(); // Title is optional
    }
    if (title.length < minTitleLength) {
      return ValidationResult.warning('Title should be at least $minTitleLength characters');
    }
    if (title.length > maxTitleLength) {
      return ValidationResult.error('Title cannot exceed $maxTitleLength characters');
    }
    return ValidationResult.success();
  }
}
```


### 2. Article Feed Pages

**Purpose:** Display articles in different feed types with infinite scroll and filtering.

**Feed Types:**

**MySpace Feed:**
```dart
class MySpaceFeedPage extends ConsumerWidget {
  // Shows only current user's articles
  // Sorted by createdAt DESC
  // Includes edit/delete buttons
  // Shows all engagement metrics
}
```

**ForYou Feed:**
```dart
class ForYouFeedPage extends ConsumerWidget {
  // Shows AI-recommended articles
  // Algorithm:
  //   - User's liked categories (weight: 0.4)
  //   - Trending articles (weight: 0.3)
  //   - Followed users' articles (weight: 0.2)
  //   - Recency (weight: 0.1)
  // Excludes user's own articles
}
```

**Category Feed:**
```dart
class CategoryFeedPage extends ConsumerWidget {
  final ArticleCategory category;
  
  // Shows articles filtered by category
  // Sorted by createdAt DESC
  // Allows category switching
}
```

**Pagination Logic:**
```dart
class FeedPaginationController {
  static const int articlesPerPage = 10;
  static const double loadMoreThreshold = 200.0; // pixels from bottom
  
  void setupScrollListener(ScrollController controller) {
    controller.addListener(() {
      if (controller.position.pixels >= 
          controller.position.maxScrollExtent - loadMoreThreshold) {
        loadMoreArticles();
      }
    });
  }
}
```


### 3. Article Card Widget

**Purpose:** Display article preview in feeds with engagement actions.

**Component Structure:**
```dart
class ArticleCard extends ConsumerWidget {
  final ArticleModel article;
  final bool showActions; // edit/delete for MySpace
  
  // Layout:
  // ┌─────────────────────────────────────┐
  // │ 👤 Author Name        • 2h ago      │
  // ├─────────────────────────────────────┤
  // │ 📰 Article Title (if provided)      │
  // │                                     │
  // │ First 2-3 lines of content preview  │
  // │ with ellipsis if longer...         │
  // │                                     │
  // │ 🏷️ #Technology #AI                 │
  // ├─────────────────────────────────────┤
  // │ ❤️ 24  💬 5  🔖 Save  📤 Share     │
  // └─────────────────────────────────────┘
}
```

**Preview Generation:**
```dart
class ArticlePreviewGenerator {
  static const int maxPreviewLines = 3;
  static const int charsPerLine = 40;
  static const int maxPreviewChars = maxPreviewLines * charsPerLine;
  
  static String generatePreview(String content) {
    if (content.length <= maxPreviewChars) {
      return content;
    }
    
    // Find last space before cutoff to avoid breaking words
    int cutoff = content.lastIndexOf(' ', maxPreviewChars);
    if (cutoff == -1) cutoff = maxPreviewChars;
    
    return '${content.substring(0, cutoff)}...';
  }
  
  static int estimateReadTime(String content) {
    // Average reading speed: 200 words per minute
    const int wordsPerMinute = 200;
    int wordCount = content.split(RegExp(r'\s+')).length;
    int minutes = (wordCount / wordsPerMinute).ceil();
    return minutes < 1 ? 1 : minutes;
  }
}
```


### 4. Comment System

**Purpose:** Allow users to comment on articles with character limits.

**Component Structure:**
```dart
class CommentSheet extends ConsumerStatefulWidget {
  final String articleId;
  
  // Features:
  // - Display all comments (sorted by createdAt DESC)
  // - Add new comment (1-300 chars)
  // - Delete own comments
  // - Real-time character counter
  // - Validation feedback
}

class CommentModel {
  final String id;
  final String articleId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content; // 1-300 chars
  final DateTime createdAt;
  final int likeCount; // Optional for Phase 1
}
```

**Comment Validation:**
```dart
class CommentValidator {
  static const int minLength = 1;
  static const int maxLength = 300;
  static const int warningThreshold = 250;
  
  static ValidationResult validate(String content) {
    if (content.trim().isEmpty) {
      return ValidationResult.error('Comment cannot be empty');
    }
    if (content.length > maxLength) {
      return ValidationResult.error('Comment cannot exceed $maxLength characters');
    }
    if (content.length > warningThreshold) {
      int remaining = maxLength - content.length;
      return ValidationResult.warning('$remaining characters remaining');
    }
    return ValidationResult.success();
  }
}
```


### 5. Feedback and Reporting System

**Purpose:** Collect user feedback and handle content reports.

**Feedback Dialog:**
```dart
class FeedbackDialog extends ConsumerStatefulWidget {
  final String? articleId; // Optional: related article
  
  // Features:
  // - Feedback type selector (Bug, Suggestion, Content, UI/UX, Other)
  // - Message field (max 500 chars)
  // - Character counter
  // - Submit button
}

enum FeedbackType {
  bug,
  suggestion,
  content,
  ui,
  other;
  
  String get displayName {
    switch (this) {
      case FeedbackType.bug:
        return 'Bug Report';
      case FeedbackType.suggestion:
        return 'Suggestion';
      case FeedbackType.content:
        return 'Content Feedback';
      case FeedbackType.ui:
        return 'UI/UX Feedback';
      case FeedbackType.other:
        return 'Other';
    }
  }
}
```

**Report Dialog:**
```dart
class ReportDialog extends ConsumerStatefulWidget {
  final String articleId;
  
  // Features:
  // - Report reason selector
  // - Optional description (max 200 chars)
  // - Submit button
}

enum ReportReason {
  spam,
  inappropriate,
  harassment,
  misinformation,
  copyright,
  other;
  
  String get displayName {
    switch (this) {
      case ReportReason.spam:
        return 'Spam or Misleading';
      case ReportReason.inappropriate:
        return 'Inappropriate Content';
      case ReportReason.harassment:
        return 'Harassment or Hate';
      case ReportReason.misinformation:
        return 'False Information';
      case ReportReason.copyright:
        return 'Copyright Violation';
      case ReportReason.other:
        return 'Other';
    }
  }
}
```


## Data Models

### ArticleModel

```dart
class ArticleModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content; // 400-1500 chars
  final String? title; // Optional, 50-100 chars
  final List<ArticleCategory> categories; // Max 5
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final int saveCount;
  final bool isEdited;
  
  // Computed properties
  String get preview => ArticlePreviewGenerator.generatePreview(content);
  int get readTimeMinutes => ArticlePreviewGenerator.estimateReadTime(content);
  bool get hasTitle => title != null && title!.isNotEmpty;
  
  // Firestore serialization
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'title': title,
      'categories': categories.map((c) => c.name).toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'likeCount': likeCount,
      'commentCount': commentCount,
      'viewCount': viewCount,
      'saveCount': saveCount,
      'isEdited': isEdited,
    };
  }
  
  factory ArticleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ArticleModel(
      id: doc.id,
      userId: data['userId'],
      userName: data['userName'],
      userAvatar: data['userAvatar'],
      content: data['content'],
      title: data['title'],
      categories: (data['categories'] as List)
          .map((c) => ArticleCategory.values.byName(c))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      viewCount: data['viewCount'] ?? 0,
      saveCount: data['saveCount'] ?? 0,
      isEdited: data['isEdited'] ?? false,
    );
  }
}
```


### ArticleCategory Enum

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
  other;
  
  String get displayName {
    switch (this) {
      case ArticleCategory.technology:
        return 'Technology';
      case ArticleCategory.business:
        return 'Business & Finance';
      case ArticleCategory.lifestyle:
        return 'Lifestyle';
      case ArticleCategory.health:
        return 'Health & Wellness';
      case ArticleCategory.education:
        return 'Education';
      case ArticleCategory.entertainment:
        return 'Entertainment';
      case ArticleCategory.sports:
        return 'Sports';
      case ArticleCategory.politics:
        return 'Politics & Society';
      case ArticleCategory.science:
        return 'Science';
      case ArticleCategory.other:
        return 'Other';
    }
  }
  
  IconData get icon {
    switch (this) {
      case ArticleCategory.technology:
        return Icons.computer;
      case ArticleCategory.business:
        return Icons.business;
      case ArticleCategory.lifestyle:
        return Icons.style;
      case ArticleCategory.health:
        return Icons.favorite;
      case ArticleCategory.education:
        return Icons.school;
      case ArticleCategory.entertainment:
        return Icons.movie;
      case ArticleCategory.sports:
        return Icons.sports_soccer;
      case ArticleCategory.politics:
        return Icons.account_balance;
      case ArticleCategory.science:
        return Icons.science;
      case ArticleCategory.other:
        return Icons.more_horiz;
    }
  }
}
```


### FeedbackModel and ReportModel

```dart
class FeedbackModel {
  final String id;
  final String userId;
  final FeedbackType type;
  final String message; // Max 500 chars
  final String? articleId; // Optional
  final DateTime createdAt;
  
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'message': message,
      'articleId': articleId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class ReportModel {
  final String id;
  final String articleId;
  final String reportedBy;
  final ReportReason reason;
  final String? description; // Max 200 chars
  final DateTime createdAt;
  final ReportStatus status;
  
  Map<String, dynamic> toFirestore() {
    return {
      'articleId': articleId,
      'reportedBy': reportedBy,
      'reason': reason.name,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'status': status.name,
    };
  }
}

enum ReportStatus {
  pending,
  reviewed,
  resolved;
}
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Content Validation Properties

**Property 1: Content Minimum Length Validation**
*For any* content string, if its length is less than 400 characters, the validation should return an error and posting should be disabled.
**Validates: Requirements 1.1, 1.4**

**Property 2: Content Maximum Length Validation**
*For any* content string, if its length exceeds 1500 characters, the validation should return an error and prevent further input.
**Validates: Requirements 1.2, 1.5**

**Property 3: Character Counter Accuracy**
*For any* text input in the content field, the displayed character count should equal the actual string length.
**Validates: Requirements 1.3**

**Property 4: Title Minimum Length Validation**
*For any* non-empty title string, if its length is less than 50 characters, the validation should return a warning.
**Validates: Requirements 2.2**

**Property 5: Title Maximum Length Validation**
*For any* title string, if its length exceeds 100 characters, the validation should return an error.
**Validates: Requirements 2.3**

**Property 6: Category Limit Enforcement**
*For any* category selection attempt, if the current selection count is 5, adding another category should be prevented.
**Validates: Requirements 3.3**


### Feed and Sorting Properties

**Property 7: MySpace Chronological Sorting**
*For any* set of articles in MySpace feed, the articles should be sorted by createdAt in descending order (newest first).
**Validates: Requirements 5.2**

**Property 8: ForYou Category Relevance**
*For any* user with liked categories, recommended articles in ForYou feed should match at least one of those categories.
**Validates: Requirements 6.2**

**Property 9: ForYou Self-Exclusion**
*For any* user viewing ForYou feed, their own articles should never appear in the recommendations.
**Validates: Requirements 6.6**

**Property 10: Category Filter Accuracy**
*For any* selected category, all articles in the filtered feed should contain that category in their categories list.
**Validates: Requirements 7.2**

### Preview and Display Properties

**Property 11: Preview Generation Consistency**
*For any* article content, the preview should be the first N characters (where N ≤ 120) of the content.
**Validates: Requirements 8.3**

**Property 12: Ellipsis Appending**
*For any* article content longer than the preview length, the preview should end with "..." (ellipsis).
**Validates: Requirements 8.4**


### Engagement Properties

**Property 13: Like Count Increment**
*For any* article, when a like action is performed, the like count should increase by exactly 1.
**Validates: Requirements 9.3**

**Property 14: Like Count Decrement**
*For any* article, when an unlike action is performed, the like count should decrease by exactly 1.
**Validates: Requirements 9.4**

**Property 15: Comment Length Validation**
*For any* comment string, if its length exceeds 300 characters, the validation should return an error and prevent submission.
**Validates: Requirements 10.4**

**Property 16: Comment Count Update on Add**
*For any* article, when a comment is added, the comment count should increase by exactly 1.
**Validates: Requirements 10.9**

**Property 17: Comment Count Update on Delete**
*For any* article, when a comment is deleted, the comment count should decrease by exactly 1.
**Validates: Requirements 10.9**

**Property 18: Save Array Addition**
*For any* article save action, the article ID should be added to the user's savedArticles array.
**Validates: Requirements 11.3**

**Property 19: Save Array Removal**
*For any* article unsave action, the article ID should be removed from the user's savedArticles array.
**Validates: Requirements 11.4**


### Reporting and Moderation Properties

**Property 20: Duplicate Report Prevention**
*For any* user-article pair, if a report already exists, attempting to create another report should be prevented.
**Validates: Requirements 14.7**

### Edit and Delete Properties

**Property 21: Edit Validation Consistency**
*For any* article being edited, the same validation rules should apply as for article creation (content: 400-1500 chars, title: 50-100 chars if provided).
**Validates: Requirements 16.4**

**Property 22: Cascade Deletion**
*For any* article deletion, all associated likes, comments, and saves should be removed from the database.
**Validates: Requirements 17.5**

### View Tracking Properties

**Property 23: View Count Deduplication**
*For any* user-article pair, if a view was recorded within the last 24 hours, a new view attempt should not increment the count.
**Validates: Requirements 18.2**


## Error Handling

### Error Categories

**1. Validation Errors**
- Content too short (< 400 chars)
- Content too long (> 1500 chars)
- Title too short (< 50 chars when provided)
- Title too long (> 100 chars)
- Comment too long (> 300 chars)
- Too many categories (> 5)

**Handling Strategy:**
- Display inline error messages with specific guidance
- Disable submit buttons until errors are resolved
- Show character counters with color coding (red for errors, yellow for warnings, green for valid)
- Provide helpful suggestions (e.g., "Need 150 more characters")

**2. Network Errors**
- Failed to load articles
- Failed to submit article
- Failed to load comments
- Connection timeout

**Handling Strategy:**
- Display user-friendly error messages
- Provide retry button
- Cache data locally when possible
- Show offline indicator
- Preserve user input on failure

**3. Permission Errors**
- Attempting to edit another user's article
- Attempting to delete another user's article
- Attempting to access restricted content

**Handling Strategy:**
- Display clear permission denied message
- Hide edit/delete buttons for non-owned content
- Validate permissions on backend
- Log security violations

**4. Data Integrity Errors**
- Article not found
- User not found
- Invalid article ID
- Corrupted data

**Handling Strategy:**
- Display appropriate error message
- Redirect to safe state (e.g., feed page)
- Log errors for debugging
- Attempt data recovery when possible


## Testing Strategy

### Dual Testing Approach

This feature requires both unit tests and property-based tests to ensure comprehensive coverage:

**Unit Tests** focus on:
- Specific widget rendering scenarios
- Edge cases (empty states, maximum limits, boundary values)
- Error conditions and recovery
- Integration points between components
- UI interaction flows
- Navigation and routing

**Property-Based Tests** focus on:
- Universal properties across all inputs
- Validation logic consistency
- Data transformation invariants
- Sorting and filtering correctness
- State management consistency
- Engagement count accuracy

### Property-Based Testing Configuration

**Framework:** Use Dart's `test` package with custom property test helpers.

**Configuration:**
- Minimum 100 iterations per property test
- Each test must reference its design document property
- Tag format: `@Tags(['Feature: article-system', 'Property N: {property_text}'])`

**Example Property Test Structure:**
```dart
@Tags(['Feature: article-system', 'Property 1: Content Minimum Length Validation'])
test('Content under 400 chars should fail validation', () {
  // Generate random strings with length < 400
  for (int i = 0; i < 100; i++) {
    final content = generateRandomString(length: Random().nextInt(400));
    final result = ArticleValidator.validateContent(content);
    expect(result.isError, isTrue);
    expect(result.message, contains('400'));
  }
});
```

### Test Coverage Requirements

**Unit Tests:**
- All widgets must have dedicated test files
- Test rendering with various state combinations
- Test user interactions (taps, text input, scrolling)
- Test loading and error states
- Test navigation flows

**Integration Tests:**
- End-to-end article creation flow
- Feed loading and pagination
- Engagement actions (like, comment, save)
- Edit and delete flows
- Feedback and reporting flows

**Property Tests:**
- All 23 correctness properties must be implemented
- Each property maps to specific requirements
- Tests should use randomized inputs
- Focus on invariants and universal rules

### Performance Testing

**Metrics to Track:**
- Initial feed load time (< 2 seconds)
- Interaction response time (< 500ms)
- Scroll performance (60 FPS)
- Memory usage during pagination
- Database query performance

**Tools:**
- Flutter DevTools for performance profiling
- Custom benchmarks for critical paths
- Firestore query analysis

