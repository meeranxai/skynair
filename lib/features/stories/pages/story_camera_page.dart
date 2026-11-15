import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../models/story_model.dart';
import '../providers/story_provider.dart';
import '../services/story_service.dart';
import '../widgets/story_text_editor.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';


class StoryCameraPage extends ConsumerStatefulWidget {
  const StoryCameraPage({super.key});

  @override
  ConsumerState<StoryCameraPage> createState() => _StoryCameraPageState();
}

class _StoryCameraPageState extends ConsumerState<StoryCameraPage>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  bool _isFlashOn = false;
  bool _isFrontCamera = false;
  XFile? _capturedMedia;
  StoryType? _mediaType;

  late AnimationController _recordingAnimationController;
  late Animation<double> _recordingScaleAnimation;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _recordingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _recordingScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _recordingAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _recordingAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final hasCamera = await PermissionService.checkAndRequest(Permission.camera, context);
      if (!hasCamera) return;

      _cameras = await availableCameras();

      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![_isFrontCamera ? 1 : 0],
          ResolutionPreset.high,
          enableAudio: false, // Disabled audio for image-only stories
        );
        await _cameraController!.initialize();
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final storyState = ref.watch(storyProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_cameraController?.value.isInitialized == true)
            Positioned.fill(child: CameraPreview(_cameraController!))
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Top Controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // Close Button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),

                    const Spacer(),

                    // Flash Toggle
                    IconButton(
                      onPressed: _toggleFlash,
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                      ),
                    ),

                    // Camera Switch
                    IconButton(
                      onPressed: _switchCamera,
                      icon: const Icon(
                        Icons.flip_camera_ios,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Recording Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Gallery Button
                        IconButton(
                          onPressed: _pickFromGallery,
                          icon: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.photo_library,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // Capture Button
                        GestureDetector(
                          onTap: _takePhoto,
                          onLongPressStart: (_) => _startVideoRecording(),
                          onLongPressEnd: (_) => _stopVideoRecording(),
                          child: AnimatedBuilder(
                            animation: _recordingScaleAnimation,
                            builder: (context, child) => Transform.scale(
                              scale: _recordingScaleAnimation.value,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isRecording
                                      ? Colors.red
                                      : Colors.white,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                ),
                                child: _isRecording
                                    ? const Icon(
                                        Icons.stop,
                                        color: Colors.white,
                                        size: 30,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),

                        // Text Button
                        IconButton(
                          onPressed: _openTextEditor,
                          icon: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.text_fields,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Instructions
                    Text(
                      _isRecording
                          ? 'Recording... Release to stop'
                          : 'Tap for photo, hold for video',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Upload Progress
          if (storyState.isUploading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: storyState.uploadProgress,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Uploading story... ${(storyState.uploadProgress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    if (_cameraController?.value.isInitialized != true) return;

    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        _capturedMedia = photo;
        _mediaType = StoryType.image;
      });
      _showPreview();
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  Future<void> _startVideoRecording() async {
    if (_cameraController?.value.isInitialized != true || _isRecording) return;

    try {
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
      _recordingAnimationController.forward();
    } catch (e) {
      debugPrint('Error starting video recording: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    if (!_isRecording) return;

    try {
      final XFile video = await _cameraController!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _capturedMedia = video;
        _mediaType = StoryType.video;
      });
      _recordingAnimationController.reverse();
      _showPreview();
    } catch (e) {
      debugPrint('Error stopping video recording: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final hasPhotos = await PermissionService.requestGalleryPermission(context);
      if (!hasPhotos) return;

      // Use pickImage instead of pickMedia to avoid video/audio permissions

      final XFile? media = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (media != null) {
        // Show crop option for images
        final shouldCrop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Edit Photo'),
            content: const Text('Do you want to crop/resize the photo?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Use Original'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Crop'),
              ),
            ],
          ),
        );

        if (shouldCrop == true && mounted) {
          // Crop the image
          final croppedFile = await ImageCropper().cropImage(
            sourcePath: media.path,
            aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16),
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Crop Photo',
                toolbarColor: Colors.black,
                toolbarWidgetColor: Colors.white,
                backgroundColor: Colors.black,
                activeControlsWidgetColor: Colors.white,
                initAspectRatio: CropAspectRatioPreset.ratio16x9,
                lockAspectRatio: false,
                aspectRatioPresets: [
                  CropAspectRatioPreset.original,
                  CropAspectRatioPreset.square,
                  CropAspectRatioPreset.ratio4x3,
                  CropAspectRatioPreset.ratio16x9,
                ],
              ),
              IOSUiSettings(
                title: 'Crop Photo',
                aspectRatioPresets: [
                  CropAspectRatioPreset.original,
                  CropAspectRatioPreset.square,
                  CropAspectRatioPreset.ratio4x3,
                  CropAspectRatioPreset.ratio16x9,
                ],
              ),
            ],
          );

          if (croppedFile != null) {
            setState(() {
              _capturedMedia = XFile(croppedFile.path);
              _mediaType = StoryType.image;
            });
            _showPreview();
          }
        } else if (shouldCrop == false) {
          // Use original image
          setState(() {
            _capturedMedia = media;
            _mediaType = StoryType.image;
          });
          _showPreview();
        }
      }
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
    }
  }

  void _openTextEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StoryTextEditor(
        onTextCreated: (text, background) {
          _createTextStory(text, background);
        },
      ),
    );
  }

  void _createTextStory(String text, StoryBackground background) {
    // Create text-only story
    final storyItem = StoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: StoryType.text,
      text: text,
      background: background,
      createdAt: DateTime.now(),
    );

    _publishStory([storyItem]);
  }

  void _showPreview() {
    if (_capturedMedia == null || _mediaType == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryPreviewPage(
          mediaFile: _capturedMedia!,
          mediaType: _mediaType!,
          onPublish: (storyItem) async {
            // Already uploaded in PreviewPage, just publish to Firestore
            _publishStory([storyItem]);
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _publishStory(List<StoryItem> items) async {
    try {
      await ref.read(storyProvider.notifier).createStory(items: items);
      if (mounted) {
        // Pop twice to go back to home
        Navigator.pop(context); // Close camera page

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story published successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Refresh stories after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ref.read(storyProvider.notifier).refresh();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish story: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController?.value.isInitialized != true) return;

    try {
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.off : FlashMode.torch,
      );
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    try {
      await _cameraController?.dispose();
      setState(() {
        _isFrontCamera = !_isFrontCamera;
      });

      _cameraController = CameraController(
        _cameras![_isFrontCamera ? 1 : 0],
        ResolutionPreset.high,
        enableAudio: false, // Disabled audio for image-only stories
      );

      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }
}

// Story Preview Page
class StoryPreviewPage extends ConsumerStatefulWidget {
  final XFile mediaFile;
  final StoryType mediaType;
  final Function(StoryItem) onPublish;

  const StoryPreviewPage({
    super.key,
    required this.mediaFile,
    required this.mediaType,
    required this.onPublish,
  });

  @override
  ConsumerState<StoryPreviewPage> createState() => _StoryPreviewPageState();
}

class _StoryPreviewPageState extends ConsumerState<StoryPreviewPage> {
  final List<StorySticker> _stickers = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _showControls = true;
  final TransformationController _transformationController =
      TransformationController();
  String? _activeStickerId;
  bool _isDraggingSticker = false;
  double _baseScale = 1.0;
  double _baseRotation = 0.0;
  Offset _basePosition = Offset.zero;

  File _getFileFromPath(String path) {
    return File(path);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          // Toggle controls visibility
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          children: [
            // Media Preview with InteractiveViewer for zoom/pan
            Positioned.fill(
              child: widget.mediaType == StoryType.image
                  ? InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Center(
                        child: kIsWeb
                            ? Image.network(
                                widget.mediaFile.path,
                                fit: BoxFit.contain,
                              )
                            : Image(
                                image: ResizeImage(
                                  FileImage(
                                    // Use a helper or cast safely
                                    // But since we are inside kIsWeb check, this is safe for mobile
                                    _getFileFromPath(widget.mediaFile.path),
                                  ),
                                  width: 1080,
                                ),
                                fit: BoxFit.contain,
                              ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    ),
            ),

            // Stickers Overlay
            ..._stickers.map(
              (sticker) => Positioned(
                left: sticker.position.dx,
                top: sticker.position.dy,
                child: GestureDetector(
                  onScaleStart: (details) {
                    setState(() {
                      _activeStickerId = sticker.id;
                      _isDraggingSticker = true;
                      _baseScale = sticker.scale;
                      _baseRotation = sticker.rotation;
                      _basePosition = sticker.position;
                    });
                  },
                  onScaleUpdate: (details) {
                    setState(() {
                      final index = _stickers.indexWhere((s) => s.id == sticker.id);
                      if (index != -1) {
                        // Handle rotation and scale
                        double newRotation = _baseRotation + details.rotation;
                        double newScale = (_baseScale * details.scale).clamp(0.5, 5.0);
                        
                        // Handle translation
                        // The focalPointDelta gives us the movement since the start of the gesture
                        Offset newPosition = _basePosition + details.focalPointDelta;

                        _stickers[index] = StorySticker(
                          id: sticker.id,
                          type: sticker.type,
                          position: newPosition,
                          rotation: newRotation,
                          scale: newScale,
                          data: sticker.data,
                        );
                      }
                    });
                  },
                  onScaleEnd: (details) {
                    setState(() {
                      _isDraggingSticker = false;
                      // Check if over delete zone
                      final index = _stickers.indexWhere((s) => s.id == sticker.id);
                      if (index != -1) {
                        final stickerPos = _stickers[index].position;
                        final screenHeight = MediaQuery.of(context).size.height;
                        if (stickerPos.dy > screenHeight - 120) {
                          _stickers.removeAt(index);
                        }
                      }
                    });
                  },
                  child: Transform.rotate(
                    angle: sticker.rotation,
                    child: Transform.scale(
                      scale: sticker.scale,
                      child: _buildStickerWidget(sticker),
                    ),
                  ),
                ),
              ),
            ),

            // Delete Zone
            if (_isDraggingSticker)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
                  ),
                ),
              ),

            // Top Controls - Only show when _showControls is true
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                        const Spacer(),
                        // Crop button for images
                        if (widget.mediaType == StoryType.image)
                          IconButton(
                            onPressed: _cropImage,
                            icon: const Icon(Icons.crop, color: Colors.white),
                            tooltip: 'Crop',
                          ),
                        IconButton(
                          onPressed: _addTextSticker,
                          icon: const Icon(
                            Icons.text_fields,
                            color: Colors.white,
                          ),
                          tooltip: 'Add Text',
                        ),
                        IconButton(
                          onPressed: _addEmojiSticker,
                          icon: const Icon(
                            Icons.emoji_emotions,
                            color: Colors.white,
                          ),
                          tooltip: 'Add Emoji',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Bottom Controls - Only show when _showControls is true
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Discard',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isUploading ? null : _publishStory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: _isUploading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Share to Story',
                                    style: TextStyle(color: Colors.black),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Hint text when controls are hidden
            if (!_showControls)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Tap to show controls',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
      default:
        return const SizedBox.shrink();
    }
  }

  void _addTextSticker() {
    // Show text input dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Text'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter text...'),
          onSubmitted: (text) {
            if (text.isNotEmpty) {
              _addSticker(
                StorySticker(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  type: StickerType.text,
                  position: const Offset(100, 200),
                  data: {'text': text, 'color': 0xFFFFFFFF, 'fontSize': 18},
                ),
              );
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _addEmojiSticker() {
    // Add a default emoji - in a real app, you'd show an emoji picker
    _addSticker(
      StorySticker(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: StickerType.emoji,
        position: const Offset(150, 300),
        data: {'emoji': '😀', 'fontSize': 32},
      ),
    );
  }

  void _addSticker(StorySticker sticker) {
    setState(() {
      _stickers.add(sticker);
    });
  }

  Future<void> _cropImage() async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: widget.mediaFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Photo',
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
        ],
      );

      if (croppedFile != null && mounted) {
        // Replace the current image with cropped version
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StoryPreviewPage(
              mediaFile: XFile(croppedFile.path),
              mediaType: widget.mediaType,
              onPublish: widget.onPublish,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error cropping image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to crop image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _publishStory() async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Upload media file to Supabase
      final storyService = StoryService();
      final currentUser = ref.read(authProvider).user;
      
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      // Convert file path to XFile
      final xFile = XFile(widget.mediaFile.path);
      
      // Upload to Supabase and get URL
      final mediaUrl = await storyService.uploadStoryMedia(
        mediaFile: xFile,
        userId: currentUser.uid,
        type: widget.mediaType,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
            });
          }
        },
      );

      final storyItem = StoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: widget.mediaType,
        mediaUrl: mediaUrl,
        stickers: _stickers,
        createdAt: DateTime.now(),
      );

      widget.onPublish(storyItem);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish story: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
}
