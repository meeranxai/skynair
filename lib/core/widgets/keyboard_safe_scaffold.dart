import 'package:flutter/material.dart';

/// A scaffold that keeps the bottom navigation bar fixed at the bottom
/// while preventing keyboard-related layout issues.
///
/// Use this for screens with minimal keyboard interaction where you want
/// the bottom navigation bar to remain fixed (Home, Explore, Profile, etc.)
///
/// Key features:
/// - Bottom navigation bar stays fixed when keyboard appears
/// - No white space issues
/// - Prevents layout overflow
/// - Optimized for feed-style screens
class KeyboardSafeScaffold extends StatelessWidget {
  /// The app bar to display at the top
  final PreferredSizeWidget? appBar;

  /// The primary content of the scaffold
  final Widget body;

  /// The bottom navigation bar (stays fixed)
  final Widget? bottomNavigationBar;

  /// Floating action button
  final Widget? floatingActionButton;

  /// Background color of the scaffold
  final Color? backgroundColor;

  /// Whether to resize the body when the keyboard appears
  /// Default is false to keep bottom nav fixed
  final bool resizeToAvoidBottomInset;

  /// Floating action button location
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Whether to extend body behind app bar
  final bool extendBody;

  const KeyboardSafeScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = false,
    this.floatingActionButtonLocation,
    this.extendBody = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      // Force false to keep bottom navigation bar fixed at the very bottom
      resizeToAvoidBottomInset: false,
      appBar: appBar,
      body: Padding(
        // Manually apply keyboard padding to the body so content isn't covered
        // but the Scaffold itself doesn't resize (keeping bottom bar fixed)
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: body,
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      extendBody: extendBody,
    );
  }
}
