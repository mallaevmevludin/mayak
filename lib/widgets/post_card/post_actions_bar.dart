import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/post_model.dart';
import '../../../services/social_service.dart';
import '../../../screens/comments_screen.dart';
import '../../../theme/app_theme.dart';
import 'animated_like_button.dart';

class PostActionsBar extends StatelessWidget {
  final PostModel post;
  final bool isClickable;
  final VoidCallback? onLikeToggle;

  const PostActionsBar({
    super.key,
    required this.post,
    this.isClickable = true,
    this.onLikeToggle,
  });

  String _pluralize(int count, String one, String two, String five) {
    int n = count % 100;
    if (n >= 11 && n <= 19) {
      return '$count $five';
    }
    n = count % 10;
    if (n == 1) {
      return '$count $one';
    }
    if (n >= 2 && n <= 4) {
      return '$count $two';
    }
    return '$count $five';
  }

  String _formatFullDateTime(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final diff = now.difference(local);

    if (diff.isNegative) {
      return 'сейчас';
    }

    if (diff.inMinutes < 1) {
      return 'только что';
    }

    if (diff.inMinutes < 60) {
      return '${_pluralize(diff.inMinutes, 'минуту', 'минуты', 'минут')} назад';
    }

    if (diff.inHours < 24) {
      return '${_pluralize(diff.inHours, 'час', 'часа', 'часов')} назад';
    }

    if (diff.inDays < 7) {
      return '${_pluralize(diff.inDays, 'день', 'дня', 'дней')} назад';
    }

    final day = local.day;
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    final monthStr = months[local.month - 1];

    if (local.year != now.year) {
      return '$day $monthStr ${local.year} г.';
    }
    return '$day $monthStr';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        // Like
        AnimatedLikeButton(
          isLiked: post.isLikedByMe,
          likesCount: post.likesCount,
          isDark: isDark,
          onTap: () {
            Provider.of<SocialService>(
              context,
              listen: false,
            ).likePost(
              post.id,
              currentlyLikedByMe: post.isLikedByMe,
            );
            if (onLikeToggle != null) {
              onLikeToggle!();
            }
          },
        ),
        const SizedBox(width: 20),

        // Comment
        _ActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: '${post.commentsCount}',
          isDark: isDark,
          onTap: () {
            if (isClickable) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CommentsScreen(postId: post.id, post: post),
                ),
              );
            }
          },
        ),
        const Spacer(),

        // Publication date and time
        Text(
          _formatFullDateTime(post.createdAt),
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? AppTheme.textSecondaryDark.withValues(
                    alpha: 0.6,
                  )
                : AppTheme.textSecondaryLight.withValues(
                    alpha: 0.6,
                  ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondaryLight;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: defaultColor, size: 19),
            if (label != null) ...[
              const SizedBox(width: 5),
              Text(
                label!,
                style: TextStyle(
                  fontSize: 13,
                  color: defaultColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
