import 'package:flutter/material.dart';

class LiveIndicator extends StatefulWidget {
  final bool isLive;
  final double size;
  final Color? color;

  const LiveIndicator({
    super.key,
    this.isLive = false,
    this.size = 12.0,
    this.color,
  });

  @override
  State<LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isLive) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LiveIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLive != oldWidget.isLive) {
      if (widget.isLive) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        widget.color ??
        (widget.isLive ? Colors.red : theme.colorScheme.onSurfaceVariant);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isLive
                ? color.withValues(alpha: _animation.value)
                : color,
          ),
        );
      },
    );
  }
}
