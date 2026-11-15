/// Photo Edit Parameters Model
class EditParameters {
  final double brightness; // -100 to +100
  final double contrast; // -100 to +100
  final double saturation; // 0 to 200
  final int rotation; // 0, 90, 180, 270
  final bool flipHorizontal;
  final bool flipVertical;
  final CropAspectRatio? cropRatio;

  EditParameters({
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 100,
    this.rotation = 0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.cropRatio,
  });

  EditParameters copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    int? rotation,
    bool? flipHorizontal,
    bool? flipVertical,
    CropAspectRatio? cropRatio,
  }) {
    return EditParameters(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      rotation: rotation ?? this.rotation,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      cropRatio: cropRatio ?? this.cropRatio,
    );
  }

  bool get hasChanges =>
      brightness != 0 ||
      contrast != 0 ||
      saturation != 100 ||
      rotation != 0 ||
      flipHorizontal ||
      flipVertical ||
      cropRatio != null;

  bool get hasExcessiveEdits =>
      brightness.abs() > 50 || contrast.abs() > 50 || saturation > 150;

  List<String> get warnings {
    final warnings = <String>[];
    if (brightness.abs() > 50) {
      warnings.add('Brightness adjustment is very high');
    }
    if (contrast.abs() > 50) {
      warnings.add('Contrast adjustment is very high');
    }
    if (saturation > 150) {
      warnings.add('Saturation is very high - colors may look unnatural');
    }
    return warnings;
  }
}

enum CropAspectRatio {
  square, // 1:1
  portrait, // 4:5
  landscape, // 16:9
  original, // Keep original
}

extension CropAspectRatioExtension on CropAspectRatio {
  String get label {
    switch (this) {
      case CropAspectRatio.square:
        return 'Square (1:1)';
      case CropAspectRatio.portrait:
        return 'Portrait (4:5)';
      case CropAspectRatio.landscape:
        return 'Landscape (16:9)';
      case CropAspectRatio.original:
        return 'Original';
    }
  }

  double get ratio {
    switch (this) {
      case CropAspectRatio.square:
        return 1.0;
      case CropAspectRatio.portrait:
        return 4.0 / 5.0;
      case CropAspectRatio.landscape:
        return 16.0 / 9.0;
      case CropAspectRatio.original:
        return 0.0; // Will use original
    }
  }
}
