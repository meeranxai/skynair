import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

import '../../../core/models/post_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/posts_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_providers.dart';
import '../widgets/image_editor.dart';
import '../../../core/services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';


class CreatePostPage extends ConsumerStatefulWidget {
  final PostModel? postToEdit;
  final String? postType; // 'media' or 'article'

  const CreatePostPage({super.key, this.postToEdit, this.postType});

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

// Twitter-style keyboard handler
class _KeyboardAwareScroll {
  static void scrollToBottom(ScrollController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.hasClients) {
        controller.animateTo(
          controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }
}

class _CreatePostPageState extends ConsumerState<CreatePostPage>
    with TickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _scrollController = ScrollController();

  String _selectedCategory = 'General';
  File? _selectedImage;
  XFile? _selectedImageFile;
  String? _existingImageUrl;
  bool _isLoading = false;
  bool _isScrollingDown = false;
  late String _postType; // 'media' or 'article'

  // Character limits
  static const int _maxMediaCharacters = 800;
  static const int _minArticleCharacters = 300;
  static const int _maxArticleCharacters = 1500;

  int _titleCharacters = 0;
  int _descriptionCharacters = 0;
  bool _isTitleOverLimit = false;
  bool _isDescriptionOverLimit = false;
  bool _isDescriptionUnderLimit = false; // Only for articles
  
  // Mention state
  List<UserModel> _mentionResults = [];
  bool _showMentionSuggestions = false;
  String _mentionQuery = '';
  int _mentionStartIndex = -1;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'General',
    'Technology',
    'Art',
    'Music',
    'Food',
    'Travel',
    'Sports',
    'Fashion',
    'Photography',
    'Business',
  ];

  @override
  void initState() {
    super.initState();

    _postType = 'media'; // Always use media post (Articles eliminated)

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Initialize with existing post data if available
    if (widget.postToEdit != null) {
      _titleController.text = widget.postToEdit!.title;
      _descriptionController.text = widget.postToEdit!.description;
      _selectedCategory = widget.postToEdit!.category;
      _existingImageUrl = widget.postToEdit!.image;
      _updateTextStats();
    }

    // Listen to text changes for character counting
    _titleController.addListener(_updateTextStats);
    _descriptionController.addListener(_updateTextStats);

    // Listen to focus changes for auto-scrolling (Twitter-style)
    _titleFocusNode.addListener(_handleTitleFocus);
    _descriptionFocusNode.addListener(_handleDescriptionFocus);

    // Listen to scroll for hiding bottom bar (Twitter-style)
    _scrollController.addListener(_handleScroll);

    _fadeController.forward();
    _slideController.forward();
  }

  void _handleScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (!_isScrollingDown) {
        setState(() {
          _isScrollingDown = true;
        });
      }
    }
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      setState(() {
        _isScrollingDown = false;
      });
    }
  }

  void _handleTitleFocus() {
    setState(() {}); // Trigger rebuild for focus animation
    if (_titleFocusNode.hasFocus) {
      _KeyboardAwareScroll.scrollToBottom(_scrollController);
    }
  }

  void _handleDescriptionFocus() {
    setState(() {}); // Trigger rebuild for focus animation
    if (_descriptionFocusNode.hasFocus) {
      _KeyboardAwareScroll.scrollToBottom(_scrollController);
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_updateTextStats);
    _descriptionController.removeListener(_updateTextStats);
    _titleFocusNode.removeListener(_handleTitleFocus);
    _descriptionFocusNode.removeListener(_handleDescriptionFocus);
    _scrollController.removeListener(_handleScroll);

    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _updateTextStats() {
    final titleText = _titleController.text;
    final descriptionText = _descriptionController.text;

    setState(() {
      _titleCharacters = titleText.length;
      _descriptionCharacters = descriptionText.length;

      // Title limit (e.g., 100 chars)
      _isTitleOverLimit = _titleCharacters > 100;

      if (_postType == 'article') {
        _isDescriptionOverLimit = _descriptionCharacters > _maxArticleCharacters;
        _isDescriptionUnderLimit = _descriptionCharacters < _minArticleCharacters;
      } else {
        _isDescriptionOverLimit = _descriptionCharacters > _maxMediaCharacters;
        _isDescriptionUnderLimit = false;
      }
    });

    _checkMentions(descriptionText);
  }

  void _checkMentions(String text) {
    final selection = _descriptionController.selection;
    if (selection.baseOffset < 0) return;

    final cursorPosition = selection.baseOffset;
    final textBeforeCursor = text.substring(0, cursorPosition);
    
    final lastAt = textBeforeCursor.lastIndexOf('@');
    if (lastAt != -1) {
      final query = textBeforeCursor.substring(lastAt + 1);
      // Ensure no spaces between @ and cursor
      if (!query.contains(' ') && !query.contains('\n')) {
        _mentionStartIndex = lastAt;
        _fetchMentions(query);
        return;
      }
    }
    
    if (_showMentionSuggestions) {
      setState(() {
        _showMentionSuggestions = false;
        _mentionResults = [];
      });
    }
  }

  Future<void> _fetchMentions(String query) async {
    if (query.length < 1) {
      setState(() {
        _showMentionSuggestions = false;
        _mentionResults = [];
      });
      return;
    }

    try {
      final users = await ref.read(userSearchProvider(query).future);
      if (mounted) {
        setState(() {
          _mentionResults = users;
          _showMentionSuggestions = users.isNotEmpty;
          _mentionQuery = query;
        });
      }
    } catch (e) {
      // Error searching users
    }
  }

  void _insertMention(UserModel user) {
    final text = _descriptionController.text;
    final selection = _descriptionController.selection;
    final cursorPosition = selection.baseOffset;
    
    final beforeMention = text.substring(0, _mentionStartIndex);
    final afterMention = text.substring(cursorPosition);
    
    final newText = '$beforeMention@${user.username} $afterMention';
    
    setState(() {
      _descriptionController.text = newText;
      _descriptionController.selection = TextSelection.collapsed(
        offset: beforeMention.length + user.username.length + 2,
      );
      _showMentionSuggestions = false;
      _mentionResults = [];
    });
  }

  void _dismissKeyboard() {
    _titleFocusNode.unfocus();
    _descriptionFocusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  Future<XFile?> _cropImage(XFile imageFile) async {
    try {
      if (kIsWeb) return imageFile; // Cropping not supported on web yet

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Theme.of(context).colorScheme.surface,
            toolbarWidgetColor: Theme.of(context).colorScheme.onSurface,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
        ],
      );

      return croppedFile != null ? XFile(croppedFile.path) : null;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return imageFile; // Return original if crop fails
    }
  }

  Future<void> _processImage(XFile image) async {
    // 1. Crop
    final croppedImage = await _cropImage(image);
    if (croppedImage == null) return; // User cancelled crop

    // 2. Edit (Filters/Adjustments)
    if (_postType == 'media' && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageEditor(
            imageFile: croppedImage,
            onSave: (editedImage) {
              setState(() {
                _selectedImageFile = editedImage;
                if (!kIsWeb) {
                  _selectedImage = File(editedImage.path);
                }
              });
            },
          ),
        ),
      );
    } else {
      // For articles, just set the cropped image
      setState(() {
        _selectedImageFile = croppedImage;
        if (!kIsWeb) {
          _selectedImage = File(croppedImage.path);
        }
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final hasPermission = await PermissionService.requestGalleryPermission(context);
      if (!hasPermission) return;

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );


      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final hasPermission = await PermissionService.checkAndRequest(Permission.camera, context);
      if (!hasPermission) return;

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );


      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take photo: $e');
    }
  }

  bool get _isOverLimit => _isTitleOverLimit || _isDescriptionOverLimit;

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageFile = null;
      _existingImageUrl = null;
    });
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Add Photo',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildImageSourceOption(
                            icon: Icons.photo_library_outlined,
                            label: 'Gallery',
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildImageSourceOption(
                            icon: Icons.camera_alt_outlined,
                            label: 'Camera',
                            onTap: () {
                              Navigator.pop(context);
                              _takePhoto();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPost({bool isDraft = false}) async {
    if (_postType == 'article' && _titleController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a title');
      _titleFocusNode.requestFocus();
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a description');
      _descriptionFocusNode.requestFocus();
      return;
    }

    /* 
    // Image is now optional for media posts
    if (_postType == 'media' &&
        _selectedImage == null &&
        _existingImageUrl == null) {
      _showErrorSnackBar('Media post requires an image');
      return;
    }
    */

    if (_isTitleOverLimit) {
      _showErrorSnackBar('Title exceeds character limit (100)');
      _titleFocusNode.requestFocus();
      return;
    }

    if (_isDescriptionOverLimit) {
      _showErrorSnackBar('Description exceeds character limit');
      _descriptionFocusNode.requestFocus();
      return;
    }

    // Minimum length check for articles (not for drafts)
    if (_postType == 'article' && !isDraft && _isDescriptionUnderLimit) {
      _showErrorSnackBar(
        'Articles must be at least $_minArticleCharacters characters long. Currently: $_descriptionCharacters',
      );
      _descriptionFocusNode.requestFocus();
      return;
    }

    // Dismiss keyboard before submitting
    _dismissKeyboard();

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.postToEdit != null) {
        await ref
            .read(postsProvider.notifier)
            .updatePost(
              postId: widget.postToEdit!.id,
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              category: _selectedCategory,
              imageFile: _selectedImageFile,
              isDraft: isDraft,
            );

        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post updated successfully!')),
          );
        }
      } else {
        await ref
            .read(postsProvider.notifier)
            .createPost(
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              category: _selectedCategory,
              imageFile: _selectedImageFile,
              postType: _postType,
              isDraft: isDraft,
            );

        if (mounted) {
          // Navigate based on post type
          if (_postType == 'article') {
            context.go('/articles');
          } else {
            context.go('/home');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${_postType == 'article' ? (isDraft ? 'Draft saved' : 'Article published') : 'Post created'} successfully!',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar(
        'Failed to ${widget.postToEdit != null ? 'update' : (isDraft ? 'save draft' : 'publish')} post: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: _isLoading
              ? null
              : () {
                  _dismissKeyboard();
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    if (_postType == 'article') {
                      context.go('/articles');
                    } else {
                      context.go('/home');
                    }
                  }
                },
          icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
        ),
        title: Text(
          widget.postToEdit != null
              ? 'Edit Post'
              : _postType == 'article'
              ? 'Write Article'
              : 'Create post',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_postType == 'article' && widget.postToEdit == null) ...[
                        TextButton(
                          onPressed: _isOverLimit ? null : () => _submitPost(isDraft: true),
                          child: Text(
                            'Save Draft',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      TextButton(
                        onPressed: _isOverLimit ? null : () => _submitPost(isDraft: false),
                        style: TextButton.styleFrom(
                          backgroundColor: _isOverLimit
                              ? theme.colorScheme.surfaceContainerHighest
                              : theme.colorScheme.primary,
                          foregroundColor: _isOverLimit
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          widget.postToEdit != null ? 'Update Post' : 'POST',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info Header
                    _buildUserHeader(currentUser, theme),

                    const SizedBox(height: 24),

                    // Image Section (On top like requested)
                    _buildImageSection(theme),

                    const SizedBox(height: 24),
                    
                    // Description Input
                    _buildDescriptionInput(theme),

                    const SizedBox(height: 8),

                    // Character/Word Counter
                    _buildTextCounter(theme),

                    const SizedBox(height: 40),

                    // Extra padding for keyboard
                    SizedBox(
                      height: MediaQuery.of(context).viewInsets.bottom > 0
                          ? 100
                          : 0,
                    ),
                  ],
                ),
              ),
              // Mention Suggestions
              if (_showMentionSuggestions && _mentionResults.isNotEmpty)
                _buildMentionSuggestions(theme),

              // Bottom action bar (Twitter-style, hides on scroll)
              if (!_isScrollingDown && _postType == 'media')
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      color: theme.colorScheme.surface,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _showImageSourceDialog,
                          icon: Icon(
                            Icons.image_outlined,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        // Character counter with progress
                        if (_descriptionCharacters > 259)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: _descriptionCharacters / _maxMediaCharacters,
                                    backgroundColor: Colors.grey.withValues(
                                      alpha: 0.3,
                                    ),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _isDescriptionOverLimit
                                          ? Colors.red
                                          : theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    '${_maxMediaCharacters - _descriptionCharacters}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _isDescriptionOverLimit
                                          ? Colors.red
                                          : theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMentionSuggestions(ThemeData theme) {
    return Positioned(
      bottom: MediaQuery.of(context).viewInsets.bottom +
          (!_isScrollingDown && _postType == 'media' ? 60 : 0),
      left: 0,
      right: 0,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 220),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Suggestions',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: _mentionResults.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  indent: 72,
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
                itemBuilder: (context, index) {
                  final user = _mentionResults[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundImage: user.photoURL != null
                          ? CachedNetworkImageProvider(user.photoURL!)
                          : null,
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: user.photoURL == null
                          ? Text(
                              user.displayName.isNotEmpty
                                  ? user.displayName[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      user.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '@${user.username}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    onTap: () => _insertMention(user),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(dynamic currentUser, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: currentUser?.photoURL != null
                ? CachedNetworkImageProvider(currentUser!.photoURL!)
                : null,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: currentUser?.photoURL == null
                ? Text(
                    currentUser?.displayName?.isNotEmpty == true
                        ? currentUser!.displayName![0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentUser?.displayName?.isNotEmpty == true
                    ? currentUser!.displayName!
                    : 'User',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.public,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Public',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleInput(ThemeData theme) {
    return const SizedBox.shrink();
  }

  Widget _buildDescriptionInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _descriptionController,
        focusNode: _descriptionFocusNode,
        decoration: InputDecoration(
          hintText: "What's on your mind?",
          hintStyle: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            fontSize: 18,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        textAlignVertical: TextAlignVertical.top,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontSize: 16,
          height: 1.6,
        ),
        maxLines: null,
        minLines: 6,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (value) => _updateTextStats(),
      ),
    );
  }

  Widget _buildCategorySelection(ThemeData theme) {
    return const SizedBox.shrink();
  }

  Widget _buildImageSection(ThemeData theme) {
    if (_selectedImage == null && _existingImageUrl == null) {
      return GestureDetector(
        onTap: _showImageSourceDialog,
        child: Container(
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              width: 1.5,
              style: BorderStyle.solid,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add Photos or Videos',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Share your moments with the world',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Rest of image section (preview)
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (_selectedImage != null)
            Image.file(
              _selectedImage!,
              width: double.infinity,
              height: 350,
              fit: BoxFit.cover,
            )
          else if (_existingImageUrl != null)
            CachedNetworkImage(
              imageUrl: _existingImageUrl!,
              width: double.infinity,
              height: 350,
              fit: BoxFit.cover,
            ),
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: _removeImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageAction({
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withValues(alpha: 0.8) : Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildTextCounter(ThemeData theme) {
    final max = _maxMediaCharacters;
    final isError = _isDescriptionOverLimit;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$_descriptionCharacters / $max',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isError
                  ? Colors.red
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: isError ? FontWeight.w900 : FontWeight.normal,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}



