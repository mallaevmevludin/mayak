import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/post_model.dart';
import '../../../theme/app_theme.dart';

class PostLinkPreview extends StatelessWidget {
  final PostModel post;

  const PostLinkPreview({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    if (post.linkUrl == null || post.linkUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
}
