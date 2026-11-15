import 'package:flutter/material.dart';

/// Professional skeleton loader for feed
/// Shows while posts are loading for better UX
class FeedSkeletonLoader extends StatefulWidget {
  final int itemCount;

  const FeedSkeletonLoader({super.key, this.itemCount = 3});

  @override
  State<FeedSkeletonLoader> createState() => _FeedSkeletonLoaderState();
}

class _FeedSkeletonLoaderState extends State<FeedSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) => _buildSkeletonCard(context),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _buildShimmerCircle(40, theme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerBox(120, 14, theme),
                      const SizedBox(height: 6),
                      _buildShimmerBox(80, 12, theme),
                    ],
                  ),
                ),
                _buildShimmerCircle(32, theme),
              ],
            ),
          ),

          // Content skeleton
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(double.infinity, 16, theme),
                const SizedBox(height: 6),
                _buildShimmerBox(double.infinity, 16, theme),
                const SizedBox(height: 6),
                _buildShimmerBox(200, 16, theme),
              ],
            ),
          ),

          // Image skeleton
          _buildShimmerBox(
            double.infinity,
            MediaQuery.of(context).size.width,
            theme,
            borderRadius: 0,
          ),

          // Stats skeleton
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                _buildShimmerBox(60, 12, theme),
                const SizedBox(width: 16),
                _buildShimmerBox(80, 12, theme),
              ],
            ),
          ),

          // Actions skeleton
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
            child: Row(
              children: [
                _buildShimmerCircle(40, theme),
                const SizedBox(width: 8),
                _buildShimmerCircle(40, theme),
                const SizedBox(width: 8),
                _buildShimmerCircle(40, theme),
                const Spacer(),
                _buildShimmerCircle(40, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox(
    double width,
    double height,
    ThemeData theme, {
    double borderRadius = 8,
  }) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
              ],
              stops: [
                (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerCircle(double size, ThemeData theme) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
              ],
              stops: [
                (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
