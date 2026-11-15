import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/story_model.dart';
import '../providers/story_provider.dart';
import '../widgets/story_progress_indicator.dart';
import '../widgets/story_reply_sheet.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/providers/auth_provider.dart';
import 'package:share_plus/share_plus.dart';

class StoryViewerPage extends ConsumerStatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;

  const StoryViewerPage({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends ConsumerState<StoryViewerPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  late AnimationController _likeAnimController;

  int _currentStoryIndex = 0;
  int _currentItemIndex = 0;
  bool _isPaused = false;

  // Local like state for instant feedback
  final Map<String, bool> _localLikeState = {};
  final Map<String, int> _localLikeCount = {};

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _progressController = AnimationController(vsync: this);
    _likeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 1.0,
      upperBound: 1.5,
      value: 1.0,
    );

    // Initialize local like state from stories
    final currentUser = ref.read(authProvider).user;
    for (final story in widget.stories) {
      _localLikeState[story.id] = currentUser != null && story.isLikedBy(currentUser.uid);
      _localLikeCount[story.id] = story.likesCount;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startStoryTimer();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _likeAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Dismissible(
        key: const Key('story_viewer_dismiss'),
        direction: DismissDirection.down,
        onDismissed: (_) => Navigator.pop(context),
        child: GestureDetector(
          onLongPressStart: (_) => _pauseStory(),
          onLongPressEnd: (_) => _resumeStory(),
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity! > 300) {
              Navigator.pop(context);
            }
          },
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.stories.length,
            onPageChanged: _onStoryChanged,
            physics:
                const ClampingScrollPhysics(), // Prevent overscroll for better feel
            itemBuilder: (context, index) {
              final story = widget.stories[index];
              return _buildStoryPage(story, index == _currentStoryIndex);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStoryPage(StoryModel story, bool isActive) {
    final currentItem =
        story.items.isNotEmpty && _currentItemIndex < story.items.length
        ? story.items[_currentItemIndex]
        : null;

    return Stack(
      children: [
        // Story Content
        Positioned.fill(child: _buildStoryContent(currentItem)),

        // Gradient Overlays (Top and Bottom)
        Positioned.fill(
          child: Column(
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tap Areas for Navigation (Invisible) — placed BEFORE header/footer
        // so that header/footer buttons render on top and remain clickable
        Positioned(
          top: 120,
          bottom: 100,
          left: 0,
          right: 0,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _previousItem,
                  child: Container(),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _nextItem,
                  child: Container(),
                ),
              ),
            ],
          ),
        ),

        // Progress Indicators
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, _) {
                  return StoryProgressIndicator(
                    itemCount: story.items.length,
                    currentIndex: _currentItemIndex,
                    progress: isActive ? _progressController.value : 0.0,
                  );
                },
              ),
            ),
          ),
        ),

        // Story Header — rendered on top so buttons are tappable
        Positioned(
          top: 24,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildStoryHeader(story),
            ),
          ),
        ),

        // Story Footer — rendered on top so buttons are tappable
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
                top: 8,
              ),
              child: _buildStoryFooter(story),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoryContent(StoryItem? item) {
    if (item == null) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.white, size: 64),
        ),
      );
    }

    switch (item.type) {
      case StoryType.image:
        return _buildImageContent(item);
      case StoryType.video:
        return _buildVideoContent(item);
      case StoryType.text:
        return _buildTextContent(item);
      default:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.deepPurple.shade900, Colors.indigo.shade900],
            ),
          ),
        );
    }
  }

  Widget _buildImageContent(StoryItem item) {
    return Stack(
      children: [
        // Background - always show something to prevent black screen
        Positioned.fill(
          child: item.background != null
              ? _buildBackground(item.background!)
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.deepPurple.shade900,
                        Colors.indigo.shade900,
                      ],
                    ),
                  ),
                ),
        ),

        // Image
        if (item.mediaUrl != null && item.mediaUrl!.isNotEmpty)
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: item.mediaUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[900],
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[900],
                child: const Center(
                  child: Icon(Icons.error, color: Colors.white),
                ),
              ),
            ),
          ),

        // Stickers
        ..._buildStickers(item.stickers),
      ],
    );
  }

  Widget _buildVideoContent(StoryItem item) {
    // In a real app, you'd use a video player here
    return Container(
      color: Colors.grey[900],
      child: Stack(
        children: [
          const Center(
            child: Icon(
              Icons.play_circle_outline,
              color: Colors.white,
              size: 64,
            ),
          ),
          ..._buildStickers(item.stickers),
        ],
      ),
    );
  }

  Widget _buildTextContent(StoryItem item) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Background - always show gradient fallback
          Positioned.fill(
            child: item.background != null
                ? _buildBackground(item.background!)
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.deepPurple.shade900,
                          Colors.indigo.shade900,
                        ],
                      ),
                    ),
                  ),
          ),

          // Text
          if (item.text != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  item.text!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Stickers
          ..._buildStickers(item.stickers),
        ],
      ),
    );
  }

  Widget _buildBackground(StoryBackground background) {
    switch (background.type) {
      case BackgroundType.color:
        return Container(
          color: Color(int.parse(background.color ?? '0xFF000000')),
        );
      case BackgroundType.gradient:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  background.gradientColors
                      ?.map((color) => Color(int.parse(color)))
                      .toList() ??
                  [Colors.purple, Colors.blue],
            ),
          ),
        );
      case BackgroundType.image:
        return background.imageUrl != null
            ? CachedNetworkImage(
                imageUrl: background.imageUrl!,
                fit: BoxFit.cover,
              )
            : Container(color: Colors.black);
      default:
        return Container(color: Colors.black);
    }
  }

  List<Widget> _buildStickers(List<StorySticker> stickers) {
    return stickers.map((sticker) {
      return Positioned(
        left: sticker.position.dx,
        top: sticker.position.dy,
        child: Transform.rotate(
          angle: sticker.rotation,
          child: Transform.scale(
            scale: sticker.scale,
            child: _buildStickerWidget(sticker),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildStickerWidget(StorySticker sticker) {
    switch (sticker.type) {
      case StickerType.text:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            sticker.data['text'] ?? '',
            style: TextStyle(
              color: Color(sticker.data['color'] ?? 0xFFFFFFFF),
              fontSize: sticker.data['fontSize']?.toDouble() ?? 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case StickerType.emoji:
        return Text(
          sticker.data['emoji'] ?? '😀',
          style: TextStyle(
            fontSize: sticker.data['fontSize']?.toDouble() ?? 32,
          ),
        );
      case StickerType.mention:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '@${sticker.data['username'] ?? ''}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStoryHeader(StoryModel story) {
    return Row(
      children: [
        // User Avatar
        CircleAvatar(
          radius: 16,
          backgroundImage: story.userAvatar != null
              ? CachedNetworkImageProvider(story.userAvatar!)
              : null,
          backgroundColor: Colors.grey[600],
          child: story.userAvatar == null
              ? const Icon(Icons.person, color: Colors.white, size: 20)
              : null,
        ),

        const SizedBox(width: 8),

        // User Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                story.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                _formatTimestamp(story.createdAt),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // More Options
        IconButton(
          onPressed: () => _showStoryOptions(story),
          icon: const Icon(Icons.more_vert, color: Colors.white),
        ),

        // Close Button
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildStoryFooter(StoryModel story) {
    final currentUser = ref.read(authProvider).user;
    final isOwnStory = story.userId == currentUser?.uid;

    if (isOwnStory) {
      return Row(
        children: [
          GestureDetector(
            onTap: () {
              // Consume tap to prevent skipping, potentially show viewers list
              _showViewersList(story);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.visibility, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${story.viewCount} views',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
          const Spacer(),
        ],
      );
    } else {
      final isLiked = _localLikeState[story.id] ?? false;
      final likeCount = _localLikeCount[story.id] ?? story.likesCount;

      return Row(
        children: [
          const Spacer(),
          // Like Button with Scale Animation
          ScaleTransition(
            scale: _likeAnimController,
            child: GestureDetector(
              onTap: () => _likeStory(story),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.redAccent : Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          if (likeCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '$likeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      );
    }
  }

  void _handleTap(TapDownDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapPosition = details.globalPosition.dx;

    if (tapPosition < screenWidth / 2) {
      // Tap on left side - previous
      _previousItem();
    } else {
      // Tap on right side - next
      _nextItem();
    }
  }

  void _previousItem() {
    if (_currentItemIndex > 0) {
      setState(() {
        _currentItemIndex--;
      });
      _startStoryTimer();
    } else if (_currentStoryIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextItem() {
    final currentStory = widget.stories[_currentStoryIndex];

    if (_currentItemIndex < currentStory.items.length - 1) {
      setState(() {
        _currentItemIndex++;
      });
      _startStoryTimer();
    } else if (_currentStoryIndex < widget.stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // End of stories
      Navigator.pop(context);
    }
  }

  void _onStoryChanged(int index) {
    setState(() {
      _currentStoryIndex = index;
      _currentItemIndex = 0;
    });
    _markStoryAsViewed();
    _startStoryTimer();
  }

  void _startStoryTimer() {
    _progressController.reset();

    final currentStory = widget.stories[_currentStoryIndex];
    final currentItem =
        currentStory.items.isNotEmpty &&
            _currentItemIndex < currentStory.items.length
        ? currentStory.items[_currentItemIndex]
        : null;

    if (currentItem != null && !_isPaused) {
      _progressController.duration = currentItem.duration;
      _progressController.forward().then((_) {
        if (!_isPaused) {
          _nextItem();
        }
      });
    }
  }

  void _pauseStory() {
    setState(() {
      _isPaused = true;
    });
    _progressController.stop();
  }

  void _resumeStory() {
    setState(() {
      _isPaused = false;
    });
    _progressController.forward();
  }

  void _markStoryAsViewed() {
    final currentStory = widget.stories[_currentStoryIndex];
    ref.read(storyProvider.notifier).markStoryAsViewed(currentStory.id);
  }

  void _showStoryOptions(StoryModel story) {
    _pauseStory();
    final currentUser = ref.read(authProvider).user;
    final isOwnStory = story.userId == currentUser?.uid;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (isOwnStory) ...[
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('Archive Story'),
                onTap: () {
                  Navigator.pop(context);
                  _archiveStory(story);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Story', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteStory(story);
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.report),
                title: const Text('Report Story'),
                onTap: () {
                  Navigator.pop(context);
                  _reportStory(story);
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    ).then((_) {
      if (mounted) _resumeStory();
    });
  }

  void _showReplySheet(StoryModel story) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StoryReplySheet(
        story: story,
        onReply: (message) {
          ref
              .read(storyProvider.notifier)
              .replyToStory(storyId: story.id, message: message);
        },
      ),
    );
  }

  void _showStoryAnalytics(StoryModel story) {
    // Navigate to analytics page
    // This would show detailed analytics for the story
  }

  void _likeStory(StoryModel story) {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;
    
    final wasLiked = _localLikeState[story.id] ?? false;
    setState(() {
      _localLikeState[story.id] = !wasLiked;
      _localLikeCount[story.id] = (_localLikeCount[story.id] ?? story.likesCount) + (wasLiked ? -1 : 1);
    });

    // Play bounce animation - fast and punchy
    _likeAnimController.forward().then((_) {
      _likeAnimController.reverse();
    });

    // Sync with backend
    ref.read(storyProvider.notifier).toggleLike(story.id);
  }

  void _shareStory(StoryModel story) async {
    // Pause story while sharing
    _pauseStory();
    
    final shareText = 'Check out this story by ${story.userName} on Skynaire!';
    await Share.share(shareText);
    
    // Resume after sharing dialog closes (approximate, as we can't detect closure exactly across all platforms)
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _resumeStory();
    });
  }

  void _archiveStory(StoryModel story) {
    final navContext = context; // Capture viewer context before dialog
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archive Story'),
        content: const Text(
          'Are you sure you want to archive this story? It will be hidden from everyone else and saved in your archive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              ref.read(storyProvider.notifier).toggleArchive(story.id);
              Navigator.of(navContext).pop(); // Close story viewer
              ScaffoldMessenger.of(navContext).showSnackBar(
                const SnackBar(
                  content: Text('Story archived successfully!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _deleteStory(StoryModel story) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Story'),
        content: const Text('Are you sure you want to delete this story?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(storyProvider.notifier).deleteStory(story.id);
              Navigator.pop(context); // Close story viewer
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addToHighlights(StoryModel story) {
    showDialog(
      context: context,
      builder: (context) {
        String highlightTitle = '';
        return AlertDialog(
          title: const Text('Add to Highlights'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Highlight Title',
              hintText: 'Enter a title for this highlight',
            ),
            onChanged: (value) => highlightTitle = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (highlightTitle.isNotEmpty) {
                  ref
                      .read(storyProvider.notifier)
                      .addToHighlights(
                        storyId: story.id,
                        highlightTitle: highlightTitle,
                      );
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _reportStory(StoryModel story) {
    showDialog(
      context: context,
      builder: (context) {
        String reason = 'Inappropriate content';
        return AlertDialog(
          title: const Text('Report Story'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Why are you reporting this story?'),
              const SizedBox(height: 16),
            DropdownButtonFormField<String>(
                // value: reason,
                initialValue: reason,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                ),
                items: [
                  'Inappropriate content',
                  'Spam',
                  'Harassment',
                  'False information',
                  'Other',
                ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) => reason = val ?? reason,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                final user = ref.read(authProvider).user;
                if (user != null) {
                  FirestoreService.submitReport(
                    reporterId: user.uid,
                    targetId: story.id,
                    targetType: 'story',
                    reason: reason,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Story reported successfully')),
                  );
                }
              },
              child: const Text('Report'),
            ),
          ],
        );
      },
    );
  }

  void _showViewersList(StoryModel story) {
    _pauseStory();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Story Viewers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.visibility, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    '${story.viewCount} views',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ).then((_) => _resumeStory());
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}
