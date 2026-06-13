import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import 'jobs/mock_job_repository.dart';
import 'auth_service.dart';
import 'image_upload_service.dart';
import 'supabase_config.dart';
import 'social/social_repository.dart';
import 'social/mock_social_repository.dart';
import 'social/supabase_social_repository.dart';
import 'realtime_service.dart';
import '../utils/app_error.dart';

class SocialService extends ChangeNotifier {
  final AuthService _authService;
  late final SocialRepository _repository;
  RealtimeService? _realtime;

  int _unreadNotifications = 0;
  int get unreadNotifications => _unreadNotifications;

  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedTag;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedTag => _selectedTag;

  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  void setSelectedTag(String? tag) {
    _selectedTag = tag;
    fetchPosts(isRefresh: true);
  }

  bool get _isMockMode => !SupabaseConfig.isConfigured;

  SocialService(this._authService) {
    if (_isMockMode) {
      _repository = MockSocialRepository();
    } else {
      _repository = SupabaseSocialRepository();
      // Живое обновление ленты: при изменениях постов/лайков/комментариев
      // подтягиваем свежие данные (с дебаунсом внутри RealtimeService).
      _realtime = RealtimeService()
        ..subscribeToFeed(onChange: _onRealtimeFeedChange);
    }

    _authService.addListener(_onAuthStatusChanged);
    if (_authService.currentUser != null) {
      fetchPosts(isRefresh: true);
      _initNotifications();
    }
  }

  void _onAuthStatusChanged() {
    if (_authService.currentUser == null) {
      _posts = [];
      _unreadNotifications = 0;
      _realtime?.unsubscribeFromNotifications();
      _safeNotify();
    } else {
      fetchPosts(isRefresh: true);
      _initNotifications();
    }
  }

  /// Подгружает счётчик непрочитанных и подписывается на новые уведомления.
  void _initNotifications() {
    final me = _authService.currentUser;
    if (me == null) return;
    refreshUnreadCount();
    _realtime?.subscribeToNotifications(
      userId: me.id,
      onInsert: (_) {
        _unreadNotifications++;
        _safeNotify();
      },
    );
  }

  /// Реакция на realtime-событие в ленте: мягко обновляем, если сейчас не
  /// идёт загрузка (чтобы не конфликтовать с пагинацией/рефрешем).
  void _onRealtimeFeedChange() {
    if (_isLoading || _isLoadingMore) return;
    if (_authService.currentUser == null) return;
    fetchPosts(isRefresh: true);
  }

  @override
  void dispose() {
    _realtime?.dispose();
    _authService.removeListener(_onAuthStatusChanged);
    super.dispose();
  }

  Future<void> _saveCachedPosts(List<PostModel> postsToCache) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'cached_social_posts_${_authService.currentUser?.id}';
      final encoded = postsToCache
          .map(
            (p) => p.toJson()
              ..addAll({
                'first_name': p.userFirstName,
                'last_name': p.userLastName,
                'username': p.userUsername,
                'emoji_avatar': p.userEmojiAvatar,
                'avatar_url': p.userAvatarUrl,
                'is_verified': p.userIsVerified,
                'likes_count': p.likesCount,
                'comments_count': p.commentsCount,
                'is_liked': p.isLikedByMe,
              }),
          )
          .toList();
      await prefs.setString(key, jsonEncode(encoded));
    } catch (e) {
      debugPrint('Error caching posts: $e');
    }
  }

  Future<void> _loadCachedPosts() async {
    final user = _authService.currentUser;
    if (user == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'cached_social_posts_${user.id}';
      final rawData = prefs.getString(key);
      if (rawData != null) {
        final List<dynamic> decoded = jsonDecode(rawData);
        _posts = decoded
            .map((item) => PostModel.fromJson(item, currentUserId: user.id))
            .toList();
        _safeNotify();
      }
    } catch (e) {
      debugPrint('Error loading cached posts: $e');
    }
  }

  /// Fetch all social posts
  /// Fetch social posts with pagination
  Future<void> fetchPosts({bool isRefresh = false}) async {
    final user = _authService.currentUser;
    if (user == null) return;

    if (isRefresh) {
      _posts = [];
      _hasMore = true;
      _isLoadingMore = false;
    }

    if (!_hasMore) return;

    final bool isFirstLoad = _posts.isEmpty;
    final int queryOffset = isFirstLoad ? 0 : _posts.length;

    if (isFirstLoad && _selectedTag == null) {
      await _loadCachedPosts();
      _setLoading(true);
    } else if (isFirstLoad) {
      _setLoading(true);
    } else {
      _isLoadingMore = true;
      _safeNotify();
    }

    _clearError();

    try {
      final fetched = await _repository.fetchPosts(
        user.id,
        limit: 10,
        offset: queryOffset,
        tag: _selectedTag,
      );

      if (fetched.length < 10) {
        _hasMore = false;
      }

      if (isRefresh || isFirstLoad) {
        _posts = fetched;
      } else {
        final existingIds = _posts.map((p) => p.id).toSet();
        final newPosts = fetched.where((p) => !existingIds.contains(p.id)).toList();
        _posts.addAll(newPosts);
      }

      if (!_isMockMode && (isRefresh || isFirstLoad) && _selectedTag == null) {
        await _saveCachedPosts(_posts);
      }
      _safeNotify();
    } catch (e) {
      _setError(e.toString());
      if (_posts.isEmpty) {
        await _loadCachedPosts();
      }
    } finally {
      _setLoading(false);
      _isLoadingMore = false;
      _safeNotify();
    }
  }

  /// Fetch a single post by ID
  Future<PostModel?> fetchPost(int postId) async {
    final user = _authService.currentUser;
    try {
      return await _repository.fetchPost(postId, user?.id);
    } catch (e) {
      debugPrint('Error fetching post $postId: $e');
      return null;
    }
  }

  /// Create a new social post
  Future<bool> createPost(
    String content, {
    String? linkUrl,
    String? linkTitle,
    String? pollQuestion,
    List<String>? pollOptions,
    String? imageUrl,
    String? imageFormat,
    int? imageWidth,
    int? imageHeight,
    List<String>? imageUrls,
    int? jobId,
  }) async {
    final user = _authService.currentUser;
    if (user == null || (content.trim().isEmpty && imageUrl == null && (imageUrls == null || imageUrls.isEmpty) && pollQuestion == null && jobId == null)) return false;

    _setLoading(true);
    _clearError();

    // Create optimistic post for instant UI feedback
    final PollModel? optimisticPoll =
        (pollQuestion != null && pollOptions != null && pollOptions.isNotEmpty)
        ? PollModel(
            question: pollQuestion,
            options: pollOptions,
            optionVotes: List.filled(pollOptions.length, 0),
            totalVotes: 0,
            userVotedIndex: null,
          )
        : null;

    final job = (jobId != null && _isMockMode) ? MockJobRepository.getJobById(jobId) : null;

    final optimisticPost = PostModel(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: user.id,
      userFirstName: user.firstName,
      userLastName: user.lastName,
      userUsername: user.username,
      userEmojiAvatar: user.emojiAvatar,
      userAvatarUrl: user.avatarUrl,
      userIsVerified: user.isVerified,
      content: content.trim(),
      createdAt: DateTime.now(),
      likesCount: 0,
      commentsCount: 0,
      isLikedByMe: false,
      linkUrl: linkUrl,
      linkTitle: linkTitle,
      poll: optimisticPoll,
      imageUrl: imageUrl ?? (imageUrls != null && imageUrls.isNotEmpty ? imageUrls.first : null),
      imageFormat: imageFormat,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      imageUploadedAt: (imageUrl != null || (imageUrls != null && imageUrls.isNotEmpty)) ? DateTime.now() : null,
      imageUrls: imageUrls ?? (imageUrl != null ? [imageUrl] : const []),
      jobId: jobId,
      job: job,
    );

    // Show post immediately
    _posts.insert(0, optimisticPost);
    _safeNotify();

    try {
      final createdPost = await _repository.createPost(
        userId: user.id,
        content: content,
        linkUrl: linkUrl,
        linkTitle: linkTitle,
        pollQuestion: pollQuestion,
        pollOptions: pollOptions,
        imageUrl: imageUrl,
        imageFormat: imageFormat,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        imageUrls: imageUrls,
        jobId: jobId,
      );

      // Re-fetch posts in background to align exactly with database IDs/states
      if (!_isMockMode) {
        fetchPosts(isRefresh: true);
      } else {
        // In mock mode, replace the optimistic post with the returned post
        final idx = _posts.indexWhere((p) => p.id == optimisticPost.id);
        if (idx != -1) {
          _posts[idx] = createdPost;
        }
        _safeNotify();
      }
      return true;
    } catch (e) {
      debugPrint('SocialService.createPost ERROR: $e');
      // Revert optimistic post on error
      _posts.removeWhere((p) => p.id == optimisticPost.id);
      _safeNotify();
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Like or unlike a post
  Future<bool> likePost(int postId, {bool? currentlyLikedByMe}) async {
    final user = _authService.currentUser;
    if (user == null) return false;

    final localIndex = _posts.indexWhere((p) => p.id == postId);
    bool currentlyLiked = currentlyLikedByMe ?? false;
    int likesCount = 0;
    PostModel? originalPost;

    if (localIndex != -1) {
      originalPost = _posts[localIndex];
      currentlyLiked = originalPost.isLikedByMe;
      likesCount = originalPost.likesCount;
    }

    final int nextLikesCount = currentlyLiked ? likesCount - 1 : likesCount + 1;
    final bool nextLikedByMe = !currentlyLiked;

    // Optimistic UI update
    if (localIndex != -1 && originalPost != null) {
      _posts[localIndex] = originalPost.copyWith(
        isLikedByMe: nextLikedByMe,
        likesCount: nextLikesCount,
      );
      _safeNotify();
    }

    try {
      await _repository.likePost(
        userId: user.id,
        postId: postId,
        currentlyLiked: currentlyLiked,
      );
      
      // If we liked a post not currently in local state (uncommon), still report success
      return true;
    } catch (e) {
      // Revert if error
      if (localIndex != -1 && originalPost != null) {
        _posts[localIndex] = originalPost;
        _safeNotify();
      }
      _setError(e.toString());
      return false;
    }
  }

  /// Fetch comments for a post
  Future<List<CommentModel>> fetchComments(int postId) async {
    final user = _authService.currentUser;
    _clearError();
    try {
      return await _repository.fetchComments(postId, user?.id);
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  /// Add comment to a post
  Future<CommentModel?> addComment(int postId, String content) async {
    final user = _authService.currentUser;
    if (user == null || content.trim().isEmpty) return null;

    _clearError();
    try {
      final newComment = await _repository.addComment(
        postId: postId,
        userId: user.id,
        content: content,
      );

      // Update local count
      final localIndex = _posts.indexWhere((p) => p.id == postId);
      if (localIndex != -1) {
        final p = _posts[localIndex];
        _posts[localIndex] = p.copyWith(commentsCount: p.commentsCount + 1);
        _safeNotify();
      }

      return newComment;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  /// Like or unlike a comment
  Future<bool> likeComment(
    int postId,
    int commentId, {
    required bool currentlyLiked,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return false;

    try {
      await _repository.likeComment(
        commentId: commentId,
        userId: user.id,
        currentlyLiked: currentlyLiked,
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Delete a post
  Future<bool> deletePost(int postId) async {
    _clearError();
    _setLoading(true);
    try {
      final user = _authService.currentUser;
      if (user == null) return false;

      // Try deleting image from Yandex Cloud storage if it exists
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        final imageUrl = _posts[postIndex].imageUrl;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          debugPrint('SocialService.deletePost: Deleting image from storage: $imageUrl');
          try {
            await ImageUploadService.deletePostImage(imageUrl);
          } catch (e) {
            debugPrint('SocialService.deletePost: Failed to delete image from S3 storage: $e');
          }
        }
      }

      await _repository.deletePost(postId: postId, userId: user.id);

      _posts.removeWhere((p) => p.id == postId);
      _safeNotify();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a comment
  Future<bool> deleteComment(int postId, int commentId) async {
    _clearError();
    try {
      final user = _authService.currentUser;
      if (user == null) return false;

      await _repository.deleteComment(commentId: commentId, userId: user.id);

      // Update local count
      final localIndex = _posts.indexWhere((p) => p.id == postId);
      if (localIndex != -1) {
        final p = _posts[localIndex];
        if (p.commentsCount > 0) {
          _posts[localIndex] = p.copyWith(commentsCount: p.commentsCount - 1);
          _safeNotify();
        }
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Get public profile of another user
  Future<UserModel?> fetchUserProfile(String userId) async {
    _clearError();
    try {
      if (_authService.currentUser?.id == userId) {
        return _authService.currentUser!;
      }
      return await _repository.fetchUserProfile(userId);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  /// Search users by username, first name or last name
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    _clearError();
    try {
      String cleanQuery = query.trim().toLowerCase();
      bool searchByUsernameOnly = false;
      if (cleanQuery.startsWith('@')) {
        cleanQuery = cleanQuery.substring(1).trim();
        searchByUsernameOnly = true;
      }

      if (cleanQuery.isEmpty) return [];

      final results = await _repository.searchUsers(cleanQuery, searchByUsernameOnly);

      // Make sure we include current user if they match the query
      final currentUser = _authService.currentUser;
      if (currentUser != null && !results.any((u) => u.id == currentUser.id)) {
        final match = searchByUsernameOnly 
            ? currentUser.username.toLowerCase().contains(cleanQuery)
            : (currentUser.username.toLowerCase().contains(cleanQuery) ||
                currentUser.firstName.toLowerCase().contains(cleanQuery) ||
                currentUser.lastName.toLowerCase().contains(cleanQuery));
        if (match) {
          results.add(currentUser);
        }
      }
      return results;
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  /// Fetch posts by a specific user
  Future<List<PostModel>> fetchUserPosts(String userId) async {
    _clearError();
    try {
      final user = _authService.currentUser;
      return await _repository.fetchUserPosts(userId, user?.id);
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  /// Get user stats: post count, total likes received
  Future<Map<String, int>> fetchUserStats(String userId) async {
    try {
      return await _repository.fetchUserStats(userId);
    } catch (e) {
      return {'posts': 0, 'likes': 0};
    }
  }

  /// Vote in a poll
  Future<bool> voteInPoll(int postId, int optionIndex) async {
    final user = _authService.currentUser;
    if (user == null) return false;

    final localIndex = _posts.indexWhere((p) => p.id == postId);
    if (localIndex == -1) return false;
    final originalPost = _posts[localIndex];
    if (originalPost.poll == null) return false;

    // Check if already voted
    if (originalPost.poll!.userVotedIndex != null) {
      return false;
    }

    // Optimistically update locally
    final updatedVotes = List<int>.from(originalPost.poll!.optionVotes);
    if (optionIndex >= 0 && optionIndex < updatedVotes.length) {
      updatedVotes[optionIndex]++;
    }
    final updatedPoll = originalPost.poll!.copyWith(
      optionVotes: updatedVotes,
      totalVotes: originalPost.poll!.totalVotes + 1,
      userVotedIndex: optionIndex,
    );

    _posts[localIndex] = originalPost.copyWith(poll: updatedPoll);
    _safeNotify();

    try {
      await _repository.voteInPoll(
        postId: postId,
        userId: user.id,
        optionIndex: optionIndex,
      );

      if (!_isMockMode) {
        // Refresh in background to get precise state
        fetchPosts();
      }
      return true;
    } catch (e) {
      // Revert if error
      _posts[localIndex] = originalPost;
      _safeNotify();
      _setError(e.toString());
      return false;
    }
  }

  // ── Подписки (follows) ──

  Future<bool> followUser(String userId) async {
    final me = _authService.currentUser;
    if (me == null || me.id == userId) return false;
    try {
      await _repository.followUser(followerId: me.id, followeeId: userId);
      return true;
    } catch (e) {
      _setError(AppError.from(e).message);
      return false;
    }
  }

  Future<bool> unfollowUser(String userId) async {
    final me = _authService.currentUser;
    if (me == null) return false;
    try {
      await _repository.unfollowUser(followerId: me.id, followeeId: userId);
      return true;
    } catch (e) {
      _setError(AppError.from(e).message);
      return false;
    }
  }

  Future<bool> isFollowing(String userId) async {
    final me = _authService.currentUser;
    if (me == null) return false;
    try {
      return await _repository.isFollowing(
        followerId: me.id,
        followeeId: userId,
      );
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, int>> fetchFollowCounts(String userId) async {
    try {
      return await _repository.fetchFollowCounts(userId);
    } catch (_) {
      return {'followers': 0, 'following': 0};
    }
  }

  /// Лента «Подписки» — посты тех, на кого подписан текущий пользователь.
  Future<List<PostModel>> fetchFollowingFeed({
    int limit = 10,
    int offset = 0,
  }) async {
    final me = _authService.currentUser;
    if (me == null) return [];
    try {
      return await _repository.fetchFollowingFeed(
        me.id,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      _setError(AppError.from(e).message);
      return [];
    }
  }

  // ── Уведомления ──

  Future<List<NotificationModel>> fetchNotifications() async {
    final me = _authService.currentUser;
    if (me == null) return [];
    try {
      return await _repository.fetchNotifications(me.id);
    } catch (e) {
      _setError(AppError.from(e).message);
      return [];
    }
  }

  Future<void> refreshUnreadCount() async {
    final me = _authService.currentUser;
    if (me == null) return;
    try {
      _unreadNotifications =
          await _repository.fetchUnreadNotificationsCount(me.id);
      _safeNotify();
    } catch (_) {
      // тихо игнорируем — бейдж не критичен
    }
  }

  /// Помечает все уведомления прочитанными и обнуляет бейдж.
  Future<void> markNotificationsRead() async {
    final me = _authService.currentUser;
    if (me == null) return;
    _unreadNotifications = 0;
    _safeNotify();
    try {
      await _repository.markNotificationsRead(me.id);
    } catch (_) {
      // не критично
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    _safeNotify();
  }

  void _setError(String msg) {
    _errorMessage = msg
        .replaceAll('Exception: ', '')
        .replaceAll('PostgrestException: ', '');
    _safeNotify();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      _safeNotify();
    }
  }

  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
