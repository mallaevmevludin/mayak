import 'package:flutter/material.dart';
import '../models/job_model.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'pill_badge.dart';
import 'multi_image_slider.dart';
import 'user_avatar.dart';

class JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
  });

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} лет назад';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} мес. назад';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBudget = job.budget != null && job.budget!.trim().isNotEmpty;
    final budgetColor = hasBudget ? AppTheme.success : context.appTextSecondary;

    return AppCard(
      onTap: onTap,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header: User Profile & Budget ───
            Row(
              children: [
                UserAvatar(
                  avatarUrl: job.userAvatarUrl,
                  fallbackInitial: job.userEmojiAvatar?.isNotEmpty == true
                      ? job.userEmojiAvatar!
                      : (job.userFirstName.isNotEmpty
                          ? job.userFirstName[0].toUpperCase()
                          : '👤'),
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         children: [
                           Flexible(
                             child: Text(
                               '${job.userFirstName} ${job.userLastName}'.trim().isNotEmpty
                                   ? '${job.userFirstName} ${job.userLastName}'
                                   : '@${job.userUsername}',
                               style: TextStyle(
                                 fontSize: 13,
                                 fontWeight: FontWeight.w600,
                                 color: context.appTextPrimary,
                               ),
                               overflow: TextOverflow.ellipsis,
                             ),
                           ),
                           if (job.userIsVerified) ...[
                             const SizedBox(width: AppSpacing.xs),
                             const Icon(
                               Icons.verified_rounded,
                               size: 14,
                               color: AppTheme.primary,
                             ),
                           ],
                         ],
                       ),
                       const SizedBox(height: 2),
                       Text(
                         '${_getTimeAgo(job.createdAt)} • ${job.category == JobCategory.freelance ? 'Удаленно' : job.formattedLocation}',
                         style: TextStyle(
                           fontSize: 11,
                           color: context.appTextSecondary,
                         ),
                       ),
                     ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Budget text (no pill container, elegant and bold)
                Text(
                  job.formattedBudget,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: budgetColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ─── Post Images ───
            if (job.imageUrls.isNotEmpty) ...[
              MultiImageSlider(
                imageUrls: job.imageUrls,
                aspectRatio: 1.8,
                borderRadius: AppRadius.cardR,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // ─── Employment Badge ───
            PillBadge(emoji: '💼', label: job.workTypeName),
            const SizedBox(height: AppSpacing.md),

            // ─── Title & Description ───
            Text(
              job.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: context.appTextPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            Text(
              job.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: context.appTextSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
    );
  }
}
