import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/post_card.dart';

class ProfilePostsTab extends StatelessWidget {
  final List<PostModel> posts;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final Function(PostModel post) onDeletePost;
  final Function(PostModel post) onLikeTogglePost;

  const ProfilePostsTab({
    super.key,
    required this.posts,
    required this.isLoading,
    required this.onRefresh,
    required this.onDeletePost,
    required this.onLikeTogglePost,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primary,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 100),
        children: [
          _buildPostsList(isDark),
        ],
      ),
    );
  }

  Widget _buildPostsList(bool isDark) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primary,
          ),
        ),
      );
    }

    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
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
          onDelete: () => onDeletePost(post),
          onLikeToggle: () => onLikeTogglePost(post),
        );
      }).toList(),
    );
  }
}
