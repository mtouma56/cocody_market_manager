import 'package:flutter/material.dart';

/// Drawer entry with built-in hover/press animations.
class AnimatedDrawerTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final String? description;

  const AnimatedDrawerTile({
    super.key,
    required this.title,
    required this.icon,
    this.isSelected = false,
    this.onTap,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: isSelected ? 1 : 0),
      builder: (context, value, child) {
        final backgroundColor = Color.lerp(
          Colors.transparent,
          colorScheme.primary.withValues(alpha: 0.12),
          value,
        );
        final iconBackground = Color.lerp(
          colorScheme.onSurface.withValues(alpha: 0.05),
          colorScheme.primary.withValues(alpha: 0.24),
          value,
        );
        final labelColor = Color.lerp(
          colorScheme.onSurface,
          colorScheme.primary,
          value,
        );

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 220),
                    scale: isSelected ? 1.05 : 1,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: labelColor,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: labelColor,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                        ),
                        if (description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            description!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: labelColor?.withValues(
                                          alpha: isSelected ? 0.85 : 0.65),
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isSelected ? 1 : 0,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
