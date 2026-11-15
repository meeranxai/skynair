import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final bool showShadow;
  final VoidCallback? onTap;

  const AppLogo({
    super.key,
    this.size = 40,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 2,
    this.showShadow = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surface,
          border: showBorder
              ? Border.all(
                  color: borderColor ?? theme.colorScheme.primary,
                  width: borderWidth,
                )
              : null,
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipOval(
          child: Container(
            padding: EdgeInsets.all(size * 0.05), // Small padding inside circle
            child: ClipOval(
              child: Image.asset(
                'assets/logo.png',
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if image not found
                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'S',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size * 0.4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Different logo variants for specific use cases
class AppLogoVariants {
  /// Small logo for app bars and navigation
  static Widget small(BuildContext context, {VoidCallback? onTap}) {
    return AppLogo(
      size: 32,
      showBorder: false,
      showShadow: false,
      onTap: onTap,
    );
  }

  /// Medium logo for headers and cards
  static Widget medium(BuildContext context, {VoidCallback? onTap}) {
    return AppLogo(size: 48, showBorder: true, showShadow: true, onTap: onTap);
  }

  /// Large logo for splash screen and login
  static Widget large(BuildContext context, {VoidCallback? onTap}) {
    return AppLogo(
      size: 80,
      showBorder: true,
      borderWidth: 3,
      showShadow: true,
      onTap: onTap,
    );
  }

  /// Extra large logo for login page with enhanced circular design
  static Widget loginLogo(BuildContext context, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: AppLogo(
          size: 100,
          showBorder: true,
          borderWidth: 4,
          borderColor: theme.colorScheme.primary,
          showShadow: true,
          onTap: onTap,
        ),
      ),
    );
  }

  /// Animated logo with pulse effect
  static Widget animated(BuildContext context, {VoidCallback? onTap}) {
    return _AnimatedLogo(onTap: onTap);
  }
}

class _AnimatedLogo extends StatefulWidget {
  final VoidCallback? onTap;

  const _AnimatedLogo({this.onTap});

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: AppLogo(
              size: 80,
              showBorder: true,
              borderWidth: 3,
              showShadow: true,
              onTap: widget.onTap,
            ),
          ),
        );
      },
    );
  }
}
