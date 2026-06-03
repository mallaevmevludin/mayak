import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SlidingSegmentedControl extends StatelessWidget {
  final List<String> children;
  final int selectedIndex;
  final ValueChanged<int> onValueChanged;

  const SlidingSegmentedControl({
    super.key,
    required this.children,
    required this.selectedIndex,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          // Sliding indicator capsule
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOutCubic,
            alignment: Alignment(
              children.length > 1
                  ? -1.0 + (selectedIndex * (2.0 / (children.length - 1)))
                  : -1.0,
              0.0,
            ),
            child: FractionallySizedBox(
              widthFactor: children.isNotEmpty ? 1.0 / children.length : 1.0,
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.04,
                      ),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Option buttons on top
          Row(
            children: List.generate(
              children.length,
              (index) => Expanded(
                child: GestureDetector(
                  onTap: () => onValueChanged(index),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selectedIndex == index
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: selectedIndex == index
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight),
                      ),
                      child: Text(children[index]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
