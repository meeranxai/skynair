import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/story_model.dart';
import '../../../core/providers/auth_provider.dart';

class StoryReplySheet extends ConsumerStatefulWidget {
  final StoryModel story;
  final Function(String) onReply;

  const StoryReplySheet({
    super.key,
    required this.story,
    required this.onReply,
  });

  @override
  ConsumerState<StoryReplySheet> createState() => _StoryReplySheetState();
}

class _StoryReplySheetState extends ConsumerState<StoryReplySheet>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final List<String> _quickReactions = [
    '❤️',
    '😍',
    '😂',
    '😮',
    '😢',
    '👏',
    '🔥',
    '💯',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Auto-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: SafeArea(
              bottom: false,
              child: Container(
                margin: EdgeInsets.only(bottom: keyboardHeight),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          // Story author avatar
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: widget.story.userAvatar != null
                                ? CachedNetworkImageProvider(
                                    widget.story.userAvatar!,
                                  )
                                : null,
                            backgroundColor: Colors.grey[300],
                            child: widget.story.userAvatar == null
                                ? const Icon(Icons.person, size: 20)
                                : null,
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reply to ${widget.story.userName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Only ${widget.story.userName} will see your reply',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick Reactions
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _quickReactions.length,
                        itemBuilder: (context, index) {
                          return _buildQuickReaction(_quickReactions[index]);
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Message Input
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        children: [
                          // Current user avatar
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundImage: currentUser?.photoURL != null
                                  ? CachedNetworkImageProvider(
                                      currentUser!.photoURL!,
                                    )
                                  : null,
                              backgroundColor: Colors.grey[300],
                              child: currentUser?.photoURL == null
                                  ? const Icon(Icons.person, size: 20)
                                  : null,
                            ),
                          ),

                          // Text input
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              focusNode: _focusNode,
                              decoration: const InputDecoration(
                                hintText: 'Send message...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              maxLines: 4,
                              minLines: 1,
                              onSubmitted: (value) => _sendReply(value),
                            ),
                          ),

                          // Send button
                          IconButton(
                            onPressed: () => _sendReply(_messageController.text),
                            icon: const Icon(Icons.send, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            )
          ),
        );
      },
    );
  }

  Widget _buildQuickReaction(String emoji) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => _sendReply(emoji),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
      ),
    );
  }

  void _sendReply(String message) {
    if (message.trim().isEmpty) return;

    widget.onReply(message.trim());

    // Show success animation
    _showSuccessAnimation();

    // Close the sheet after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _showSuccessAnimation() {
    // Show a brief success indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('Reply sent to ${widget.story.userName}'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
