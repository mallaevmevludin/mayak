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

  static final RegExp _mentionRegex = RegExp(r'@(\w+)');

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

    for (final match in _mentionRegex.allMatches(text)) {
      // Text before the mention
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: defaultStyle,
          ),
        );
      }

      final mentionText = match.group(0)!; // e.g., "@username"
      final username = match.group(1)!; // e.g., "username"

      spans.add(
        TextSpan(
          text: mentionText,
          style: defaultStyle.copyWith(
            color: const Color(0xFF007AFF),
            fontWeight: FontWeight.w600,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _navigateToProfile(context, username),
        ),
      );

      lastEnd = match.end;
    }

    // Remaining text after last mention
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: defaultStyle));
    }

    // No mentions found — return simple text
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: defaultStyle));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
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
