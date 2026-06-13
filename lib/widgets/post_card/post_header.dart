import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/post_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/social_service.dart';
import '../../../theme/app_dimens.dart';
import '../../../theme/app_theme.dart';
import '../../../screens/user_profile_screen.dart';
import '../user_avatar.dart';

class PostHeader extends StatelessWidget {
  final PostModel post;
  final bool useHero;
  final VoidCallback? onDelete;

  const PostHeader({
    super.key,
    required this.post,
    this.useHero = true,
    this.onDelete,
  });

  void _navigateToProfile(BuildContext context, String heroTag) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            UserProfileScreen(userId: post.userId, heroTag: heroTag),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, bool isDark) async {
    bool isDeletingLocal = false;

    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Удалить пост?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Вы уверены, что хотите удалить этот пост? Это действие нельзя отменить.',
            ),
            actions: [
              TextButton(
                onPressed: isDeletingLocal ? null : () => Navigator.pop(context, false),
                child: Text(
                  'Отмена',
                  style: TextStyle(
                    color: isDeletingLocal
                        ? Colors.grey
                        : (isDark ? Colors.white60 : Colors.black54),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: isDeletingLocal
                    ? null
                    : () async {
                        setDialogState(() => isDeletingLocal = true);
                        final deleteResult = await Provider.of<SocialService>(
                          context,
                          listen: false,
                        ).deletePost(post.id);
                        if (context.mounted) {
                          Navigator.pop(context, deleteResult);
                        }
                      },
                child: isDeletingLocal
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.error,
                        ),
                      )
                    : const Text(
                        'Удалить',
                        style: TextStyle(
                          color: AppTheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );

    if (success == false && context.mounted) {
      final error = Provider.of<SocialService>(context, listen: false).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Не удалось удалить пост'),
          backgroundColor: AppTheme.error,
        ),
      );
    } else if (success == true && onDelete != null) {
      onDelete!();
    }
  }

  Widget _buildPostActionsSheet(
    BuildContext parentContext,
    BuildContext sheetContext,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDelete(parentContext, isDark);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      color: AppTheme.error,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Удалить пост',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(sheetContext),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Отмена',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final avatarHeroTag = 'avatar-${post.id}-${post.userId}';
    final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
    final bool isMyPost = currentUser != null && currentUser.id == post.userId;

    Widget avatar = UserAvatar.fromUsername(
      username: post.userUsername,
      avatarUrl: post.userAvatarUrl,
      size: 40,
      onTap: () => _navigateToProfile(context, avatarHeroTag),
    );

    if (useHero) {
      avatar = Hero(
        tag: avatarHeroTag,
        child: avatar,
      );
    }

    return Row(
      children: [
        avatar,
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => _navigateToProfile(context, avatarHeroTag),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${post.userFirstName} ${post.userLastName}'.trim(),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (post.userIsVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        color: AppTheme.primary,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isMyPost) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (sheetContext) {
                  return _buildPostActionsSheet(
                    context,
                    sheetContext,
                    isDark,
                  );
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.more_horiz_rounded,
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
                size: 20,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
