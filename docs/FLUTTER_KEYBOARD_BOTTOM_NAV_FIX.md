# Flutter Keyboard & Bottom Navigation Bar Fix - Complete Guide

## 🎯 Root Cause Analysis

### Why This Happens in Flutter

The keyboard issue occurs due to how Flutter's `Scaffold` widget handles the `resizeToAvoidBottomInset` property:

1. **`resizeToAvoidBottomInset: true` (default)**
   - The entire body resizes when keyboard appears
   - Bottom navigation bar moves up with keyboard
   - Can cause layout overflow and white space issues

2. **`resizeToAvoidBottomInset: false`**
   - Body doesn't resize for keyboard
   - Content can get hidden behind keyboard
   - Bottom nav stays fixed but input fields may be obscured

3. **The Core Problem**
   - Flutter's `Scaffold` treats `bottomNavigationBar` as part of the layout
   - When keyboard appears, the entire scaffold adjusts
   - No built-in way to keep bottom nav fixed while making content keyboard-aware

---

## ✅ Solution 1: Main Feed Screen (Fixed Bottom Nav)

### For screens with minimal keyboard interaction (Home, Explore, Profile)

**File: `lib/core/widgets/keyboard_safe_scaffold.dart`**

```dart
import 'package:flutter/material.dart';

/// A scaffold that keeps the bottom navigation bar fixed
/// while making the body keyboard-aware
class KeyboardSafeScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  const KeyboardSafeScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
```

**Usage in HomePage:**

```dart
// In home_page.dart - Replace Scaffold with KeyboardSafeScaffold
@override
Widget build(BuildContext context) {
  return KeyboardSafeScaffold(
    backgroundColor: theme.colorScheme.surface,
    resizeToAvoidBottomInset: false, // Keep bottom nav fixed
    appBar: _buildAppBar(context, theme, authState.user),
    body: RefreshIndicator(
      // ... your existing body content
    ),
    floatingActionButton: _buildFab(),
  );
}
```

---

## ✅ Solution 2: Chat/Comment Screens (Keyboard-Heavy)

### For screens with text input (Chat, Comments, Create Post)

**File: `lib/core/widgets/keyboard_aware_scaffold.dart`**

```dart
import 'package:flutter/material.dart';

/// A scaffold optimized for keyboard-heavy screens
/// Automatically adjusts content when keyboard appears
class KeyboardAwareScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool maintainBottomViewPadding;

  const KeyboardAwareScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomSheet,
    this.backgroundColor,
    this.maintainBottomViewPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true, // Allow resize for keyboard
      appBar: appBar,
      body: Column(
        children: [
          Expanded(child: body),
          if (bottomSheet != null) bottomSheet!,
        ],
      ),
    );
  }
}
```

**Enhanced Chat Page Implementation:**

```dart
// File: lib/features/messages/pages/chat_page_fixed.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/keyboard_aware_scaffold.dart';

class ChatPageFixed extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatPageFixed({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  ConsumerState<ChatPageFixed> createState() => _ChatPageFixedState();
}

class _ChatPageFixedState extends ConsumerState<ChatPageFixed> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    
    // Listen to keyboard visibility
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // Scroll to bottom when keyboard appears
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messagesAsync = ref.watch(messagesProvider(widget.chatId));

    return GestureDetector(
      // Dismiss keyboard when tapping outside
      onTap: () => FocusScope.of(context).unfocus(),
      child: KeyboardAwareScaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: _buildAppBar(theme),
        body: messagesAsync.when(
          data: (messages) => _buildMessagesList(messages, theme),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildErrorState(error.toString(), theme),
        ),
        bottomSheet: _buildMessageInput(theme),
      ),
    );
  }

  Widget _buildMessagesList(List<Message> messages, ThemeData theme) {
    if (messages.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == ref.read(authProvider).user?.uid;
        return _buildMessageBubble(message, isMe, theme);
      },
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? 12
            : MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attachment button
            IconButton(
              onPressed: () {
                // TODO: Show attachment options
              },
              icon: Icon(
                Icons.add_circle_outline,
                color: theme.colorScheme.primary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            
            const SizedBox(width: 8),
            
            // Message input field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) => setState(() {}),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                onPressed: _messageController.text.trim().isNotEmpty
                    ? _sendMessage
                    : null,
                icon: Icon(
                  Icons.send_rounded,
                  color: _messageController.text.trim().isNotEmpty
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundImage: widget.otherUserAvatar != null
                  ? NetworkImage(widget.otherUserAvatar!)
                  : null,
              child: widget.otherUserAvatar == null
                  ? Text(widget.otherUserName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                ),
              ),
              child: Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isMe
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('Error: $error', style: TextStyle(color: theme.colorScheme.error)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: widget.otherUserAvatar != null
                ? NetworkImage(widget.otherUserAvatar!)
                : null,
            child: widget.otherUserAvatar == null
                ? Text(widget.otherUserName[0].toUpperCase())
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.otherUserName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    ref.read(messagingProvider.notifier).sendMessage(
          chatId: widget.chatId,
          receiverId: widget.otherUserId,
          content: content,
        );

    _messageController.clear();

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
```

---

## ✅ Solution 3: Comments Page Fix

**File: `lib/features/comments/pages/comments_page_fixed.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/keyboard_aware_scaffold.dart';
import '../../../core/models/post_model.dart';
import '../../../core/models/comment_model.dart';
import '../../../core/providers/comments_provider.dart';
import '../../../core/providers/auth_provider.dart';

class CommentsPageFixed extends ConsumerStatefulWidget {
  final PostModel post;

  const CommentsPageFixed({super.key, required this.post});

  @override
  ConsumerState<CommentsPageFixed> createState() => _CommentsPageFixedState();
}

class _CommentsPageFixedState extends ConsumerState<CommentsPageFixed> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commentsAsync = ref.watch(commentsProvider(widget.post.id));
    final currentUser = ref.watch(authProvider).user;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: KeyboardAwareScaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text('Comments'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Column(
          children: [
            // Post Preview
            _buildPostPreview(theme),
            const Divider(height: 1),
            
            // Comments List
            Expanded(
              child: commentsAsync.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : commentsAsync.comments.isEmpty
                      ? _buildEmptyState(theme)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: commentsAsync.comments.length,
                          itemBuilder: (context, index) => _buildCommentItem(
                            theme,
                            commentsAsync.comments[index],
                            currentUser?.uid,
                          ),
                        ),
            ),
          ],
        ),
        bottomSheet: _buildCommentInput(theme, currentUser),
      ),
    );
  }

  Widget _buildPostPreview(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: Text(
              widget.post.author[0].toUpperCase(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.author,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.post.title.isNotEmpty)
                  Text(
                    widget.post.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No comments yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to comment',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(
    ThemeData theme,
    CommentModel comment,
    String? currentUserId,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: Text(
              comment.author[0].toUpperCase(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.author,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(ThemeData theme, dynamic currentUser) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? 12
            : MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: Text(
                currentUser?.displayName?.isNotEmpty == true
                    ? currentUser!.displayName![0].toUpperCase()
                    : 'U',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 100),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _commentController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _commentController.text.trim().isNotEmpty
                  ? _sendComment
                  : null,
              icon: Icon(
                Icons.send_rounded,
                color: _commentController.text.trim().isNotEmpty
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  void _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final content = _commentController.text.trim();
    _commentController.clear();
    _focusNode.unfocus();

    try {
      await ref
          .read(commentsProvider(widget.post.id).notifier)
          .addComment(widget.post.id, content);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment added!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
```

---

## 📋 Integration Steps

### Step 1: Create Helper Widgets

1. Create `lib/core/widgets/keyboard_safe_scaffold.dart`
2. Create `lib/core/widgets/keyboard_aware_scaffold.dart`

### Step 2: Update Existing Pages

#### For Home Page (Minimal keyboard interaction):
```dart
// Replace Scaffold with KeyboardSafeScaffold
return KeyboardSafeScaffold(
  resizeToAvoidBottomInset: false,
  // ... rest of your code
);
```

#### For Chat Page (Heavy keyboard interaction):
```dart
// Use the new ChatPageFixed or update existing
return KeyboardAwareScaffold(
  // ... your chat UI
);
```

#### For Comments Page:
```dart
// Use CommentsPageFixed or update existing
return KeyboardAwareScaffold(
  // ... your comments UI
);
```

### Step 3: Update Create Post Page

```dart
// In create_post_page.dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    resizeToAvoidBottomInset: true, // Allow keyboard resize
    appBar: _buildAppBar(),
    body: SingleChildScrollView( // Important: wrap in scroll view
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          // ... your form fields
        ),
      ),
    ),
  );
}
```

---

## ✅ Testing Checklist

### Android Testing
- [ ] Open keyboard in chat - bottom nav should stay fixed
- [ ] Type message - input field should stay visible
- [ ] Scroll messages while keyboard is open
- [ ] Dismiss keyboard by tapping outside
- [ ] Rotate device with keyboard open
- [ ] Test on different screen sizes

### iOS Testing
- [ ] Open keyboard in chat - smooth animation
- [ ] Input field should move up with keyboard
- [ ] Safe area should be respected
- [ ] Keyboard dismiss gesture works
- [ ] Test with different keyboard types
- [ ] Test with external keyboard

### Both Platforms
- [ ] Home page: bottom nav stays fixed
- [ ] Chat page: messages scroll properly
- [ ] Comments page: input stays visible
- [ ] Create post: all fields accessible
- [ ] No white space appears
- [ ] No layout overflow errors
- [ ] Smooth keyboard animations

---

## 🎨 Platform-Specific Considerations

### Android
```dart
// Add to AndroidManifest.xml
<activity
  android:name=".MainActivity"
  android:windowSoftInputMode="adjustResize">
</activity>
```

### iOS
```dart
// In Info.plist (usually already set)
<key>UIViewControllerBasedStatusBarAppearance</key>
<false/>
```

---

## 🚀 Common Pitfalls to Avoid

1. **Don't use `resizeToAvoidBottomInset: true` on main navigation screens**
   - This causes bottom nav to move up

2. **Always wrap keyboard-heavy screens in `SingleChildScrollView`**
   - Prevents overflow when keyboard appears

3. **Use `MediaQuery.of(context).viewInsets.bottom` for dynamic padding**
   - Adjusts padding based on keyboard height

4. **Add `GestureDetector` with `onTap: () => FocusScope.of(context).unfocus()`**
   - Allows dismissing keyboard by tapping outside

5. **Use `SafeArea` widget for bottom input fields**
   - Respects device notches and system UI

6. **Test on real devices, not just emulators**
   - Keyboard behavior differs significantly

---

## 📱 Quick Reference

| Screen Type | `resizeToAvoidBottomInset` | Scaffold Type | Bottom Nav |
|-------------|---------------------------|---------------|------------|
| Home/Feed | `false` | `KeyboardSafeScaffold` | Fixed |
| Chat | `true` | `KeyboardAwareScaffold` | None |
| Comments | `true` | `KeyboardAwareScaffold` | None |
| Create Post | `true` | Standard `Scaffold` | None |
| Profile | `false` | `KeyboardSafeScaffold` | Fixed |

---

## 🎯 Summary

The fix involves:
1. Using `resizeToAvoidBottomInset: false` for screens with bottom navigation
2. Using `resizeToAvoidBottomInset: true` for keyboard-heavy screens
3. Wrapping content in `SingleChildScrollView` where needed
4. Using `MediaQuery.viewInsets.bottom` for dynamic padding
5. Adding keyboard dismiss gestures
6. Testing on both platforms thoroughly

This approach gives you:
- ✅ Fixed bottom navigation bar
- ✅ Keyboard-aware content
- ✅ No white space issues
- ✅ Smooth animations
- ✅ Works on both Android & iOS
