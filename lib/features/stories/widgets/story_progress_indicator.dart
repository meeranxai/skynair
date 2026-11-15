import 'package:flutter/material.dart';

class StoryProgressIndicator extends StatelessWidget {
  final int itemCount;
  final int currentIndex;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  const StoryProgressIndicator({
    super.key,
    required this.itemCount,
    required this.currentIndex,
    required this.progress,
    this.activeColor = Colors.white,
    this.inactiveColor = Colors.white38,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(itemCount, (index) {
        return Expanded(
          child: Container(
            height: 2.5, // Slightly thicker for better visibility
            margin: EdgeInsets.only(right: index < itemCount - 1 ? 4 : 0), // Increased spacing
            child: ClipRRect( // Rounded corners
              borderRadius: BorderRadius.circular(1.5),
              child: LinearProgressIndicator(
                value: _getProgressValue(index),
                backgroundColor: inactiveColor.withValues(alpha: 0.3), // More transparent background
                valueColor: AlwaysStoppedAnimation<Color>(activeColor),
              ),
            ),
          ),
        );
      }),
    );
  }

  double _getProgressValue(int index) {
    if (index < currentIndex) {
      return 1.0; // Completed
    } else if (index == currentIndex) {
      return progress; // Current progress
    } else {
      return 0.0; // Not started
    }
  }
}

class AnimatedStoryProgressIndicator extends StatefulWidget {
  final int itemCount;
  final int currentIndex;
  final Duration duration;
  final VoidCallback? onComplete;
  final Color activeColor;
  final Color inactiveColor;

  const AnimatedStoryProgressIndicator({
    super.key,
    required this.itemCount,
    required this.currentIndex,
    required this.duration,
    this.onComplete,
    this.activeColor = Colors.white,
    this.inactiveColor = Colors.white38,
  });

  @override
  State<AnimatedStoryProgressIndicator> createState() =>
      _AnimatedStoryProgressIndicatorState();
}

class _AnimatedStoryProgressIndicatorState
    extends State<AnimatedStoryProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    _startAnimation();
  }

  @override
  void didUpdateWidget(AnimatedStoryProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex ||
        oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    _controller.reset();
    _controller.forward();
  }

  void pause() {
    _controller.stop();
  }

  void resume() {
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return StoryProgressIndicator(
          itemCount: widget.itemCount,
          currentIndex: widget.currentIndex,
          progress: _animation.value,
          activeColor: widget.activeColor,
          inactiveColor: widget.inactiveColor,
        );
      },
    );
  }
}

class CircularStoryProgressIndicator extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color activeColor;
  final Color inactiveColor;
  final Widget? child;

  const CircularStoryProgressIndicator({
    super.key,
    required this.progress,
    this.size = 64,
    this.strokeWidth = 3,
    this.activeColor = Colors.white,
    this.inactiveColor = Colors.white38,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background circle
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(inactiveColor),
          ),

          // Progress circle
          CircularProgressIndicator(
            value: progress,
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(activeColor),
          ),

          // Child widget (usually avatar)
          if (child != null)
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(strokeWidth + 2),
                child: child,
              ),
            ),
        ],
      ),
    );
  }
}

class StoryProgressBar extends StatelessWidget {
  final double progress;
  final double height;
  final Color activeColor;
  final Color inactiveColor;
  final BorderRadius? borderRadius;

  const StoryProgressBar({
    super.key,
    required this.progress,
    this.height = 4,
    this.activeColor = Colors.white,
    this.inactiveColor = Colors.white38,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: inactiveColor,
        borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: activeColor,
            borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}

class MultiStoryProgressIndicator extends StatelessWidget {
  final List<double> progresses;
  final int currentIndex;
  final double height;
  final double spacing;
  final Color activeColor;
  final Color inactiveColor;
  final Color completedColor;

  const MultiStoryProgressIndicator({
    super.key,
    required this.progresses,
    required this.currentIndex,
    this.height = 3,
    this.spacing = 2,
    this.activeColor = Colors.white,
    this.inactiveColor = Colors.white38,
    this.completedColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(progresses.length, (index) {
        Color color;
        double progress;

        if (index < currentIndex) {
          color = completedColor;
          progress = 1.0;
        } else if (index == currentIndex) {
          color = activeColor;
          progress = progresses[index];
        } else {
          color = inactiveColor;
          progress = 0.0;
        }

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index < progresses.length - 1 ? spacing : 0,
            ),
            child: StoryProgressBar(
              progress: progress,
              height: height,
              activeColor: color,
              inactiveColor: inactiveColor,
            ),
          ),
        );
      }),
    );
  }
}

class StoryProgressController {
  final List<AnimationController> _controllers = [];
  int _currentIndex = 0;
  bool _isPaused = false;

  void initialize(TickerProvider vsync, List<Duration> durations) {
    _dispose();

    for (final duration in durations) {
      final controller = AnimationController(duration: duration, vsync: vsync);
      _controllers.add(controller);
    }
  }

  void start() {
    if (_controllers.isNotEmpty && _currentIndex < _controllers.length) {
      _controllers[_currentIndex].forward();
    }
  }

  void pause() {
    _isPaused = true;
    if (_currentIndex < _controllers.length) {
      _controllers[_currentIndex].stop();
    }
  }

  void resume() {
    _isPaused = false;
    if (_currentIndex < _controllers.length) {
      _controllers[_currentIndex].forward();
    }
  }

  void next() {
    if (_currentIndex < _controllers.length) {
      _controllers[_currentIndex].animateTo(1.0, duration: Duration.zero);
      _currentIndex++;
      if (_currentIndex < _controllers.length && !_isPaused) {
        _controllers[_currentIndex].forward();
      }
    }
  }

  void previous() {
    if (_currentIndex > 0) {
      _controllers[_currentIndex].reset();
      _currentIndex--;
      _controllers[_currentIndex].reset();
      if (!_isPaused) {
        _controllers[_currentIndex].forward();
      }
    }
  }

  void jumpTo(int index) {
    if (index >= 0 && index < _controllers.length) {
      // Complete all previous controllers
      for (int i = 0; i < index; i++) {
        _controllers[i].animateTo(1.0, duration: Duration.zero);
      }

      // Reset current and future controllers
      for (int i = index; i < _controllers.length; i++) {
        _controllers[i].reset();
      }

      _currentIndex = index;
      if (!_isPaused) {
        _controllers[_currentIndex].forward();
      }
    }
  }

  void _dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
  }

  void dispose() {
    _dispose();
  }

  int get currentIndex => _currentIndex;
  bool get isPaused => _isPaused;
  List<AnimationController> get controllers => _controllers;
}
