# Implementation Plan: Phase 1 Article System

## Overview

This implementation plan breaks down the Phase 1 Article System into discrete, incremental tasks. Each task builds upon previous work and focuses on delivering specific functionality. The plan follows a bottom-up approach: models → services → providers → UI components → integration.

## Tasks

- [ ] 1. Set up core data models and enums
  - Create ArticleModel with all required fields
  - Create ArticleCategory enum with display names and icons
  - Create CommentModel for comment data
  - Create FeedbackModel and ReportModel
  - Create validation result classes
  - _Requirements: 1.1, 1.2, 2.2, 2.3, 3.1, 10.4, 13.2, 14.2_

- [ ] 2. Implement validation logic
  - [ ] 2.1 Create ArticleValidator class
    - Implement content length validation (400-1500 chars)
    - Implement title length validation (50-100 chars, optional)
    - Implement category limit validation (max 5)
    - Add helpful error messages with character counts
    - _Requirements: 1.1, 1.2, 1.4, 1.5, 2.2, 2.3, 3.3_

  - [ ]* 2.2 Write property test for content minimum length
    - **Property 1: Content Minimum Length Validation**
    - **Validates: Requirements 1.1, 1.4**

  - [ ]* 2.3 Write property test for content maximum length
    - **Property 2: Content Maximum Length Validation**
    - **Validates: Requirements 1.2, 1.5**

  - [ ]* 2.4 Write property test for title validation
    - **Property 4: Title Minimum Length Validation**
    - **Property 5: Title Maximum Length Validation**
    - **Validates: Requirements 2.2, 2.3**

  - [ ]* 2.5 Write property test for category limit
    - **Property 6: Category Limit Enforcement**
    - **Validates: Requirements 3.3**


- [ ] 3. Implement CommentValidator class
  - Add comment length validation (1-300 chars)
  - Add character counter logic with warning threshold
  - _Requirements: 10.3, 10.4, 10.5, 10.6_

  - [ ]* 3.1 Write property test for comment length validation
    - **Property 15: Comment Length Validation**
    - **Validates: Requirements 10.4**

- [ ] 4. Implement preview generation utilities
  - [ ] 4.1 Create ArticlePreviewGenerator class
    - Implement preview generation (first 2-3 lines, ~120 chars)
    - Add ellipsis appending for long content
    - Implement read time estimation
    - _Requirements: 1.6, 8.3, 8.4_

  - [ ]* 4.2 Write property test for preview generation
    - **Property 11: Preview Generation Consistency**
    - **Validates: Requirements 8.3**

  - [ ]* 4.3 Write property test for ellipsis appending
    - **Property 12: Ellipsis Appending**
    - **Validates: Requirements 8.4**

- [ ] 5. Implement Firestore service layer
  - [ ] 5.1 Create ArticleService
    - Implement createArticle method
    - Implement updateArticle method
    - Implement deleteArticle method with cascade deletion
    - Implement getArticleById method
    - Implement getUserArticles method (for MySpace)
    - Implement getArticlesByCategory method
    - Add pagination support (10 articles per page)
    - _Requirements: 1.1-1.6, 5.1-5.6, 7.1-7.7, 16.1-16.7, 17.1-17.7_

  - [ ]* 5.2 Write property test for cascade deletion
    - **Property 22: Cascade Deletion**
    - **Validates: Requirements 17.5**


- [ ] 6. Implement RecommendationService for ForYou feed
  - [ ] 6.1 Create RecommendationService class
    - Implement algorithm for AI recommendations
    - Weight user's liked categories (0.4)
    - Weight trending articles (0.3)
    - Weight followed users' articles (0.2)
    - Weight recency (0.1)
    - Exclude user's own articles
    - Filter articles from last 7 days
    - _Requirements: 6.1-6.8_

  - [ ]* 6.2 Write property test for category relevance
    - **Property 8: ForYou Category Relevance**
    - **Validates: Requirements 6.2**

  - [ ]* 6.3 Write property test for self-exclusion
    - **Property 9: ForYou Self-Exclusion**
    - **Validates: Requirements 6.6**

- [ ] 7. Implement EngagementService
  - [ ] 7.1 Create EngagementService class
    - Implement likeArticle method (increment count)
    - Implement unlikeArticle method (decrement count)
    - Implement saveArticle method (add to user's array)
    - Implement unsaveArticle method (remove from array)
    - Implement addComment method (increment count)
    - Implement deleteComment method (decrement count)
    - Implement trackView method (with 24-hour deduplication)
    - _Requirements: 9.1-9.7, 10.1-10.9, 11.1-11.7, 18.1-18.5_

  - [ ]* 7.2 Write property test for like count increment
    - **Property 13: Like Count Increment**
    - **Validates: Requirements 9.3**

  - [ ]* 7.3 Write property test for like count decrement
    - **Property 14: Like Count Decrement**
    - **Validates: Requirements 9.4**

  - [ ]* 7.4 Write property test for comment count updates
    - **Property 16: Comment Count Update on Add**
    - **Property 17: Comment Count Update on Delete**
    - **Validates: Requirements 10.9**

  - [ ]* 7.5 Write property test for save array operations
    - **Property 18: Save Array Addition**
    - **Property 19: Save Array Removal**
    - **Validates: Requirements 11.3, 11.4**

  - [ ]* 7.6 Write property test for view deduplication
    - **Property 23: View Count Deduplication**
    - **Validates: Requirements 18.2**


- [ ] 8. Implement FeedbackService and ReportService
  - [ ] 8.1 Create FeedbackService class
    - Implement submitFeedback method
    - Validate feedback message length (max 500 chars)
    - Store feedback in Firestore
    - _Requirements: 13.1-13.7_

  - [ ] 8.2 Create ReportService class
    - Implement submitReport method
    - Validate report description length (max 200 chars)
    - Check for duplicate reports (prevent same user reporting same article twice)
    - Store reports in Firestore with status tracking
    - _Requirements: 14.1-14.7_

  - [ ]* 8.3 Write property test for duplicate report prevention
    - **Property 20: Duplicate Report Prevention**
    - **Validates: Requirements 14.7**

- [ ] 9. Checkpoint - Ensure all services work correctly
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Implement state management providers
  - [ ] 10.1 Create ArticleStateProvider
    - Manage article creation/editing state
    - Handle validation state
    - Manage character counters
    - Handle category selection
    - _Requirements: 1.1-1.6, 2.1-2.6, 3.1-3.6_

  - [ ] 10.2 Create FeedStateProvider
    - Manage MySpace feed state
    - Manage ForYou feed state
    - Manage Category feed state
    - Handle pagination
    - Handle pull-to-refresh
    - Handle loading states
    - _Requirements: 5.1-5.6, 6.1-6.8, 7.1-7.7, 15.1-15.7_

  - [ ] 10.3 Create EngagementStateProvider
    - Manage like states
    - Manage save states
    - Manage comment states
    - Handle optimistic updates
    - _Requirements: 9.1-9.7, 10.1-10.9, 11.1-11.7_


- [ ] 11. Implement Create Article Page
  - [ ] 11.1 Build CreateArticlePage UI
    - Create page scaffold with AppBar
    - Add optional title TextField with character counter
    - Add required content TextField with character counter
    - Add category selector with chips (multi-select, max 5)
    - Add disabled image upload section with "Coming in Phase 2" message
    - Add Post/Update button (enabled only when valid)
    - Implement real-time validation feedback
    - Show character counters with color coding
    - _Requirements: 1.1-1.6, 2.1-2.6, 3.1-3.6, 4.1-4.4_

  - [ ] 11.2 Implement article creation flow
    - Connect to ArticleStateProvider
    - Handle form submission
    - Show success message
    - Navigate to feed on success
    - Handle errors gracefully
    - _Requirements: 1.1-1.6_

  - [ ] 11.3 Implement article editing flow
    - Pre-populate form with existing article data
    - Apply same validation as creation
    - Update article on save
    - Set isEdited flag
    - Update updatedAt timestamp
    - _Requirements: 16.1-16.7_

  - [ ]* 11.4 Write property test for edit validation consistency
    - **Property 21: Edit Validation Consistency**
    - **Validates: Requirements 16.4**

  - [ ]* 11.5 Write unit tests for CreateArticlePage
    - Test form rendering
    - Test validation feedback
    - Test character counters
    - Test category selection
    - Test submit button state


- [ ] 12. Implement Article Card Widget
  - [ ] 12.1 Build ArticleCard component
    - Display author avatar, name, and time ago
    - Display title (if provided) with max 2 lines
    - Display content preview (2-3 lines with ellipsis)
    - Display up to 3 category chips (clickable)
    - Display engagement metrics (like, comment, save, share)
    - Add tap handler to navigate to full article
    - Add category chip tap handler to filter feed
    - _Requirements: 8.1-8.8_

  - [ ] 12.2 Add edit/delete actions for MySpace
    - Show edit button for own articles
    - Show delete button for own articles
    - Implement delete confirmation dialog
    - Handle delete with cascade
    - _Requirements: 5.3, 16.1-16.7, 17.1-17.7_

  - [ ]* 12.3 Write unit tests for ArticleCard
    - Test rendering with title
    - Test rendering without title
    - Test preview generation
    - Test category chips
    - Test engagement buttons
    - Test edit/delete buttons visibility

- [ ] 13. Implement Feed Pages
  - [ ] 13.1 Build MySpaceFeedPage
    - Create page scaffold with tab/header
    - Integrate with FeedStateProvider
    - Display articles using ArticleCard
    - Implement infinite scroll (load more at 200px from bottom)
    - Implement pull-to-refresh
    - Show skeleton loaders while loading
    - Show empty state when no articles
    - Show end-of-feed message
    - _Requirements: 5.1-5.6, 15.1-15.7_

  - [ ]* 13.2 Write property test for MySpace sorting
    - **Property 7: MySpace Chronological Sorting**
    - **Validates: Requirements 5.2**


  - [ ] 13.3 Build ForYouFeedPage
    - Create page scaffold with tab/header
    - Integrate with FeedStateProvider and RecommendationService
    - Display recommended articles using ArticleCard
    - Implement infinite scroll
    - Implement pull-to-refresh
    - Show skeleton loaders while loading
    - Show empty state when no recommendations
    - _Requirements: 6.1-6.8, 15.1-15.7_

  - [ ] 13.4 Build CategoryFeedPage
    - Create page scaffold with category selector
    - Integrate with FeedStateProvider
    - Display filtered articles using ArticleCard
    - Implement category dropdown/chips for switching
    - Implement infinite scroll
    - Implement pull-to-refresh
    - Show skeleton loaders while loading
    - Show empty state for category
    - _Requirements: 7.1-7.7, 15.1-15.7_

  - [ ]* 13.5 Write property test for category filtering
    - **Property 10: Category Filter Accuracy**
    - **Validates: Requirements 7.2**

  - [ ]* 13.6 Write unit tests for feed pages
    - Test feed rendering
    - Test pagination
    - Test pull-to-refresh
    - Test empty states
    - Test loading states
    - Test error states

- [ ] 14. Checkpoint - Ensure article creation and feeds work correctly
  - Ensure all tests pass, ask the user if questions arise.


- [ ] 15. Implement engagement features
  - [ ] 15.1 Implement like functionality
    - Add like button to ArticleCard
    - Connect to EngagementStateProvider
    - Implement optimistic updates
    - Show filled heart when liked
    - Update like count in real-time
    - Handle errors gracefully
    - _Requirements: 9.1-9.7_

  - [ ] 15.2 Implement save/bookmark functionality
    - Add save button to ArticleCard
    - Connect to EngagementStateProvider
    - Implement optimistic updates
    - Show filled bookmark when saved
    - Update save count in real-time
    - Add saved articles to user profile
    - _Requirements: 11.1-11.7_

  - [ ] 15.3 Implement share functionality
    - Add share button to ArticleCard
    - Open native share dialog
    - Generate shareable text/link
    - Track share count
    - _Requirements: 12.1-12.5_

  - [ ]* 15.4 Write unit tests for engagement features
    - Test like toggle
    - Test save toggle
    - Test share dialog
    - Test optimistic updates
    - Test error handling

- [ ] 16. Implement comment system
  - [ ] 16.1 Build CommentSheet component
    - Create bottom sheet/page for comments
    - Display all comments sorted by createdAt DESC
    - Show comment author, content, and time ago
    - Add comment input field with character counter (max 300)
    - Add submit button (enabled when valid)
    - Show validation feedback
    - Allow users to delete their own comments
    - _Requirements: 10.1-10.9_

  - [ ] 16.2 Integrate with EngagementService
    - Load comments on open
    - Submit new comments
    - Delete comments
    - Update comment count in real-time
    - Handle errors gracefully
    - _Requirements: 10.1-10.9_

  - [ ]* 16.3 Write unit tests for comment system
    - Test comment rendering
    - Test comment submission
    - Test comment deletion
    - Test validation
    - Test character counter


- [ ] 17. Implement feedback system
  - [ ] 17.1 Build FeedbackDialog component
    - Create dialog with feedback type selector
    - Add feedback types: Bug, Suggestion, Content, UI/UX, Other
    - Add message TextField (max 500 chars)
    - Add character counter
    - Add submit button
    - Show validation feedback
    - _Requirements: 13.1-13.7_

  - [ ] 17.2 Integrate with FeedbackService
    - Submit feedback to Firestore
    - Show success confirmation
    - Handle errors gracefully
    - Optionally associate with article
    - _Requirements: 13.1-13.7_

  - [ ]* 17.3 Write unit tests for feedback system
    - Test dialog rendering
    - Test type selection
    - Test message validation
    - Test submission
    - Test success/error states

- [ ] 18. Implement reporting system
  - [ ] 18.1 Build ReportDialog component
    - Create dialog with report reason selector
    - Add report reasons: Spam, Inappropriate, Harassment, Misinformation, Copyright, Other
    - Add optional description TextField (max 200 chars)
    - Add character counter
    - Add submit button
    - Show validation feedback
    - _Requirements: 14.1-14.7_

  - [ ] 18.2 Integrate with ReportService
    - Check for duplicate reports
    - Submit report to Firestore
    - Show success confirmation
    - Handle errors gracefully
    - _Requirements: 14.1-14.7_

  - [ ]* 18.3 Write unit tests for reporting system
    - Test dialog rendering
    - Test reason selection
    - Test description validation
    - Test duplicate prevention
    - Test submission


- [ ] 19. Implement navigation and routing
  - [ ] 19.1 Add article routes
    - Add route for create article page
    - Add route for edit article page (with article ID)
    - Add route for article detail page
    - Add route for MySpace feed
    - Add route for ForYou feed
    - Add route for Category feed (with category parameter)
    - _Requirements: 5.1, 6.1, 7.1_

  - [ ] 19.2 Implement navigation flows
    - Navigate to create article from FAB
    - Navigate to edit article from MySpace
    - Navigate to article detail from card tap
    - Navigate to category feed from chip tap
    - Navigate back to feed after article creation/edit
    - _Requirements: 8.7, 8.8_

  - [ ]* 19.3 Write integration tests for navigation
    - Test create article flow
    - Test edit article flow
    - Test feed navigation
    - Test category filtering navigation

- [ ] 20. Implement error handling and empty states
  - [ ] 20.1 Add error handling
    - Display user-friendly error messages
    - Add retry buttons for network errors
    - Preserve user input on errors
    - Log errors for debugging
    - _Requirements: 19.1-19.5_

  - [ ] 20.2 Add empty states
    - MySpace empty state with create button
    - ForYou empty state with suggestions
    - Category empty state
    - Comments empty state
    - Search results empty state
    - _Requirements: 5.5, 19.1_

  - [ ] 20.3 Add loading states
    - Skeleton loaders for feeds
    - Loading indicators for actions
    - Progress indicators for submissions
    - _Requirements: 15.3_

  - [ ]* 20.4 Write unit tests for error handling
    - Test error message display
    - Test retry functionality
    - Test input preservation
    - Test empty states


- [ ] 21. Implement performance optimizations
  - [ ] 21.1 Optimize Firestore queries
    - Add proper indexes for queries
    - Implement query pagination
    - Cache frequently accessed data
    - Use Firestore transactions for counts
    - _Requirements: 15.1-15.7, 20.1-20.6_

  - [ ] 21.2 Optimize UI performance
    - Implement list view builders for feeds
    - Add image caching
    - Optimize widget rebuilds
    - Use const constructors where possible
    - _Requirements: 20.3_

  - [ ] 21.3 Add offline support
    - Cache recently viewed articles
    - Enable Firestore offline persistence
    - Show offline indicator
    - Queue actions for when online
    - _Requirements: 15.7_

  - [ ]* 21.4 Write performance tests
    - Test feed load time
    - Test scroll performance
    - Test interaction response time
    - Test memory usage

- [ ] 22. Final integration and testing
  - [ ] 22.1 Integration testing
    - Test end-to-end article creation flow
    - Test end-to-end engagement flow
    - Test feed switching and filtering
    - Test edit and delete flows
    - Test feedback and reporting flows
    - _Requirements: All_

  - [ ] 22.2 User acceptance testing
    - Create test articles with various lengths
    - Test all three feed types
    - Test all engagement features
    - Test error scenarios
    - Test on different devices/screen sizes
    - _Requirements: All_

  - [ ] 22.3 Performance validation
    - Measure feed load times
    - Measure interaction response times
    - Check scroll performance (60 FPS)
    - Monitor memory usage
    - _Requirements: 20.1-20.6_

  - [ ] 22.4 Documentation
    - Document API endpoints
    - Document data models
    - Document validation rules
    - Add code comments
    - Create user guide

- [ ] 23. Final checkpoint - Ensure all features work correctly
  - Ensure all tests pass, ask the user if questions arise.


## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
- Integration tests validate end-to-end flows
- The implementation builds incrementally: models → services → providers → UI → integration

## Estimated Timeline

| Phase | Tasks | Estimated Time |
|-------|-------|----------------|
| Models & Validation | 1-4 | 4 hours |
| Services | 5-8 | 8 hours |
| State Management | 9-10 | 4 hours |
| UI Components | 11-14 | 12 hours |
| Engagement & Comments | 15-16 | 6 hours |
| Feedback & Reporting | 17-18 | 4 hours |
| Navigation & Polish | 19-21 | 6 hours |
| Testing & Integration | 22-23 | 6 hours |
| **Total** | | **~50 hours** |

## Dependencies

- Flutter SDK
- Riverpod for state management
- Firestore for database
- Existing authentication system
- Existing user profile system

## Success Criteria

- [ ] Users can create articles with 400-1500 characters
- [ ] Optional titles work correctly (50-100 chars)
- [ ] Categories can be selected (max 5)
- [ ] MySpace feed shows user's articles
- [ ] ForYou feed shows AI recommendations
- [ ] Category filtering works correctly
- [ ] Like, comment, save, and share features work
- [ ] Feedback and reporting systems work
- [ ] All validation rules are enforced
- [ ] Performance meets requirements (< 2s load, < 500ms interactions, 60 FPS)
- [ ] All property tests pass
- [ ] All unit tests pass
- [ ] All integration tests pass

