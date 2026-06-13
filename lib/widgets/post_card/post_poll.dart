import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/post_model.dart';
import '../../../services/social_service.dart';
import '../../../theme/app_theme.dart';

class PostPoll extends StatelessWidget {
  final PostModel post;

  const PostPoll({
    super.key,
    required this.post,
  });

  String _pluralizeVotes(int count) {
    int n = count % 100;
    if (n >= 11 && n <= 19) {
      return '$count голосов';
    }
    n = count % 10;
    if (n == 1) {
      return '$count голос';
    }
    if (n >= 2 && n <= 4) {
      return '$count голоса';
    }
    return '$count голосов';
  }

  @override
  Widget build(BuildContext context) {
    final poll = post.poll;
    if (poll == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool hasVoted = poll.userVotedIndex != null;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.015),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            poll.question,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(poll.options.length, (index) {
            final optionText = poll.options[index];
            final votes = poll.optionVotes[index];
            final total = poll.totalVotes;
            final double percent = total > 0 ? (votes / total) : 0.0;
            final int percentInt = (percent * 100).round();
            final bool isMyVote = poll.userVotedIndex == index;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  if (!hasVoted) {
                    Provider.of<SocialService>(
                      context,
                      listen: false,
                    ).voteInPoll(post.id, index);
                  }
                },
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (hasVoted && isMyVote)
                          ? AppTheme.primary.withValues(alpha: 0.3)
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.04)),
                      width: 0.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Progress bar background layer
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutCubic,
                                width: hasVoted
                                    ? constraints.maxWidth * percent
                                    : 0.0,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: hasVoted
                                      ? (isMyVote
                                            ? AppTheme.primary.withValues(
                                                alpha: isDark ? 0.18 : 0.12,
                                              )
                                            : (isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.05,
                                                    )
                                                  : Colors.black.withValues(
                                                      alpha: 0.035,
                                                    )))
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Text and details layer
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    if (hasVoted && isMyVote) ...[
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 14,
                                        color: AppTheme.primary,
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Expanded(
                                      child: Text(
                                        optionText,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: (hasVoted && isMyVote)
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (hasVoted)
                                Text(
                                  '$percentInt%',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isMyVote
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isMyVote
                                        ? AppTheme.primary
                                        : (isDark
                                              ? Colors.white60
                                              : Colors.black54),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          Text(
            _pluralizeVotes(poll.totalVotes),
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}
