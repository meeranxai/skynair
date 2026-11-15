import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Unified keyboard handler that solves all keyboard-related issues systematically
///
/// Root Cause Analysis:
/// 1. Multiple conflicting keyboard handlers
/// 2. Inconsistent keyboard detection methods
/// 3. Navigation bar moving with keyboard
/// 4. Back button not dismissing keyboard properly
/// 5. Complex layering causing interference
///
/// Solution:
/// - Single, unified keyboard management system
/// - Consistent keyboard detection across app
/// - Fixed navigation bar positioning
/// - Proper back button handling
/// - Clean, simple implementation
class UnifiedKeyboardHandler extends StatefulWidget {
  final Widget child;
  final bool hasBottomNavigation;

  const UnifiedKeyboardHandler({
    super.key,
    required this.child,
    this.hasBottomNavigation = false,
  });

  @override
  State<UnifiedKeyboardHandler> createState() => _UnifiedKeyboardHandlerState();
}

class _UnifiedKeyboardHandlerState extends State<UnifiedKeyboardHandler>
    with WidgetsBindingObserver {
  // Keyboard state management
  bool _isKeyboardVisible = false;
  double _keyboardHeight = 0;
  bool _backPressConsumed = false;

  // Constants
  static const double _bottomNavHeight = 80.0;
  static const Duration _keyboardAnimationDuration = Duration(
    milliseconds: 250,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _updateKeyboardState();
  }

  void _updateKeyboardState() {
    if (!mounted) return;

    final mediaQuery = MediaQuery.of(context);
    final newKeyboardHeight = mediaQuery.viewInsets.bottom;
    final newKeyboardVisible = newKeyboardHeight > 0;

    if (_isKeyboardVisible != newKeyboardVisible ||
        _keyboardHeight != newKeyboardHeight) {
      setState(() {
        _isKeyboardVisible = newKeyboardVisible;
        _keyboardHeight = newKeyboardHeight;

        // Reset back press flag when keyboard state changes
        if (!newKeyboardVisible) {
          _backPressConsumed = false;
        }
      });
    }
  }

  Future<bool> _handleBackPress() async {
    // If keyboard is visible and we haven't consumed a back press yet
    if (_isKeyboardVisible && !_backPressConsumed) {
      _backPressConsumed = true;

      // Dismiss keyboard using the most reliable method
      await _dismissKeyboard();

      // Prevent navigation
      return false;
    }

    // Allow navigation
    return true;
  }

  Future<void> _dismissKeyboard() async {
    // Use multiple methods for maximum reliability
    FocusManager.instance.primaryFocus?.unfocus();
    FocusScope.of(context).unfocus();

    // Force hide keyboard through system channel
    try {
      await SystemChannels.textInput.invokeMethod('TextInput.hide');
    } catch (e) {
      // Ignore errors from system channel
    }
  }

  void _handleTapOutside() {
    if (_isKeyboardVisible) {
      _dismissKeyboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;

    // Calculate content padding
    double bottomPadding = 0;
    if (widget.hasBottomNavigation) {
      bottomPadding = _isKeyboardVisible
          ? _keyboardHeight
          : _bottomNavHeight + safeAreaBottom;
    } else {
      bottomPadding = _isKeyboardVisible ? _keyboardHeight : 0;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _handleBackPress();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: GestureDetector(
        onTap: _handleTapOutside,
        behavior: HitTestBehavior.translucent,
        child: AnimatedContainer(
          duration: _keyboardAnimationDuration,
          curve: Curves.easeInOut,
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Unified keyboard-aware scaffold that replaces all other keyboard handling
class UnifiedKeyboardScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomSheet;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  const UnifiedKeyboardScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomSheet,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: UnifiedKeyboardHandler(child: body),
      bottomSheet: bottomSheet,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

/// Utility class for keyboard operations
class KeyboardManager {
  /// Check if keyboard is currently visible
  static bool isVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  /// Get current keyboard height
  static double getHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  /// Dismiss keyboard reliably
  static Future<void> dismiss() async {
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      await SystemChannels.textInput.invokeMethod('TextInput.hide');
    } catch (e) {
      // Ignore system channel errors
    }
  }

  /// Focus on a specific field and show keyboard
  static void focus(FocusNode focusNode) {
    focusNode.requestFocus();
  }

  /// Check if any text field has focus
  static bool hasFocus(BuildContext context) {
    return FocusScope.of(context).hasFocus;
  }
}

/// Extension for easy keyboard operations
extension KeyboardExtension on BuildContext {
  bool get isKeyboardVisible => KeyboardManager.isVisible(this);
  double get keyboardHeight => KeyboardManager.getHeight(this);
  Future<void> dismissKeyboard() => KeyboardManager.dismiss();
  bool get hasFocus => KeyboardManager.hasFocus(this);
}
