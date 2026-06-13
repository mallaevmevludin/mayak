import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../screens/user_profile_screen.dart';
import '../services/social_service.dart';
import 'package:provider/provider.dart';

/// Builds a RichText widget that parses @username mentions in text
/// and makes them tappable (navigates to user profile).
class MentionTextBuilder extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const MentionTextBuilder({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
  });

  static final RegExp _regex = RegExp(r'([@#])([a-zA-Z0-9_а-яА-ЯёЁ]+)');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultStyle =
        style ??
        TextStyle(
          fontSize: 15,
          height: 1.4,
          color: isDark ? Colors.white.withValues(alpha: 0.92) : Colors.black87,
        );

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in _regex.allMatches(text)) {
      // Text before the match
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: defaultStyle,
          ),
        );
      }

      final fullMatch = match.group(0)!; // e.g., "@username" or "#tag"
      final prefix = match.group(1)!; // e.g., "@" or "#"
      final value = match.group(2)!; // e.g., "username" or "tag"

      if (prefix == '@') {
        spans.add(
          TextSpan(
            text: fullMatch,
            style: defaultStyle.copyWith(
              color: const Color(0xFF007AFF),
              fontWeight: FontWeight.w600,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _navigateToProfile(context, value),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: fullMatch,
            style: defaultStyle.copyWith(
              color: const Color(0xFF34C759), // Use a nice premium green/blue color for hashtags
              fontWeight: FontWeight.w600,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _onHashtagTap(context, value),
          ),
        );
      }

      lastEnd = match.end;
    }

    // Remaining text after last match
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: defaultStyle));
    }

    // No matches found — return simple text
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: defaultStyle));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }

  void _onHashtagTap(BuildContext context, String tag) {
    Provider.of<SocialService>(context, listen: false).setSelectedTag(tag);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _navigateToProfile(BuildContext context, String username) async {
    final socialService = Provider.of<SocialService>(context, listen: false);
    final results = await socialService.searchUsers(username);

    if (results.isNotEmpty && context.mounted) {
      // Find exact match first, then fallback to first result
      final exactMatch = results.firstWhere(
        (u) => u.username.toLowerCase() == username.toLowerCase(),
        orElse: () => results.first,
      );

      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) =>
              UserProfileScreen(userId: exactMatch.id),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }
}
