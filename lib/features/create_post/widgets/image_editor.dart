import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageEditor extends StatefulWidget {
  final XFile imageFile;
  final Function(XFile) onSave;

  const ImageEditor({
    super.key,
    required this.imageFile,
    required this.onSave,
  });

  @override
  State<ImageEditor> createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor> {
  final GlobalKey _imageKey = GlobalKey();
  
  // Image adjustments
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  double _rotation = 0.0;
  
  // Filter presets
  String _selectedFilter = 'None';
  final List<Map<String, dynamic>> _filters = [
    {'name': 'None', 'brightness': 0.0, 'contrast': 1.0, 'saturation': 1.0},
    {'name': 'Vivid', 'brightness': 0.05, 'contrast': 1.2, 'saturation': 1.3},
    {'name': 'Cool', 'brightness': 0.0, 'contrast': 1.1, 'saturation': 0.8},
    {'name': 'Warm', 'brightness': 0.1, 'contrast': 1.0, 'saturation': 1.2},
    {'name': 'B&W', 'brightness': 0.0, 'contrast': 1.1, 'saturation': 0.0},
    {'name': 'Vintage', 'brightness': -0.05, 'contrast': 0.9, 'saturation': 0.7},
  ];

  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Edit Image', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveImage,
              child: Text(
                'Done',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Image Preview
          Expanded(
            flex: 3,
            child: Center(
              child: RepaintBoundary(
                key: _imageKey,
                child: Transform.rotate(
                  angle: _rotation * 3.14159 / 180,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.matrix(_getColorMatrix()),
                    child: Image.file(
                      File(widget.imageFile.path),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Tools Section
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Filters
                  Container(
                    height: 100,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        final isSelected = _selectedFilter == filter['name'];
                        
                        return GestureDetector(
                          onTap: () => _applyFilter(filter),
                          child: Container(
                            width: 70,
                            margin: EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected 
                                          ? theme.colorScheme.primary 
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: ColorFiltered(
                                      colorFilter: ColorFilter.matrix(
                                        _getFilterMatrix(filter),
                                      ),
                                      child: Image.file(
                                        File(widget.imageFile.path),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  filter['name'],
                                  style: TextStyle(
                                    color: isSelected 
                                        ? theme.colorScheme.primary 
                                        : Colors.white70,
                                    fontSize: 11,
                                    fontWeight: isSelected 
                                        ? FontWeight.bold 
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  Divider(color: Colors.white24, height: 1),

                  // Adjustment Controls
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.all(16),
                      children: [
                        _buildSlider(
                          'Brightness',
                          Icons.brightness_6,
                          _brightness,
                          -0.3,
                          0.3,
                          (value) => setState(() => _brightness = value),
                        ),
                        _buildSlider(
                          'Contrast',
                          Icons.contrast,
                          _contrast,
                          0.5,
                          1.5,
                          (value) => setState(() => _contrast = value),
                        ),
                        _buildSlider(
                          'Saturation',
                          Icons.palette,
                          _saturation,
                          0.0,
                          2.0,
                          (value) => setState(() => _saturation = value),
                        ),
                        _buildSlider(
                          'Rotation',
                          Icons.rotate_right,
                          _rotation,
                          -180,
                          180,
                          (value) => setState(() => _rotation = value),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    IconData icon,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Spacer(),
              Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor: Colors.white24,
              thumbColor: theme.colorScheme.primary,
              overlayColor: theme.colorScheme.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  void _applyFilter(Map<String, dynamic> filter) {
    setState(() {
      _selectedFilter = filter['name'];
      _brightness = filter['brightness'];
      _contrast = filter['contrast'];
      _saturation = filter['saturation'];
    });
  }

  List<double> _getColorMatrix() {
    // Brightness, Contrast, Saturation Matrix
    final double b = _brightness;
    final double c = _contrast;
    final double s = _saturation;
    
    final double sr = (1 - s) * 0.3086;
    final double sg = (1 - s) * 0.6094;
    final double sb = (1 - s) * 0.0820;
    
    return [
      sr + s * c, sg, sb, 0, b * 255,
      sr, sg + s * c, sb, 0, b * 255,
      sr, sg, sb + s * c, 0, b * 255,
      0, 0, 0, 1, 0,
    ];
  }

  List<double> _getFilterMatrix(Map<String, dynamic> filter) {
    final double b = filter['brightness'];
    final double c = filter['contrast'];
    final double s = filter['saturation'];
    
    final double sr = (1 - s) * 0.3086;
    final double sg = (1 - s) * 0.6094;
    final double sb = (1 - s) * 0.0820;
    
    return [
      sr + s * c, sg, sb, 0, b * 255,
      sr, sg + s * c, sb, 0, b * 255,
      sr, sg, sb + s * c, 0, b * 255,
      0, 0, 0, 1, 0,
    ];
  }

  Future<void> _saveImage() async {
    setState(() => _isSaving = true);

    try {
      // Capture the edited image
      RenderRepaintBoundary boundary = _imageKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      
      if (byteData == null) {
        throw Exception('Failed to convert image');
      }

      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/edited_image_$timestamp.png';
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      // Convert to XFile
      final editedXFile = XFile(filePath);

      // Call the save callback
      widget.onSave(editedXFile);
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
