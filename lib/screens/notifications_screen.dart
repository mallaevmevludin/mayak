import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/notification_model.dart';
import '../services/social_service.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/user_avatar.dart';
import 'comments_screen.dart';
import 'user_profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<NotificationModel> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final social = Provider.of<SocialService>(context, listen: false);
    final items = await social.fetchNotifications();
    // Открыли экран — помечаем прочитанными.
    await social.markNotificationsRead();
    if (!mounted) return;
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return Icons.favorite_rounded;
      case NotificationType.comment:
        return Icons.mode_comment_rounded;
      case NotificationType.follow:
        return Icons.person_add_rounded;
      case NotificationType.mention:
        return Icons.alternate_email_rounded;
      case NotificationType.unknown:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return AppTheme.error;
      case NotificationType.comment:
        return AppTheme.primary;
      case NotificationType.follow:
        return AppTheme.success;
      case NotificationType.mention:
        return AppTheme.warning;
      case NotificationType.unknown:
        return AppTheme.primary;
    }
  }

  Future<void> _onTap(NotificationModel n) async {
    if (n.type == NotificationType.follow) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfileScreen(userId: n.actorId),
        ),
      );
      return;
    }
    if (n.postId != null) {
      final social = Provider.of<SocialService>(context, listen: false);
      final navigator = Navigator.of(context);
      final post = await social.fetchPost(n.postId!);
      if (!mounted || post == null) return;
      navigator.push(
        MaterialPageRoute(
          builder: (_) => CommentsScreen(postId: post.id, post: post),
        ),
      );
    }
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inDays > 7) return '${(d.inDays / 7).floor()} нед.';
    if (d.inDays > 0) return '${d.inDays} дн.';
    if (d.inHours > 0) return '${d.inHours} ч.';
    if (d.inMinutes > 0) return '${d.inMinutes} мин.';
    return 'только что';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBg,
      appBar: AppBar(
        title: const Text(
          'Уведомления',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary,
                ),
              )
            : _items.isEmpty
                ? const AppEmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: 'Пока нет уведомлений',
                    subtitle:
                        'Здесь появятся лайки, комментарии и новые подписчики.',
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.bottomNavClearance,
                    ),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) =>
                        _buildTile(_items[index]),
                  ),
      ),
    );
  }

  Widget _buildTile(NotificationModel n) {
    return InkWell(
      onTap: () => _onTap(n),
      borderRadius: AppRadius.cardR,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatar.fromUsername(
                  username: n.actorUsername,
                  avatarUrl: n.actorAvatarUrl,
                  size: 48,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _colorFor(n.type),
                      shape: BoxShape.circle,
                      border: Border.all(color: context.appBg, width: 2),
                    ),
                    child: Icon(_iconFor(n.type), size: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.3,
                    color: context.appTextPrimary,
                  ),
                  children: [
                    TextSpan(
                      text: n.actorName.isNotEmpty
                          ? n.actorName
                          : '@${n.actorUsername}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: n.actionText,
                      style: TextStyle(color: context.appTextSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _timeAgo(n.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: context.appTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
