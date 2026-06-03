import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/post_model.dart';
import '../services/social_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../screens/user_profile_screen.dart';
import '../screens/comments_screen.dart';
import 'mention_text_builder.dart';
import 'multi_image_slider.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onDelete;
  final VoidCallback? onLikeToggle;
  final bool useHero;
  final bool isClickable;

  const PostCard({
    super.key,
    required this.post,
    this.onDelete,
    this.onLikeToggle,
    this.useHero = true,
    this.isClickable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final initial = post.userUsername.isNotEmpty
        ? post.userUsername[0].toUpperCase()
        : 'U';

    final avatarHeroTag = 'avatar-${post.id}-${post.userId}';
    final currentUser = Provider.of<AuthService>(
      context,
      listen: false,
    ).currentUser;
    final bool isMyPost = currentUser != null && currentUser.id == post.userId;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: isClickable
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommentsScreen(
                        postId: post.id,
                        post: post,
                      ),
                    ),
                  );
                }
              : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header: Avatar + Name + @username + time ──
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () =>
                              _navigateToProfile(context, avatarHeroTag),
                          child: useHero
                              ? Hero(
                                  tag: avatarHeroTag,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.black.withValues(
                                              alpha: 0.04,
                                            ),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.1,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.06,
                                              ),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: post.userAvatarUrl != null &&
                                              post.userAvatarUrl!.isNotEmpty
                                          ? Image.network(
                                              post.userAvatarUrl!,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return const Center(
                                                  child: SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 1.5,
                                                      color: AppTheme.primary,
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) => Center(
                                                child: Text(
                                                  initial,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: isDark ? Colors.white70 : Colors.black87,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                initial,
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white70
                                                      : Colors.black87,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.04),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : Colors.black.withValues(
                                              alpha: 0.06,
                                            ),
                                      width: 0.5,
                                    ),
                                  ),
                                   child: ClipOval(
                                      child: post.userAvatarUrl != null &&
                                              post.userAvatarUrl!.isNotEmpty
                                          ? Image.network(
                                              post.userAvatarUrl!,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return const Center(
                                                  child: SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 1.5,
                                                      color: AppTheme.primary,
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) => Center(
                                                child: Text(
                                                  initial,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: isDark ? Colors.white70 : Colors.black87,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                initial,
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white70
                                                      : Colors.black87,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                    ),
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                _navigateToProfile(context, avatarHeroTag),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '${post.userFirstName} ${post.userLastName}'
                                            .trim(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
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
                    ),

                    const SizedBox(height: 12),

                    // ── Post content with @mention support ──
                    MentionTextBuilder(
                      text: post.content,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.92)
                            : Colors.black87,
                        letterSpacing: -0.2,
                      ),
                    ),

                    // Post Image (Progressive Loader & Slider)
                    if (post.imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      MultiImageSlider(
                        imageUrls: post.imageUrls,
                        aspectRatio: post.imageFormat == '16:9'
                            ? 16 / 9
                            : post.imageFormat == '9:16'
                                ? 9 / 16
                                : 1.0,
                      ),
                    ],

                    // Website Link Preview
                    _buildLinkPreview(context, isDark),

                    // Poll Widget
                    _buildPollWidget(context, isDark),

                    const SizedBox(height: 14),

                    // ── Action bar ──
                    Row(
                      children: [
                        // Like
                        _AnimatedLikeButton(
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
        // Slightly visible separator line below each post card
        Divider(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          height: 1,
          thickness: 0.5,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildLinkPreview(BuildContext context, bool isDark) {
    if (post.linkUrl == null || post.linkUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    String domain = '';
    try {
      final uri = Uri.parse(post.linkUrl!);
      domain = uri.host;
    } catch (_) {
      domain = post.linkUrl!;
    }
    if (domain.startsWith('www.')) {
      domain = domain.substring(4);
    }

    return GestureDetector(
      onTap: () async {
        try {
          final uri = Uri.parse(post.linkUrl!);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          debugPrint('Error launching url: $e');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.link_rounded,
                size: 16,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.linkTitle ?? domain,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    domain,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 12,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollWidget(BuildContext context, bool isDark) {
    final poll = post.poll;
    if (poll == null) return const SizedBox.shrink();

    final bool hasVoted = poll.userVotedIndex != null;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.015),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            poll.question,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(poll.options.length, (index) {
            final optionText = poll.options[index];
            final votes = poll.optionVotes[index];
            final total = poll.totalVotes;
            final double percent = total > 0 ? (votes / total) : 0.0;
            final int percentInt = (percent * 100).round();
            final bool isMyVote = poll.userVotedIndex == index;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  if (!hasVoted) {
                    Provider.of<SocialService>(
                      context,
                      listen: false,
                    ).voteInPoll(post.id, index);
                  }
                },
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (hasVoted && isMyVote)
                          ? AppTheme.primary.withValues(alpha: 0.3)
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.04)),
                      width: 0.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Progress bar background layer
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutCubic,
                                width: hasVoted
                                    ? constraints.maxWidth * percent
                                    : 0.0,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: hasVoted
                                      ? (isMyVote
                                            ? AppTheme.primary.withValues(
                                                alpha: isDark ? 0.18 : 0.12,
                                              )
                                            : (isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.05,
                                                    )
                                                  : Colors.black.withValues(
                                                      alpha: 0.035,
                                                    )))
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Text and details layer
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    if (hasVoted && isMyVote) ...[
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 14,
                                        color: AppTheme.primary,
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Expanded(
                                      child: Text(
                                        optionText,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: (hasVoted && isMyVote)
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (hasVoted)
                                Text(
                                  '$percentInt%',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isMyVote
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isMyVote
                                        ? AppTheme.primary
                                        : (isDark
                                              ? Colors.white60
                                              : Colors.black54),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          Text(
            _pluralizeVotes(poll.totalVotes),
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  String _pluralizeVotes(int count) {
    int n = count % 100;
    if (n >= 11 && n <= 19) {
      return '$count голосов';
    }
    n = count % 10;
    if (n == 1) {
      return '$count голос';
    }
    if (n >= 2 && n <= 4) {
      return '$count голоса';
    }
    return '$count голосов';
  }

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
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
}

// ─── Small action button ──────────────────────────────────────────────
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

// ─── Animated like button with scale bounce ────────────────────────
class _AnimatedLikeButton extends StatefulWidget {
  final bool isLiked;
  final int likesCount;
  final bool isDark;
  final VoidCallback onTap;

  const _AnimatedLikeButton({
    required this.isLiked,
    required this.likesCount,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<_AnimatedLikeButton>
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
