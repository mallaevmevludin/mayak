import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../services/social_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme.dart';
import '../widgets/post_card.dart';
import 'chat_screen.dart';
import '../widgets/user_avatar.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String? heroTag;

  const UserProfileScreen({super.key, required this.userId, this.heroTag});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  UserModel? _user;
  List<PostModel> _userPosts = [];
  Map<String, int> _stats = {'posts': 0, 'likes': 0};
  Map<String, int> _followCounts = {'followers': 0, 'following': 0};
  bool _isFollowing = false;
  bool _followBusy = false;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final socialService = Provider.of<SocialService>(context, listen: false);
    final me = Provider.of<AuthService>(context, listen: false).currentUser;
    final isOwn = me?.id == widget.userId;

    final results = await Future.wait([
      socialService.fetchUserProfile(widget.userId),
      socialService.fetchUserPosts(widget.userId),
      socialService.fetchUserStats(widget.userId),
      socialService.fetchFollowCounts(widget.userId),
      if (!isOwn) socialService.isFollowing(widget.userId),
    ]);

    if (mounted) {
      setState(() {
        _user = results[0] as UserModel?;
        _userPosts = results[1] as List<PostModel>;
        _stats = results[2] as Map<String, int>;
        _followCounts = results[3] as Map<String, int>;
        _isFollowing = isOwn ? false : results[4] as bool;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_followBusy) return;
    final social = Provider.of<SocialService>(context, listen: false);

    // Оптимистично переключаем.
    setState(() {
      _followBusy = true;
      _isFollowing = !_isFollowing;
      _followCounts['followers'] =
          (_followCounts['followers'] ?? 0) + (_isFollowing ? 1 : -1);
    });

    final ok = _isFollowing
        ? await social.followUser(widget.userId)
        : await social.unfollowUser(widget.userId);

    if (!mounted) return;
    setState(() {
      if (!ok) {
        // Откат при ошибке.
        _isFollowing = !_isFollowing;
        _followCounts['followers'] =
            (_followCounts['followers'] ?? 0) + (_isFollowing ? 1 : -1);
      }
      _followBusy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = Provider.of<AuthService>(
      context,
      listen: false,
    ).currentUser;
    final isOwnProfile = currentUser?.id == widget.userId;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primary,
              ),
            )
          : _user == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 48,
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                  const SizedBox(height: 12),
                  const Text('Пользователь не найден'),
                ],
              ),
            )
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    floating: false,
                    pinned: true,
                    backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    leading: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppTheme.cardBorderDark : AppTheme.cardBorderLight,
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.25 : 0.04,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '@${_user!.username}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    centerTitle: true,
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeaderSection(isDark, isOwnProfile, theme),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
                      tabBar: TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: 'Посты'),
                          Tab(text: 'Инфо'),
                        ],
                        labelColor: Colors.white,
                        unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                        indicator: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostsTab(isDark),
                  _buildInfoTab(isDark, isOwnProfile, theme),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderSection(bool isDark, bool isOwnProfile, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Hero(
              tag: widget.heroTag ?? 'avatar-profile-${widget.userId}',
              child: UserAvatar.fromName(
                avatarUrl: _user!.avatarUrl,
                firstName: _user!.firstName,
                lastName: _user!.lastName,
                size: 92,
                showBorder: true,
                borderWidth: 1.5,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildHeaderStat('${_stats['posts'] ?? 0}', 'Посты'),
                  _buildHeaderStat(
                    '${_followCounts['followers'] ?? 0}',
                    'Подписчики',
                  ),
                  _buildHeaderStat(
                    '${_followCounts['following'] ?? 0}',
                    'Подписки',
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Flexible(
              child: Text(
                '${_user!.firstName} ${_user!.lastName}'.trim(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_user!.isVerified) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.verified_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '@${_user!.username}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (_user!.biography != null && _user!.biography!.trim().isNotEmpty) ...[
          Text(
            _user!.biography!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
        ] else if (isOwnProfile) ...[
          Text(
            'Описание профиля не заполнено. Перейдите во вкладку Профиль, чтобы отредактировать.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white30 : Colors.black38,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (!isOwnProfile) _buildActionButtons(isDark),
      ],
    );
  }

  Future<void> _openChat() async {
    final chat = Provider.of<ChatService>(context, listen: false);
    final navigator = Navigator.of(context);
    final convId = await chat.openDirectConversation(widget.userId);
    if (!mounted || convId == null || _user == null) return;
    navigator.push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: convId,
          otherName: '${_user!.firstName} ${_user!.lastName}'.trim(),
          otherUsername: _user!.username,
          otherAvatarUrl: _user!.avatarUrl,
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    final following = _isFollowing;
    return Row(
      children: [
        Expanded(
          child: following
              ? OutlinedButton(
                  onPressed: _followBusy ? null : _toggleFollow,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.appTextPrimary,
                    side: BorderSide(color: context.appCardBorder, width: 1),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.controlR,
                    ),
                  ),
                  child: const Text('Вы подписаны'),
                )
              : ElevatedButton(
                  onPressed: _followBusy ? null : _toggleFollow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.controlR,
                    ),
                  ),
                  child: const Text('Подписаться'),
                ),
        ),
        const SizedBox(width: AppSpacing.sm),
        OutlinedButton(
          onPressed: _openChat,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primary,
            side: BorderSide(color: context.appCardBorder, width: 1),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.controlR),
          ),
          child: const Icon(Icons.mode_comment_outlined, size: 20),
        ),
      ],
    );
  }

  Widget _buildHeaderStat(String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPostsTab(bool isDark) {
    final displayPosts = _userPosts;
    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: AppTheme.primary,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 100),
        children: [
          _buildPostsList(isDark, displayPosts),
        ],
      ),
    );
  }

  Widget _buildInfoTab(bool isDark, bool isOwnProfile, ThemeData theme) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Text(
          'О себе (Биография)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              (_user!.biography != null && _user!.biography!.trim().isNotEmpty)
                  ? _user!.biography!
                  : (isOwnProfile
                      ? 'Биография пока не заполнена. Нажмите редактировать, чтобы добавить информацию.'
                      : 'Биография пока не добавлена.'),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: (_user!.biography == null || _user!.biography!.trim().isEmpty)
                    ? FontStyle.italic
                    : FontStyle.normal,
                color: (_user!.biography == null || _user!.biography!.trim().isEmpty)
                    ? (isDark ? Colors.white30 : Colors.black38)
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Интересы',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        if (_user!.interests.isEmpty)
          Card(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                width: 0.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Интересы пока не добавлены.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _user!.interests.map((interest) {
              return Chip(
                label: Text(
                  interest,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide.none,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildPostsList(bool isDark, List<PostModel> posts) {
    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.article_outlined,
                size: 40,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              const SizedBox(height: 10),
              Text(
                'Нет публикаций',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: posts.map((post) {
        return PostCard(
          post: post,
          useHero: false,
          onDelete: () {
            setState(() {
              _userPosts.removeWhere((p) => p.id == post.id);
            });
          },
          onLikeToggle: () {
            setState(() {
              final idx = _userPosts.indexWhere((p) => p.id == post.id);
              if (idx != -1) {
                final p = _userPosts[idx];
                final wasLiked = p.isLikedByMe;
                _userPosts[idx] = p.copyWith(
                  isLikedByMe: !wasLiked,
                  likesCount: wasLiked ? p.likesCount - 1 : p.likesCount + 1,
                );
              }
            });
          },
        );
      }).toList(),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate({required this.tabBar, required this.backgroundColor});

  @override
  double get minExtent => tabBar.preferredSize.height + 16;
  @override
  double get maxExtent => tabBar.preferredSize.height + 16;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: backgroundColor.withValues(alpha: 0.8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            height: tabBar.preferredSize.height,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardBorderDark : AppTheme.cardBorderLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: tabBar,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return oldDelegate.tabBar != tabBar || oldDelegate.backgroundColor != backgroundColor;
  }
}
