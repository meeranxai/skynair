import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Configuration for Flutter Widget Inspector
/// This helps with widget preview and debugging
class InspectorConfig {
  static void configure() {
    if (kDebugMode) {
      // Enable widget inspector
      WidgetsFlutterBinding.ensureInitialized();

      // Configure debug settings for better widget inspection
      debugPaintSizeEnabled = false; // Set to true to see widget boundaries
      debugRepaintRainbowEnabled = false; // Set to true to see repaints

      // Configure performance overlay
      // WidgetsApp.showPerformanceOverlayOverride = true; // Uncomment to show performance

      // Configure semantics
      WidgetsBinding.instance.ensureSemantics();
    }
  }

  /// Enable debug painting for widget boundaries
  static void enableDebugPainting() {
    if (kDebugMode) {
      debugPaintSizeEnabled = true;
    }
  }

  /// Disable debug painting
  static void disableDebugPainting() {
    if (kDebugMode) {
      debugPaintSizeEnabled = false;
    }
  }

  /// Enable repaint rainbow for performance debugging
  static void enableRepaintRainbow() {
    if (kDebugMode) {
      debugRepaintRainbowEnabled = true;
    }
  }

  /// Disable repaint rainbow
  static void disableRepaintRainbow() {
    if (kDebugMode) {
      debugRepaintRainbowEnabled = false;
    }
  }

  /// Toggle widget inspector overlay
  static void toggleInspector() {
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // This will trigger the widget inspector
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      });
    }
  }
}

/// Widget Inspector Helper
/// Provides utilities for widget inspection and debugging
class InspectorHelper {
  /// Wrap a widget with inspection capabilities
  static Widget wrapForInspection(
    Widget child, {
    String? debugLabel,
    Color? debugColor,
  }) {
    if (!kDebugMode) return child;

    return Container(
      decoration: debugColor != null
          ? BoxDecoration(border: Border.all(color: debugColor, width: 1))
          : null,
      child: Builder(
        builder: (context) {
          if (debugLabel != null) {
            return Semantics(label: debugLabel, child: child);
          }
          return child;
        },
      ),
    );
  }

  /// Create a debug info overlay
  static Widget debugInfo(String info, Widget child) {
    if (!kDebugMode) return child;

    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              info,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Log widget build information
  static void logBuild(String widgetName) {
    if (kDebugMode) {
      debugPrint('🔧 Building: $widgetName at ${DateTime.now()}');
    }
  }

  /// Log widget interaction
  static void logInteraction(String widgetName, String action) {
    if (kDebugMode) {
      debugPrint('👆 $widgetName: $action at ${DateTime.now()}');
    }
  }
}
