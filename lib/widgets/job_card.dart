import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/job_model.dart';
import '../theme/app_theme.dart';
import 'scale_on_tap.dart';
import 'multi_image_slider.dart';

class JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
  });

  Future<void> _launchPhone(BuildContext context, String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Номер телефона не указан')),
      );
      return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching phone: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось совершить вызов: $e')),
      );
    }
  }

  Future<void> _launchTelegram(BuildContext context, String? username) async {
    if (username == null || username.trim().isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telegram аккаунт не указан')),
      );
      return;
    }
    var cleanTg = username.trim();
    if (cleanTg.startsWith('@')) {
      cleanTg = cleanTg.substring(1);
    }
    if (cleanTg.startsWith('http://t.me/') || cleanTg.startsWith('https://t.me/')) {
      // It is already a link
    } else {
      cleanTg = 'https://t.me/$cleanTg';
    }
    final uri = Uri.parse(cleanTg);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching telegram: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть Telegram: $e')),
      );
    }
  }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

    return ScaleOnTap(
      onTap: onTap,
      scaleFactor: 0.97,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (job.imageUrls.isNotEmpty) ...[
              MultiImageSlider(
                imageUrls: job.imageUrls,
                aspectRatio: 1.8,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              const SizedBox(height: 8),
            ],
            // Category Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        job.categoryEmoji,
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        job.categoryName,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Title & Description
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                // Description
                Text(
                  job.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    height: 1.3,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Budget Tag
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Text(
                    '💰 ',
                    style: TextStyle(fontSize: 12),
                  ),
                  Expanded(
                    child: Text(
                      job.formattedBudget,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.success,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Author and Date
            Row(
              children: [
                CircleAvatar(
                  radius: 8,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                  backgroundImage: job.userAvatarUrl != null && job.userAvatarUrl!.isNotEmpty
                      ? NetworkImage(job.userAvatarUrl!)
                      : null,
                  child: job.userAvatarUrl == null || job.userAvatarUrl!.isEmpty
                      ? Text(
                          job.userEmojiAvatar ?? '👤',
                          style: const TextStyle(fontSize: 8),
                        )
                      : null,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '@${job.userUsername}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _getTimeAgo(job.createdAt),
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark
                        ? AppTheme.textSecondaryDark.withValues(alpha: 0.7)
                        : AppTheme.textSecondaryLight.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Contact Buttons Row
            Row(
              children: [
                // Phone Button
                Expanded(
                  child: GestureDetector(
                    onTap: () => _launchPhone(context, job.contactPhone),
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone_rounded, size: 12, color: AppTheme.primary),
                          SizedBox(width: 4),
                          Text(
                            'Звонок',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (job.contactTelegram != null && job.contactTelegram!.trim().isNotEmpty) ...[
                  const SizedBox(width: 6),
                  // Telegram Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _launchTelegram(context, job.contactTelegram),
                      child: Container(
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2EA6DA).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF2EA6DA).withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 12, color: Color(0xFF2EA6DA)),
                            SizedBox(width: 4),
                            Text(
                              'Telegram',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2EA6DA),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
