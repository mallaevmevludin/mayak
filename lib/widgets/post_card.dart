import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../screens/comments_screen.dart';
import '../theme/app_dimens.dart';
import 'app_card.dart';
import 'mention_text_builder.dart';
import 'multi_image_slider.dart';
import 'post_card/post_header.dart';
import 'post_card/post_link_preview.dart';
import 'post_card/post_poll.dart';
import 'post_card/post_actions_bar.dart';

import 'post_job_card.dart';

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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Avatar + Name + @username + actions ──
            PostHeader(
              post: post,
              useHero: useHero,
              onDelete: onDelete,
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Post content with @mention support ──
            MentionTextBuilder(
              text: post.content,
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: context.appTextPrimary,
                letterSpacing: -0.2,
              ),
            ),

            // Post Image (Progressive Loader & Slider)
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
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
            PostLinkPreview(post: post),

            // Poll Widget
            PostPoll(post: post),

            // Linked Job Card
            if (post.job != null) PostJobCard(job: post.job!),

            const SizedBox(height: AppSpacing.md),

            // ── Action bar ──
            PostActionsBar(
              post: post,
              isClickable: isClickable,
              onLikeToggle: onLikeToggle,
            ),
          ],
        ),
      ),
    );
  }
}
