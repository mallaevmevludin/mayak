import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class AnimatedLikeButton extends StatefulWidget {
  final bool isLiked;
  final int likesCount;
  final bool isDark;
  final VoidCallback onTap;

  const AnimatedLikeButton({
    super.key,
    required this.isLiked,
    required this.likesCount,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<AnimatedLikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inactiveColor = widget.isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondaryLight;

    return GestureDetector(
      onTap: () {
        _controller.forward(from: 0.0);
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Row(
                children: [
                  Icon(
                    widget.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: widget.isLiked
                        ? const Color(0xFFFF2D55)
                        : inactiveColor,
                    size: 20,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${widget.likesCount}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: widget.isLiked
                          ? const Color(0xFFFF2D55)
                          : inactiveColor,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
