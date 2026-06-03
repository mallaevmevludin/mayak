import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'image_upload_service.dart';
import 'supabase_config.dart';

class SocialService extends ChangeNotifier {
  final AuthService _authService;

  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get _isMockMode => !SupabaseConfig.isConfigured;

  // Local mock databases
  static final List<PostModel> _mockPostsDb = [
    PostModel(
      id: 1,
      userId: 'mock-user-2',
      userFirstName: 'Александр',
      userLastName: 'Петров',
      userUsername: 'sasha_fit',
      userEmojiAvatar: '💪',
      userIsVerified: true,
      content:
          'Ребята, закрыл неделю ежедневных тренировок! Стрик 7 дней 🔥 Чувствую себя супер.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      likesCount: 5,
      commentsCount: 2,
      isLikedByMe: false,
    ),
    PostModel(
      id: 2,
      userId: 'mock-user-3',
      userFirstName: 'Мария',
      userLastName: 'Смирнова',
      userUsername: 'maria_zen',
      userEmojiAvatar: '🧘',
      userIsVerified: true,
      content:
          'Сегодняшняя утренняя медитация была невероятно глубокой. Всем хорошего и осознанного дня! ✨',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      likesCount: 12,
      commentsCount: 1,
      isLikedByMe: true,
    ),
  ];

  static final Map<int, List<CommentModel>> _mockCommentsDb = {
    1: [
      CommentModel(
        id: 1,
        postId: 1,
        userId: 'mock-user-3',
        userFirstName: 'Мария',
        userLastName: 'Смирнова',
        userUsername: 'maria_zen',
        userEmojiAvatar: '🧘',
        userIsVerified: true,
        content: 'Поздравляю! Отличный результат 💪 Какой следующий рубеж?',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      CommentModel(
        id: 2,
        postId: 1,
        userId: 'mock-user-1',
        userFirstName: 'Иван',
        userLastName: 'Иванов',
        userUsername: 'ivanov',
        userEmojiAvatar: '🏃',
        userIsVerified: false,
        content: 'Мощно! Тоже хочу такую серию собрать.',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ],
    2: [
      CommentModel(
        id: 3,
        postId: 2,
        userId: 'mock-user-2',
        userFirstName: 'Александр',
        userLastName: 'Петров',
        userUsername: 'sasha_fit',
        userEmojiAvatar: '💪',
        userIsVerified: true,
        content: 'Маша, подскажи, под какую музыку медитируешь? Или в тишине?',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ],
  };

  static final List<UserModel> _mockProfiles = [
    UserModel(
      id: 'mock-user-1',
      firstName: 'Иван',
      lastName: 'Иванов',
      username: 'ivanov',
      email: 'ivan@example.com',
      phoneNumber: '+7 (999) 123-45-67',
      biography: 'Разработчик на Flutter, люблю спорт и чтение.',
      interests: ['Flutter', 'Спорт', 'Чтение'],
      emojiAvatar: '🏃',
      isVerified: false,
    ),
    UserModel(
      id: 'mock-user-2',
      firstName: 'Александр',
      lastName: 'Петров',
      username: 'sasha_fit',
      email: 'sasha@example.com',
      phoneNumber: '+7 (999) 765-43-21',
      biography: 'Фитнес-тренер, бегаю марафоны, пропагандирую ЗОЖ 💪',
      interests: ['Фитнес', 'Бег', 'ЗОЖ', 'Питание'],
      emojiAvatar: '💪',
      isVerified: true,
    ),
    UserModel(
      id: 'mock-user-3',
      firstName: 'Мария',
      lastName: 'Смирнова',
      username: 'maria_zen',
      email: 'maria@example.com',
      phoneNumber: '+7 (999) 111-22-33',
      biography: 'Инструктор по йоге и медитации. Учу находить дзен в хаосе 🧘',
      interests: ['Йога', 'Медитация', 'Дзен', 'Психология'],
      emojiAvatar: '🧘',
      isVerified: true,
    ),
  ];

  SocialService(this._authService) {
    _authService.addListener(_onAuthStatusChanged);
    if (_authService.currentUser != null) {
      fetchPosts();
    }
  }

  void _onAuthStatusChanged() {
    if (_authService.currentUser == null) {
      _posts = [];
      _safeNotify();
    } else {
      fetchPosts();
    }
  }

  @override
  void dispose() {
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
  Future<void> fetchPosts() async {
    final user = _authService.currentUser;
    if (user == null) return;

    // Load from cache first for instant start
    if (_posts.isEmpty) {
      await _loadCachedPosts();
    }

    _setLoading(true);
    _clearError();

    try {
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 300));
        _posts = List<PostModel>.from(_mockPostsDb)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        final response = await Supabase.instance.client
            .from('posts')
            .select('''
              id, content, created_at, user_id,
              link_url, link_title,
              image_url, image_format, image_width, image_height, image_uploaded_at, image_urls,
              profiles:user_id(first_name, last_name, username, emoji_avatar, avatar_url, is_verified),
              post_likes(user_id),
              comments(id),
              polls:polls(question, options),
              poll_votes:poll_votes(user_id, option_index)
            ''')
            .order('created_at', ascending: false);

        final List<dynamic> data = response;
        _posts = data
            .map((json) => PostModel.fromJson(json, currentUserId: user.id))
            .toList();

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
    }
  }

  /// Fetch a single post by ID
  Future<PostModel?> fetchPost(int postId) async {
    final user = _authService.currentUser;
    try {
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 100));
        return _mockPostsDb.firstWhere((p) => p.id == postId);
      } else {
        final response = await Supabase.instance.client
            .from('posts')
            .select('''
              id, content, created_at, user_id,
              link_url, link_title,
              image_url, image_format, image_width, image_height, image_uploaded_at, image_urls,
              profiles:user_id(first_name, last_name, username, emoji_avatar, avatar_url, is_verified),
              post_likes(user_id),
              comments(id),
              polls:polls(question, options),
              poll_votes:poll_votes(user_id, option_index)
            ''')
            .eq('id', postId)
            .single();
        return PostModel.fromJson(response, currentUserId: user?.id);
      }
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
  }) async {
    final user = _authService.currentUser;
    if (user == null || (content.trim().isEmpty && imageUrl == null && (imageUrls == null || imageUrls.isEmpty) && pollQuestion == null)) return false;

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
    );

    // Show post immediately
    _posts.insert(0, optimisticPost);
    _safeNotify();

    try {
      if (_isMockMode) {
        debugPrint('SocialService.createPost: [Mock Mode] inserting post');
        await Future.delayed(const Duration(milliseconds: 300));
        _mockPostsDb.insert(0, optimisticPost);
        return true;
      } else {
        final Map<String, dynamic> insertData = {
          'user_id': user.id,
          'content': content.trim(),
          'link_url': linkUrl,
          'link_title': linkTitle,
          'image_url': imageUrl ?? (imageUrls != null && imageUrls.isNotEmpty ? imageUrls.first : null),
          'image_format': imageFormat,
          'image_width': imageWidth,
          'image_height': imageHeight,
          'image_uploaded_at': (imageUrl != null || (imageUrls != null && imageUrls.isNotEmpty)) ? DateTime.now().toUtc().toIso8601String() : null,
          'image_urls': imageUrls ?? (imageUrl != null ? [imageUrl] : const []),
        };

        debugPrint('SocialService.createPost: Inserting post row to Supabase: $insertData');
        final response = await Supabase.instance.client
            .from('posts')
            .insert(insertData)
            .select('id')
            .single();

        final newPostId = response['id'] as int;
        debugPrint('SocialService.createPost: Post created successfully with ID = $newPostId');

        if (pollQuestion != null &&
            pollOptions != null &&
            pollOptions.isNotEmpty) {
          debugPrint('SocialService.createPost: Inserting poll for post ID = $newPostId');
          await Supabase.instance.client.from('polls').insert({
            'post_id': newPostId,
            'question': pollQuestion,
            'options': pollOptions,
          });
          debugPrint('SocialService.createPost: Poll created successfully');
        }

        // Refresh in background to get real server data (ID, timestamps)
        // Don't set loading — optimistic post is already shown
        fetchPosts();
        return true;
      }
    } catch (e, stackTrace) {
      debugPrint('SocialService.createPost ERROR: $e');
      debugPrint('SocialService.createPost STACK TRACE:\n$stackTrace');
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
    bool currentlyLiked = false;
    int likesCount = 0;
    PostModel? originalPost;

    if (localIndex != -1) {
      originalPost = _posts[localIndex];
      currentlyLiked = originalPost.isLikedByMe;
      likesCount = originalPost.likesCount;
    } else {
      if (_isMockMode) {
        final dbIndex = _mockPostsDb.indexWhere((p) => p.id == postId);
        if (dbIndex != -1) {
          currentlyLiked = _mockPostsDb[dbIndex].isLikedByMe;
          likesCount = _mockPostsDb[dbIndex].likesCount;
        }
      } else {
        currentlyLiked = currentlyLikedByMe ?? false;
      }
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
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 100));

        final dbIndex = _mockPostsDb.indexWhere((p) => p.id == postId);
        if (dbIndex != -1) {
          _mockPostsDb[dbIndex] = _mockPostsDb[dbIndex].copyWith(
            isLikedByMe: nextLikedByMe,
            likesCount: nextLikesCount,
          );
        }
        _safeNotify();
        return true;
      } else {
        if (currentlyLiked) {
          await Supabase.instance.client
              .from('post_likes')
              .delete()
              .eq('post_id', postId)
              .eq('user_id', user.id);
        } else {
          await Supabase.instance.client.from('post_likes').insert({
            'post_id': postId,
            'user_id': user.id,
          });
        }
        _safeNotify();
        return true;
      }
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
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 200));
        return _mockCommentsDb[postId] ?? [];
      } else {
        final response = await Supabase.instance.client
            .from('comments')
            .select('''
              id, post_id, user_id, content, created_at,
              profiles:user_id(first_name, last_name, username, emoji_avatar, avatar_url, is_verified),
              comment_likes(user_id)
            ''')
            .eq('post_id', postId)
            .order('created_at', ascending: true);

        final List<dynamic> data = response;
        return data
            .map((json) => CommentModel.fromJson(json, currentUserId: user?.id))
            .toList();
      }
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
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 200));

        final newComment = CommentModel(
          id: DateTime.now().millisecondsSinceEpoch,
          postId: postId,
          userId: user.id,
          userFirstName: user.firstName,
          userLastName: user.lastName,
          userUsername: user.username,
          userEmojiAvatar: user.emojiAvatar,
          userAvatarUrl: user.avatarUrl,
          userIsVerified: user.isVerified,
          content: content.trim(),
          createdAt: DateTime.now(),
        );

        if (!_mockCommentsDb.containsKey(postId)) {
          _mockCommentsDb[postId] = [];
        }
        _mockCommentsDb[postId]!.add(newComment);

        // Update local counts
        final localIndex = _posts.indexWhere((p) => p.id == postId);
        if (localIndex != -1) {
          final p = _posts[localIndex];
          _posts[localIndex] = p.copyWith(commentsCount: p.commentsCount + 1);
          _safeNotify();
        }

        final dbIndex = _mockPostsDb.indexWhere((p) => p.id == postId);
        if (dbIndex != -1) {
          _mockPostsDb[dbIndex] = _mockPostsDb[dbIndex].copyWith(
            commentsCount: _mockPostsDb[dbIndex].commentsCount + 1,
          );
        }

        return newComment;
      } else {
        final response = await Supabase.instance.client
            .from('comments')
            .insert({
              'post_id': postId,
              'user_id': user.id,
              'content': content.trim(),
            })
            .select('''
              id, post_id, user_id, content, created_at,
              profiles:user_id(first_name, last_name, username, emoji_avatar, avatar_url, is_verified),
              comment_likes(user_id)
            ''')
            .single();

        final newComment = CommentModel.fromJson(
          response,
          currentUserId: user.id,
        );

        // Update local count
        final localIndex = _posts.indexWhere((p) => p.id == postId);
        if (localIndex != -1) {
          final p = _posts[localIndex];
          _posts[localIndex] = p.copyWith(commentsCount: p.commentsCount + 1);
          _safeNotify();
        }

        return newComment;
      }
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
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      } else {
        if (currentlyLiked) {
          await Supabase.instance.client
              .from('comment_likes')
              .delete()
              .eq('comment_id', commentId)
              .eq('user_id', user.id);
        } else {
          await Supabase.instance.client.from('comment_likes').insert({
            'comment_id': commentId,
            'user_id': user.id,
          });
        }
        return true;
      }
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
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 200));
        _mockPostsDb.removeWhere((p) => p.id == postId);
        _posts.removeWhere((p) => p.id == postId);
        _safeNotify();
        return true;
      } else {
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

        await Supabase.instance.client
            .from('posts')
            .delete()
            .eq('id', postId)
            .eq('user_id', user.id);

        _posts.removeWhere((p) => p.id == postId);
        _safeNotify();
        return true;
      }
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
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (_mockCommentsDb.containsKey(postId)) {
          _mockCommentsDb[postId]!.removeWhere((c) => c.id == commentId);
        }

        // Update local count
        final localIndex = _posts.indexWhere((p) => p.id == postId);
        if (localIndex != -1) {
          final p = _posts[localIndex];
          if (p.commentsCount > 0) {
            _posts[localIndex] = p.copyWith(commentsCount: p.commentsCount - 1);
            _safeNotify();
          }
        }

        final dbIndex = _mockPostsDb.indexWhere((p) => p.id == postId);
        if (dbIndex != -1) {
          final p = _mockPostsDb[dbIndex];
          if (p.commentsCount > 0) {
            _mockPostsDb[dbIndex] = p.copyWith(
              commentsCount: p.commentsCount - 1,
            );
          }
        }
        return true;
      } else {
        final user = _authService.currentUser;
        if (user == null) return false;

        await Supabase.instance.client
            .from('comments')
            .delete()
            .eq('id', commentId)
            .eq('user_id', user.id);

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
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Get public profile of another user
  Future<UserModel?> fetchUserProfile(String userId) async {
    _clearError();
    try {
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 300));

        if (_authService.currentUser?.id == userId) {
          return _authService.currentUser!;
        }

        final profile = _mockProfiles.firstWhere(
          (u) => u.id == userId,
          orElse: () => _mockProfiles.first,
        );
        return profile;
      } else {
        final response = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', userId)
            .single();

        return UserModel.fromJson(response, '');
      }
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

      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 100));
        final List<UserModel> results = [];

        for (final u in _mockProfiles) {
          if (searchByUsernameOnly) {
            if (u.username.toLowerCase().contains(cleanQuery)) {
              results.add(u);
            }
          } else {
            if (u.username.toLowerCase().contains(cleanQuery) ||
                u.firstName.toLowerCase().contains(cleanQuery) ||
                u.lastName.toLowerCase().contains(cleanQuery)) {
              results.add(u);
            }
          }
        }

        // Also check current user
        final currentUser = _authService.currentUser;
        if (currentUser != null &&
            !results.any((u) => u.id == currentUser.id)) {
          if (searchByUsernameOnly) {
            if (currentUser.username.toLowerCase().contains(cleanQuery)) {
              results.add(currentUser);
            }
          } else {
            if (currentUser.username.toLowerCase().contains(cleanQuery) ||
                currentUser.firstName.toLowerCase().contains(cleanQuery) ||
                currentUser.lastName.toLowerCase().contains(cleanQuery)) {
              results.add(currentUser);
            }
          }
        }
        return results;
      } else {
        var req = Supabase.instance.client.from('profiles').select();
        if (searchByUsernameOnly) {
          req = req.ilike('username', '%$cleanQuery%');
        } else {
          req = req.or(
            'username.ilike.%$cleanQuery%,first_name.ilike.%$cleanQuery%,last_name.ilike.%$cleanQuery%',
          );
        }

        final response = await req.limit(20);
        final List<dynamic> data = response;
        return data.map((json) => UserModel.fromJson(json, '')).toList();
      }
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  /// Fetch posts by a specific user
  Future<List<PostModel>> fetchUserPosts(String userId) async {
    _clearError();
    try {
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 200));
        return _mockPostsDb.where((p) => p.userId == userId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        final user = _authService.currentUser;
        final response = await Supabase.instance.client
            .from('posts')
            .select('''
              id, content, created_at, user_id,
              link_url, link_title,
              image_url, image_format, image_width, image_height, image_uploaded_at, image_urls,
              profiles:user_id(first_name, last_name, username, emoji_avatar, avatar_url),
              post_likes(user_id),
              comments(id),
              polls:polls(question, options),
              poll_votes:poll_votes(user_id, option_index)
            ''')
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        final List<dynamic> data = response;
        return data
            .map((json) => PostModel.fromJson(json, currentUserId: user?.id))
            .toList();
      }
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  /// Get user stats: post count, total likes received
  Future<Map<String, int>> fetchUserStats(String userId) async {
    try {
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 100));
        final userPosts = _mockPostsDb
            .where((p) => p.userId == userId)
            .toList();
        final totalLikes = userPosts.fold<int>(
          0,
          (sum, p) => sum + p.likesCount,
        );
        return {'posts': userPosts.length, 'likes': totalLikes};
      } else {
        final postsResponse = await Supabase.instance.client
            .from('posts')
            .select('id, post_likes(user_id)')
            .eq('user_id', userId);
        final List<dynamic> data = postsResponse;
        int totalLikes = 0;
        for (final post in data) {
          if (post['post_likes'] != null) {
            totalLikes += (post['post_likes'] as List).length;
          }
        }
        return {'posts': data.length, 'likes': totalLikes};
      }
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
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 100));
        // Update mock database
        final dbIndex = _mockPostsDb.indexWhere((p) => p.id == postId);
        if (dbIndex != -1) {
          final dbPost = _mockPostsDb[dbIndex];
          if (dbPost.poll != null) {
            final dbVotes = List<int>.from(dbPost.poll!.optionVotes);
            if (optionIndex >= 0 && optionIndex < dbVotes.length) {
              dbVotes[optionIndex]++;
            }
            _mockPostsDb[dbIndex] = dbPost.copyWith(
              poll: dbPost.poll!.copyWith(
                optionVotes: dbVotes,
                totalVotes: dbPost.poll!.totalVotes + 1,
                userVotedIndex: optionIndex,
              ),
            );
          }
        }
        return true;
      } else {
        await Supabase.instance.client.from('poll_votes').insert({
          'post_id': postId,
          'user_id': user.id,
          'option_index': optionIndex,
        });

        // Refresh in background to get precise state
        fetchPosts();
        return true;
      }
    } catch (e) {
      // Revert if error
      _posts[localIndex] = originalPost;
      _safeNotify();
      _setError(e.toString());
      return false;
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
