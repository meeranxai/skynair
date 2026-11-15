import 'package:flutter/material.dart';

class NotificationBadge extends StatelessWidget {
  final int count;
  final Widget child;
  final Color? backgroundColor;
  final Color? textColor;
  final double? size;
  final bool showZero;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
    this.backgroundColor,
    this.textColor,
    this.size,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shouldShow = count > 0 || showZero;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (shouldShow)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: BoxConstraints(
                minWidth: size ?? 20,
                minHeight: size ?? 20,
              ),
              decoration: BoxDecoration(
                color: backgroundColor ?? theme.colorScheme.error,
                borderRadius: BorderRadius.circular((size ?? 20) / 2),
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: (size ?? 20) * 0.6,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
