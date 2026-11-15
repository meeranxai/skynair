import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/story_model.dart';

class StoryTextEditor extends StatefulWidget {
  final Function(String, StoryBackground) onTextCreated;

  const StoryTextEditor({super.key, required this.onTextCreated});

  @override
  State<StoryTextEditor> createState() => _StoryTextEditorState();
}

class _StoryTextEditorState extends State<StoryTextEditor> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  static const int _maxCharacters = 190; // Instagram-style limit
  int _currentCharacters = 0;

  int _currentBackgroundIndex = 0;
  Color _textColor = Colors.white;
  TextAlign _textAlign = TextAlign.center;
  double _fontSize = 32.0;
  String _currentFont = 'Roboto';
  bool _showStylingPanel = false;

  final List<Map<String, dynamic>> _fonts = [
    {'name': 'Modern', 'family': 'Roboto', 'weight': FontWeight.w900},
    {'name': 'Classic', 'family': 'Serif', 'weight': FontWeight.w400},
    {'name': 'Sharp', 'family': 'Monospace', 'weight': FontWeight.w700},
    {'name': 'Soft', 'family': 'Roboto', 'weight': FontWeight.w300},
  ];

  final List<StoryBackground> _backgrounds = [
    const StoryBackground(
      type: BackgroundType.gradient,
      gradientColors: ['0xFF667eea', '0xFF764ba2'],
    ),
    const StoryBackground(
      type: BackgroundType.gradient,
      gradientColors: ['0xFFf093fb', '0xFFf5576c'],
    ),
    const StoryBackground(
      type: BackgroundType.gradient,
      gradientColors: ['0xFF4facfe', '0xFF00f2fe'],
    ),
    const StoryBackground(
      type: BackgroundType.gradient,
      gradientColors: ['0xFF43e97b', '0xFF38f9d7'],
    ),
    const StoryBackground(
      type: BackgroundType.gradient,
      gradientColors: ['0xFFfa709a', '0xFFfee140'],
    ),
    const StoryBackground(type: BackgroundType.color, color: '0xFF000000'),
    const StoryBackground(type: BackgroundType.color, color: '0xFFFFFFFF'),
  ];

  final List<Color> _textColors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: _buildBackgroundDecoration(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Text Input Area
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _focusNode.requestFocus(),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 80,
                    ),
                    child: Column(
                      children: [
                        // Text input
                        Expanded(
                          child: Center(
                            child: TextField(
                              controller: _textController,
                              focusNode: _focusNode,
                              style: TextStyle(
                                color: _textColor,
                                fontSize: _fontSize,
                                fontWeight: _fonts.firstWhere(
                                  (f) =>
                                      f['family'] == _currentFont ||
                                      f['name'] == _currentFont,
                                  orElse: () => _fonts[0],
                                )['weight'],
                                fontFamily: _currentFont,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              textAlign: _textAlign,
                              maxLines: null,
                              maxLength: _maxCharacters,
                              buildCounter:
                                  (
                                    context, {
                                    int? currentLength,
                                    bool? isFocused,
                                    int? maxLength,
                                  }) => null, // Hide default counter
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Type something...',
                                hintStyle: TextStyle(color: Colors.white70),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              onChanged: (value) {
                                setState(() {
                                  _currentCharacters = value.length;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Top Controls
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: 'Close',
                      ),
                      const Spacer(),
                      // Character counter in the middle/top
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_currentCharacters/$_maxCharacters',
                          style: TextStyle(
                            color: _currentCharacters > _maxCharacters
                                ? Colors.red
                                : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showStylingPanel = !_showStylingPanel;
                            if (_showStylingPanel) {
                              _focusNode.unfocus();
                            } else {
                              _focusNode.requestFocus();
                            }
                          });
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _showStylingPanel
                                ? Colors.green
                                : Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _showStylingPanel ? Icons.check : Icons.palette,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        tooltip: 'Style',
                      ),
                      IconButton(
                        onPressed: _toggleTextAlign,
                        icon: Icon(_getTextAlignIcon(), color: Colors.white),
                        tooltip: 'Text Align',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Styling Panel
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              bottom: _showStylingPanel ? 0 : -500,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // Font Selection
                        const Text(
                          'Select Style',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _fonts.length,
                            itemBuilder: (context, index) {
                              final font = _fonts[index];
                              final isSelected =
                                  _currentFont == font['family'] ||
                                  _currentFont == font['name'];
                              return GestureDetector(
                                onTap: () => setState(
                                  () => _currentFont = font['family'],
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white10,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    font['name'],
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Color label and palette... (keeping existing color logic but improved UI)
                        const Text(
                          'Text Color',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 44,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _textColors.length,
                            itemBuilder: (context, index) {
                              final color = _textColors[index];
                              return GestureDetector(
                                onTap: () => setState(() => _textColor = color),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _textColor == color
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      if (_textColor == color)
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.5),
                                          blurRadius: 10,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Text(
                          'Background',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _backgrounds.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => setState(
                                  () => _currentBackgroundIndex = index,
                                ),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _currentBackgroundIndex == index
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      decoration: _buildBackgroundDecoration(
                                        _backgrounds[index],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),
                        // Font Size Slider
                        Row(
                          children: [
                            const Icon(
                              Icons.format_size,
                              color: Colors.white,
                              size: 20,
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: Colors.white,
                                  overlayColor: Colors.white10,
                                ),
                                child: Slider(
                                  value: _fontSize,
                                  min: 16.0,
                                  max: 80.0,
                                  onChanged: (val) =>
                                      setState(() => _fontSize = val),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Main Action Bar (when not styling)
            if (!_showStylingPanel)
              Positioned(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _textController.text.trim().isNotEmpty &&
                                _currentCharacters <= _maxCharacters
                            ? _createTextStory
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          'Post to Story',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration([StoryBackground? background]) {
    final bg = background ?? _backgrounds[_currentBackgroundIndex];

    switch (bg.type) {
      case BackgroundType.color:
        return BoxDecoration(color: Color(int.parse(bg.color ?? '0xFF000000')));
      case BackgroundType.gradient:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                bg.gradientColors
                    ?.map((color) => Color(int.parse(color)))
                    .toList() ??
                [Colors.purple, Colors.blue],
          ),
        );
      default:
        return const BoxDecoration(color: Colors.black);
    }
  }

  IconData _getTextAlignIcon() {
    switch (_textAlign) {
      case TextAlign.left:
        return Icons.format_align_left;
      case TextAlign.center:
        return Icons.format_align_center;
      case TextAlign.right:
        return Icons.format_align_right;
      default:
        return Icons.format_align_center;
    }
  }

  void _toggleTextAlign() {
    setState(() {
      switch (_textAlign) {
        case TextAlign.left:
          _textAlign = TextAlign.center;
          break;
        case TextAlign.center:
          _textAlign = TextAlign.right;
          break;
        case TextAlign.right:
          _textAlign = TextAlign.left;
          break;
        default:
          _textAlign = TextAlign.center;
      }
    });
  }


  void _createTextStory() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final background = _backgrounds[_currentBackgroundIndex];
    widget.onTextCreated(text, background);
    Navigator.pop(context);
  }
}

// Story effects panel for camera
class StoryEffectsPanel extends StatelessWidget {
  final List<StoryEffect> effects;
  final Function(StoryEffect) onEffectSelected;

  const StoryEffectsPanel({
    super.key,
    required this.effects,
    required this.onEffectSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: ListView.builder(
        itemCount: effects.length,
        itemBuilder: (context, index) {
          final effect = effects[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => onEffectSelected(effect),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(effect.icon, color: Colors.white, size: 24),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Story effect model
class StoryEffect {
  final String id;
  final String name;
  final IconData icon;
  final String? filterName;
  final Map<String, dynamic> parameters;

  const StoryEffect({
    required this.id,
    required this.name,
    required this.icon,
    this.filterName,
    this.parameters = const {},
  });
}

// Predefined story effects
class StoryEffects {
  static const List<StoryEffect> effects = [
    StoryEffect(id: 'normal', name: 'Normal', icon: Icons.camera),
    StoryEffect(
      id: 'vintage',
      name: 'Vintage',
      icon: Icons.photo_filter,
      filterName: 'vintage',
    ),
    StoryEffect(
      id: 'black_white',
      name: 'B&W',
      icon: Icons.filter_b_and_w,
      filterName: 'grayscale',
    ),
    StoryEffect(
      id: 'sepia',
      name: 'Sepia',
      icon: Icons.filter_vintage,
      filterName: 'sepia',
    ),
    StoryEffect(
      id: 'blur',
      name: 'Blur',
      icon: Icons.blur_on,
      filterName: 'blur',
      parameters: {'radius': 5.0},
    ),
    StoryEffect(
      id: 'brightness',
      name: 'Bright',
      icon: Icons.brightness_high,
      filterName: 'brightness',
      parameters: {'value': 0.2},
    ),
    StoryEffect(
      id: 'contrast',
      name: 'Contrast',
      icon: Icons.contrast,
      filterName: 'contrast',
      parameters: {'value': 1.2},
    ),
  ];
}
