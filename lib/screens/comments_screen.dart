import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../services/social_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../screens/user_profile_screen.dart';
import '../widgets/mention_text_builder.dart';
import '../widgets/post_card.dart';
import '../widgets/user_avatar.dart';

class CommentsScreen extends StatefulWidget {
  final int postId;
  final PostModel? post;

  const CommentsScreen({super.key, required this.postId, this.post});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  CommentModel? _replyingTo;
  PostModel? _post;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadData();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _commentController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadData() async {
    final socialService = Provider.of<SocialService>(context, listen: false);
    
    if (_post == null) {
      final index = socialService.posts.indexWhere((p) => p.id == widget.postId);
      if (index != -1) {
        _post = socialService.posts[index];
      } else {
        final fetchedPost = await socialService.fetchPost(widget.postId);
        if (mounted) {
          setState(() {
            _post = fetchedPost;
          });
        }
      }
    }

    final comments = await socialService.fetchComments(widget.postId);
    if (mounted) {
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitComment() async {
    final rawText = _commentController.text.trim();
    if (rawText.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    String finalText = rawText;
    if (_replyingTo != null) {
      finalText = '@${_replyingTo!.userUsername} $rawText';
    }

    final socialService = Provider.of<SocialService>(context, listen: false);
    final newComment = await socialService.addComment(widget.postId, finalText);
    if (newComment != null && mounted) {
      setState(() {
        _comments.add(newComment);
        _commentController.clear();
        _replyingTo = null;
        _isSending = false;
        if (_post != null) {
          _post = _post!.copyWith(commentsCount: _post!.commentsCount + 1);
        }
      });
      _focusNode.unfocus();
    } else if (mounted) {
      setState(() => _isSending = false);
    }
  }

  void _toggleLikeComment(int commentId) {
    final idx = _comments.indexWhere((c) => c.id == commentId);
    if (idx == -1) return;

    final comment = _comments[idx];
    final wasLiked = comment.isLikedByMe;
    final newLikes = wasLiked ? comment.likesCount - 1 : comment.likesCount + 1;

    // Optimistic update
    setState(() {
      _comments[idx] = comment.copyWith(
        isLikedByMe: !wasLiked,
        likesCount: newLikes < 0 ? 0 : newLikes,
      );
    });

    // Persist to Supabase
    final socialService = Provider.of<SocialService>(context, listen: false);
    socialService
        .likeComment(widget.postId, commentId, currentlyLiked: wasLiked)
        .then((success) {
          if (!success && mounted) {
            // Revert on error
            setState(() {
              _comments[idx] = comment;
            });
          }
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

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: Stack(
        children: [
          // 1. Full-screen scrollable comments list
          Positioned.fill(
            child: _post == null
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  )
                : Consumer<SocialService>(
                    builder: (context, socialService, child) {
                      final postFromService = socialService.posts.firstWhere(
                        (p) => p.id == widget.postId,
                        orElse: () => _post!,
                      );
                      return ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 70, // offset for floating header
                          bottom: MediaQuery.of(context).padding.bottom + 90, // offset for floating input bar
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _isLoading
                            ? 2
                            : _comments.isEmpty
                                ? 2
                                : 1 + _comments.length,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: PostCard(
                                post: postFromService,
                                isClickable: false,
                                onLikeToggle: () {
                                  setState(() {
                                    final isLiked = _post!.isLikedByMe;
                                    _post = _post!.copyWith(
                                      isLikedByMe: !isLiked,
                                      likesCount: isLiked ? _post!.likesCount - 1 : _post!.likesCount + 1,
                                    );
                                  });
                                },
                              ),
                            );
                          }

                          Widget innerChild;

                          if (_isLoading) {
                            innerChild = const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primary,
                                ),
                              ),
                            );
                          } else if (_comments.isEmpty) {
                            innerChild = Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 48,
                                    color: isDark ? Colors.white12 : Colors.black12,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Пока нет комментариев',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppTheme.textSecondaryDark
                                          : AppTheme.textSecondaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Будьте первым!',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.white24 : Colors.black26,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            final comment = _comments[index - 1];
                            final content = comment.content;
                            bool isReply = false;
                            if (content.startsWith('@')) {
                              final firstSpace = content.indexOf(' ');
                              if (firstSpace != -1) {
                                final possibleUsername = content.substring(
                                  1,
                                  firstSpace,
                                );
                                if (RegExp(
                                  r'^[a-zA-Z0-9_]+$',
                                ).hasMatch(possibleUsername)) {
                                  isReply = true;
                                }
                              }
                            }

                            innerChild = Padding(
                              padding: EdgeInsets.only(
                                left: isReply ? 40.0 : 16.0,
                                right: 16.0,
                                bottom: 16.0,
                              ),
                              child: _CommentBubbleTile(
                                comment: comment,
                                isDark: isDark,
                                isMyComment: currentUser != null &&
                                    currentUser.id == comment.userId,
                                isLiked: comment.isLikedByMe,
                                likesCount: comment.likesCount,
                                onDelete: () => _deleteComment(comment),
                                onProfileTap: () =>
                                    _openProfile(context, comment.userId),
                                onLikeTap: () => _toggleLikeComment(comment.id),
                                onReplyTap: () {
                                  setState(() {
                                    _replyingTo = comment;
                                  });
                                  _focusNode.requestFocus();
                                },
                              ),
                            );
                          }

                          return innerChild;
                        },
                      );
                    },
                  ),
          ),

          // 2. Floating Top Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top + 56,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              color: Colors.transparent,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : Colors.white,
                          shape: BoxShape.circle,
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
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(12),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Комментарии',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!_isLoading)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_comments.length}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Bottom Input Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reply bar above field if replying to someone
                  if (_replyingTo != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 74,
                        right: 72,
                        bottom: 6,
                      ),
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(19),
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
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.reply_rounded,
                              color: AppTheme.primary,
                              size: 15,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ответ @${_replyingTo!.userUsername}: ${_replyingTo!.content.startsWith('@') ? _replyingTo!.content.substring(_replyingTo!.content.indexOf(' ') + 1).trim() : _replyingTo!.content}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _replyingTo = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.black12,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 11,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Input area
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      (MediaQuery.of(context).padding.bottom +
                              8.0 -
                              MediaQuery.of(context).viewInsets.bottom)
                          .clamp(8.0, 100.0),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        UserAvatar.fromUsername(
                          username: currentUser?.username ?? 'U',
                          avatarUrl: currentUser?.avatarUrl,
                          size: 48,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.darkSurface
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
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
                            child: TextField(
                              controller: _commentController,
                              focusNode: _focusNode,
                              textAlignVertical: TextAlignVertical.center,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                filled: false,
                                hintText: _replyingTo != null
                                    ? 'Ваш ответ...'
                                    : 'Комментировать...',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight,
                                  fontSize: 14,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 15,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              onSubmitted: (_) => _submitComment(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _isSending ? null : _submitComment,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primary.withValues(
                                alpha: _isSending ? 0.4 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(
                                    alpha: isDark ? 0.35 : 0.2,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _isSending
                                ? const Padding(
                                    padding: EdgeInsets.all(13),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.arrow_upward_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(CommentModel comment) async {
    bool isDeleting = false;

    final success = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return CupertinoAlertDialog(
            title: const Text('Удалить комментарий?'),
            content: const Text('Вы уверены, что хотите удалить этот комментарий?'),
            actions: [
              CupertinoDialogAction(
                onPressed: isDeleting ? null : () => Navigator.pop(dialogContext, false),
                child: const Text('Отмена'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialogState(() => isDeleting = true);
                        final deleteResult = await Provider.of<SocialService>(
                          context,
                          listen: false,
                        ).deleteComment(widget.postId, comment.id);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, deleteResult);
                        }
                      },
                child: isDeleting
                    ? const CupertinoActivityIndicator()
                    : const Text('Удалить'),
              ),
            ],
          );
        },
      ),
    );

    if (success == true && mounted) {
      setState(() {
        _comments.removeWhere((c) => c.id == comment.id);
        if (_post != null && _post!.commentsCount > 0) {
          _post = _post!.copyWith(commentsCount: _post!.commentsCount - 1);
        }
      });
    }
  }

  void _openProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, _) =>
            UserProfileScreen(userId: userId),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

// ─── Beautiful comment bubble tile (Apple Messages style) ─────────────────────────
class _CommentBubbleTile extends StatefulWidget {
  final CommentModel comment;
  final bool isDark;
  final bool isMyComment;
  final bool isLiked;
  final int likesCount;
  final VoidCallback onDelete;
  final VoidCallback onProfileTap;
  final VoidCallback onLikeTap;
  final VoidCallback onReplyTap;

  const _CommentBubbleTile({
    required this.comment,
    required this.isDark,
    required this.isMyComment,
    required this.isLiked,
    required this.likesCount,
    required this.onDelete,
    required this.onProfileTap,
    required this.onLikeTap,
    required this.onReplyTap,
  });

  @override
  State<_CommentBubbleTile> createState() => _CommentBubbleTileState();
}

class _CommentBubbleTileState extends State<_CommentBubbleTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeController;
  late Animation<double> _likeScaleAnimation;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _likeScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.9), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _likeController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  void _showActionsSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              widget.onReplyTap();
            },
            child: const Text('Ответить'),
          ),
          if (widget.isMyComment)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                widget.onDelete();
              },
              child: const Text('Удалить'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Отмена'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textSecondaryColor = widget.isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondaryLight;

    final content = widget.comment.content;
    String? replyingToUsername;
    String displayContent = content;

    if (content.startsWith('@')) {
      final firstSpace = content.indexOf(' ');
      if (firstSpace != -1) {
        final possibleUsername = content.substring(1, firstSpace);
        if (RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(possibleUsername)) {
          replyingToUsername = possibleUsername;
          displayContent = content.substring(firstSpace + 1);
        }
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar with thread line support
        Stack(
          clipBehavior: Clip.none,
          children: [
            if (replyingToUsername != null)
              Positioned(
                left: -8,
                width: 24,
                top: -24,
                height: 40,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: ThreadLinePainter(isDark: widget.isDark),
                  ),
                ),
              ),
            GestureDetector(
              onTap: widget.onProfileTap,
              child: UserAvatar.fromUsername(
                username: widget.comment.userUsername,
                avatarUrl: widget.comment.userAvatarUrl,
                size: 32,
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bubble with comment content
              Dismissible(
                key: ValueKey('swipe-${widget.comment.id}'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    widget.onReplyTap();
                  }
                  return false; // Prevent dismiss, slide back
                },
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(
                    Icons.reply_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                background: const SizedBox.shrink(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFF6F6F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + Time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: widget.onProfileTap,
                                child: Text(
                                  '${widget.comment.userFirstName} ${widget.comment.userLastName}'
                                      .trim(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: widget.isDark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              if (widget.comment.userIsVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  color: AppTheme.primary,
                                  size: 14,
                                ),
                              ],
                              const SizedBox(width: 6),
                              Text(
                                _formatRelativeTime(widget.comment.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => _showActionsSheet(context),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 8,
                                bottom: 2,
                              ),
                              child: Icon(
                                Icons.more_horiz_rounded,
                                size: 20,
                                color: textSecondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Replying to indicator in X.com style
                      if (replyingToUsername != null) ...[
                        Row(
                          children: [
                            Text(
                              'В ответ ',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondaryColor.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                            Text(
                              '@$replyingToUsername',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],

                      // Comment text
                      MentionTextBuilder(
                        text: displayContent,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.35,
                          color: widget.isDark
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.black.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Actions below Bubble: Like
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    // Like button
                    GestureDetector(
                      onTap: () {
                        _likeController.forward(from: 0.0);
                        widget.onLikeTap();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          ScaleTransition(
                            scale: _likeScaleAnimation,
                            child: Icon(
                              widget.isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 16,
                              color: widget.isLiked
                                  ? const Color(0xFFFF2D55)
                                  : textSecondaryColor,
                            ),
                          ),
                          if (widget.likesCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${widget.likesCount}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: widget.isLiked
                                    ? const Color(0xFFFF2D55)
                                    : textSecondaryColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt.toLocal());

    if (diff.inMinutes < 1) return 'сейчас';
    if (diff.inMinutes < 60) return '${diff.inMinutes}м';
    if (diff.inHours < 24) return '${diff.inHours}ч';
    if (diff.inDays < 7) return '${diff.inDays}д';

    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}';
  }
}

// ─── Custom Painter for Thread Connector Lines ────────────────────────────────────
class ThreadLinePainter extends CustomPainter {
  final bool isDark;

  ThreadLinePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Start at top-left (center of parent column at separator boundary)
    path.moveTo(0, 0);
    // Go straight down to the level of child avatar center (y = size.height)
    path.lineTo(0, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
