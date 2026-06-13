import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/social_service.dart';
import '../services/auth_service.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/post_card.dart';
import '../widgets/sliding_segmented_control.dart';
import '../widgets/skeleton_item.dart';
import 'create_post_sheet.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  int _selectedTab = 0; // 0 = Лента, 1 = Популярное
  final ScrollController _scrollController = ScrollController();
  double _appBarOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SocialService>(context, listen: false).fetchPosts(isRefresh: true);
    });
  }

  void _onScroll() {
    if (!mounted) return;
    final offset = _scrollController.offset;
    final newOpacity = (offset / 60.0).clamp(0.0, 1.0);
    if (newOpacity != _appBarOpacity) {
      setState(() {
        _appBarOpacity = newOpacity;
      });
    }

    // Trigger pagination when reaching within 200 pixels of the bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final socialService = Provider.of<SocialService>(context, listen: false);
      if (!socialService.isLoading &&
          !socialService.isLoadingMore &&
          socialService.hasMore) {
        socialService.fetchPosts(isRefresh: false);
      }
    }
  }

  Future<void> _refresh() async {
    await Provider.of<SocialService>(context, listen: false).fetchPosts(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final socialService = Provider.of<SocialService>(context);

    // Sort posts by tab: 0 = recent, 1 = most liked
    List posts = List.from(socialService.posts);
    if (_selectedTab == 1) {
      posts.sort((a, b) => b.likesCount.compareTo(a.likesCount));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.primary,
        displacement: 60,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ── iOS-style Large Title AppBar ──
            SliverAppBar(
              expandedHeight: 100,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  bottom: AppSpacing.md,
                ),
                title: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: AppRadius.controlR,
                    boxShadow: AppShadows.soft(isDark),
                  ),
                  child: Text(
                    'Сообщество',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.appTextPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: AppHeaderAction(
                    icon: Icons.add_rounded,
                    onTap: _showCreatePostDialog,
                  ),
                ),
              ],
            ),

            // ── Segment control (Лента / Популярное) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                child: SlidingSegmentedControl(
                  children: const ['Лента', 'Популярное'],
                  selectedIndex: _selectedTab,
                  onValueChanged: (index) {
                    setState(() {
                      _selectedTab = index;
                    });
                  },
                ),
              ),
            ),

            // ── Selected Hashtag Indicator ──
            if (socialService.selectedTag != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs + 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(
                            alpha: AppAlpha.fillMuted,
                          ),
                          borderRadius: AppRadius.chipR,
                          border: Border.all(
                            color: AppTheme.primary.withValues(
                              alpha: AppAlpha.fillStrong,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.tag_rounded,
                              size: 16,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '#${socialService.selectedTag}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                socialService.setSelectedTag(null);
                              },
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Loading indicator while refreshing (posts already visible) ──
            if (socialService.isLoading && posts.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: const LinearProgressIndicator(
                      minHeight: 2,
                      color: AppTheme.primary,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
              ),

            // ── Posts ──
            if (socialService.isLoading && socialService.posts.isEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: _buildPostSkeleton(isDark),
                  );
                }, childCount: 3),
              )
            else if (posts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.forum_outlined,
                        size: 56,
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Постов пока нет',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Напишите что-нибудь первым!',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final post = posts[index];
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      0,
                      AppSpacing.sm,
                      index == posts.length - 1 ? AppSpacing.xxl : 0,
                    ),
                    child: PostCard(post: post),
                  );
                }, childCount: posts.length),
              ),

            // Bottom loading spinner or spacing for pagination to clear floating nav bar
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  top: socialService.isLoadingMore ? AppSpacing.lg : 0.0,
                  bottom: AppSpacing.bottomNavClearance,
                ),
                child: socialService.isLoadingMore
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostSkeleton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SkeletonItem(
                width: 40,
                height: 40,
                borderRadius: 20,
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonItem(
                    width: 120,
                    height: 14,
                    borderRadius: 4,
                  ),
                  SizedBox(height: 6),
                  SkeletonItem(
                    width: 80,
                    height: 10,
                    borderRadius: 3,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const SkeletonItem(
            width: double.infinity,
            height: 12,
            borderRadius: 3,
          ),
          const SizedBox(height: 8),
          const SkeletonItem(
            width: double.infinity,
            height: 12,
            borderRadius: 3,
          ),
          const SizedBox(height: 8),
          const SkeletonItem(
            width: 180,
            height: 12,
            borderRadius: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const SkeletonItem(
                width: 50,
                height: 24,
                borderRadius: 12,
              ),
              const SizedBox(width: 20),
              const SkeletonItem(
                width: 50,
                height: 24,
                borderRadius: 12,
              ),
              const Spacer(),
              SkeletonItem(
                width: 70,
                height: 12,
                borderRadius: 3,
                key: UniqueKey(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreatePostDialog() {
    final currentUser = Provider.of<AuthService>(
      context,
      listen: false,
    ).currentUser;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CreatePostSheet(currentUser: currentUser);
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
