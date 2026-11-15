import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/providers/realtime_messaging_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../../../core/models/message_model.dart';
import '../../../core/models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  MessageModel? _replyingToMessage;

  @override
  void initState() {
    super.initState();
    // Mark messages as read when entering chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(realtimeMessagingProvider.notifier)
          .markMessagesAsRead(widget.chatId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final messagingState = ref.watch(realtimeMessagingProvider);
    final isTyping = messagingState.isUserTyping(widget.chatId);
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
          ),
        ),
        title: InkWell(
          onTap: () {
            // TODO: View other user profile
          },
          child: Row(
            children: [
              Stack(
                children: [
                  ClipOval(
                    child: Container(
                      width: 40,
                      height: 40,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: widget.otherUserAvatar != null && widget.otherUserAvatar!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.otherUserAvatar!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Text(
                                  widget.otherUserName.isNotEmpty
                                      ? widget.otherUserName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                widget.otherUserName.isNotEmpty
                                    ? widget.otherUserName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.otherUserName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isTyping ? 'typing...' : 'Online',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isTyping ? theme.colorScheme.primary : Colors.green,
                        fontWeight: isTyping ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.phone_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessageBubble(message, authState.user?.uid);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load messages',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Message input
          _buildMessageInput(theme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, String? currentUserId) {
    final theme = Theme.of(context);
    final isMe = message.senderId == currentUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                ClipOval(
                  child: Container(
                    width: 24,
                    height: 24,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: widget.otherUserAvatar != null && widget.otherUserAvatar!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.otherUserAvatar!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Center(
                              child: Text(
                                widget.otherUserName.isNotEmpty
                                    ? widget.otherUserName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              widget.otherUserName.isNotEmpty
                                  ? widget.otherUserName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! > 0 && !isMe) {
                      setState(() => _replyingToMessage = message);
                    } else if (details.primaryVelocity! < 0 && isMe) {
                      setState(() => _replyingToMessage = message);
                    }
                  },
                  onLongPress: () => _showMessageOptions(message),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isMe
                          ? LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withValues(alpha: 0.8),
                              ],
                            )
                          : null,
                      color: isMe ? null : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                        bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.replyToId != null)
                          _buildReplyPreview(message.replyToId!, isMe),
                        if (message.type == MessageType.image)
                          _buildImageContent(message.imageUrl!)
                        else
                          Text(
                            message.content,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(message.timestamp),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isMe
                                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              Icon(
                                message.isRead ? Icons.done_all : Icons.done,
                                size: 14,
                                color: message.isRead
                                    ? Colors.blue[300]
                                    : theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(String replyId, bool isMe) {
    // This would ideally fetch the actual message content
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: isMe ? Colors.white : Colors.blue, width: 4)),
      ),
      child: const Text(
        'Replying to message...',
        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildImageContent(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: url,
        placeholder: (context, url) => const SizedBox(
          width: 200,
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_replyingToMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Row(
              children: [
                const Icon(Icons.reply, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Replying to...',
                        style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _replyingToMessage!.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _replyingToMessage = null),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
                onPressed: _showAttachmentMenu,
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: 5,
                    minLines: 1,
                    onChanged: (text) => ref.read(realtimeMessagingProvider.notifier).setTypingStatus(widget.chatId, text.isNotEmpty),
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _messageController.text.trim().isEmpty
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.camera_alt_outlined, color: theme.colorScheme.primary),
                          onPressed: () => _pickImage(ImageSource.camera),
                        ),
                        IconButton(
                          icon: Icon(Icons.mic_none_rounded, color: theme.colorScheme.primary),
                          onPressed: () {},
                        ),
                      ],
                    )
                  : CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        onPressed: _sendMessage,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty && _replyingToMessage == null) return;

    ref.read(realtimeMessagingProvider.notifier).sendMessage(
          chatId: widget.chatId,
          receiverId: widget.otherUserId,
          content: content,
          replyToId: _replyingToMessage?.id,
        );

    _messageController.clear();
    setState(() => _replyingToMessage = null);

    // Scroll to bottom
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

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      // In a real app, you would upload to storage first
      // For now, we'll simulate it or use a local path if supported by service
      // ref.read(realtimeMessagingProvider.notifier).sendImageMessage(...)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image selection ready (Upload logic pending)')),
      );
    }
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Document'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Location'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(MessageModel message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.reply),
            title: const Text('Reply'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _replyingToMessage = message);
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy Text'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              ref.read(realtimeMessagingProvider.notifier).deleteMessage(widget.chatId, message.id);
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
