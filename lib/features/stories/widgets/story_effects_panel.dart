import 'package:flutter/material.dart';

class StoryEffectsPanel extends StatelessWidget {
  final VoidCallback? onFilterTap;
  final VoidCallback? onTextTap;
  final VoidCallback? onStickerTap;
  final VoidCallback? onDrawTap;

  const StoryEffectsPanel({
    super.key,
    this.onFilterTap,
    this.onTextTap,
    this.onStickerTap,
    this.onDrawTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _EffectButton(
            icon: Icons.filter,
            label: 'Filter',
            onTap: onFilterTap,
          ),
          _EffectButton(
            icon: Icons.text_fields,
            label: 'Text',
            onTap: onTextTap,
          ),
          _EffectButton(
            icon: Icons.emoji_emotions,
            label: 'Sticker',
            onTap: onStickerTap,
          ),
          _EffectButton(icon: Icons.brush, label: 'Draw', onTap: onDrawTap),
        ],
      ),
    );
  }
}

class _EffectButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _EffectButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
