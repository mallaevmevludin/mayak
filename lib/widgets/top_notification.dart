import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TopNotification extends StatefulWidget {
  final String message;
  final IconData? icon;
  final Color? iconColor;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final Duration duration;
  final VoidCallback onDismissed;

  const TopNotification({
    super.key,
    required this.message,
    this.icon,
    this.iconColor,
    this.actionLabel,
    this.onActionPressed,
    required this.duration,
    required this.onDismissed,
  });

  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? iconColor,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (_currentEntry != null) {
      try {
        _currentEntry!.remove();
      } catch (_) {}
      _currentEntry = null;
    }

    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => TopNotification(
        message: message,
        icon: icon,
        iconColor: iconColor,
        actionLabel: actionLabel,
        onActionPressed: onActionPressed,
        duration: duration,
        onDismissed: () {
          try {
            overlayEntry.remove();
          } catch (_) {}
          if (_currentEntry == overlayEntry) {
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = overlayEntry;
    overlayState.insert(overlayEntry);
  }

  @override
  State<TopNotification> createState() => _TopNotificationState();
}

class _TopNotificationState extends State<TopNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    _timer = Timer(widget.duration, () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (mounted) {
      _controller.reverse().then((_) {
        widget.onDismissed();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            top: false,
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.55)
                          : Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.08),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: widget.iconColor ?? AppTheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            widget.message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        if (widget.actionLabel != null &&
                            widget.onActionPressed != null) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: AppTheme.primary,
                            ),
                            onPressed: () {
                              widget.onActionPressed!();
                              _dismiss();
                            },
                            child: Text(
                              widget.actionLabel!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
