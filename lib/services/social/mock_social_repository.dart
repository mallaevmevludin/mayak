import 'dart:async';
import '../../../models/post_model.dart';
import '../../../models/comment_model.dart';
import '../../../models/user_model.dart';
import '../jobs/mock_job_repository.dart';
import 'social_repository.dart';

class MockSocialRepository implements SocialRepository {
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

  @override
  Future<List<PostModel>> fetchPosts(String? currentUserId, {int limit = 10, int offset = 0, String? tag}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var sorted = List<PostModel>.from(_mockPostsDb)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    sorted = sorted.map((p) {
      if (p.jobId != null && p.job == null) {
        return p.copyWith(job: MockJobRepository.getJobById(p.jobId!));
      }
      return p;
    }).toList();

    if (tag != null && tag.isNotEmpty) {
      sorted = sorted.where((p) => p.content.toLowerCase().contains('#${tag.toLowerCase()}')).toList();
    }

    if (offset >= sorted.length) return [];
    final end = (offset + limit).clamp(0, sorted.length);
    return sorted.sublist(offset, end);
  }

  @override
  Future<PostModel?> fetchPost(int postId, String? currentUserId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      final post = _mockPostsDb.firstWhere((p) => p.id == postId);
      if (post.jobId != null && post.job == null) {
        return post.copyWith(job: MockJobRepository.getJobById(post.jobId!));
      }
      return post;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PostModel> createPost({
    required String userId,
    required String content,
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
    await Future.delayed(const Duration(milliseconds: 300));

    final creator = _mockProfiles.firstWhere(
      (u) => u.id == userId,
      orElse: () => _mockProfiles.first,
    );

    final PollModel? poll =
        (pollQuestion != null && pollOptions != null && pollOptions.isNotEmpty)
        ? PollModel(
            question: pollQuestion,
            options: pollOptions,
            optionVotes: List.filled(pollOptions.length, 0),
            totalVotes: 0,
            userVotedIndex: null,
          )
        : null;

    final job = jobId != null ? MockJobRepository.getJobById(jobId) : null;

    final newPost = PostModel(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: userId,
      userFirstName: creator.firstName,
      userLastName: creator.lastName,
      userUsername: creator.username,
      userEmojiAvatar: creator.emojiAvatar,
      userAvatarUrl: creator.avatarUrl,
      userIsVerified: creator.isVerified,
      content: content.trim(),
      createdAt: DateTime.now(),
      likesCount: 0,
      commentsCount: 0,
      isLikedByMe: false,
      linkUrl: linkUrl,
      linkTitle: linkTitle,
      poll: poll,
      imageUrl: imageUrl ?? (imageUrls != null && imageUrls.isNotEmpty ? imageUrls.first : null),
      imageFormat: imageFormat,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      imageUploadedAt: (imageUrl != null || (imageUrls != null && imageUrls.isNotEmpty)) ? DateTime.now() : null,
      imageUrls: imageUrls ?? (imageUrl != null ? [imageUrl] : const []),
      jobId: jobId,
      job: job,
    );

    _mockPostsDb.insert(0, newPost);
    return newPost;
  }

  @override
  Future<void> likePost({
    required String userId,
    required int postId,
    required bool currentlyLiked,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _mockPostsDb.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _mockPostsDb[index];
      _mockPostsDb[index] = post.copyWith(
        isLikedByMe: !currentlyLiked,
        likesCount: currentlyLiked ? post.likesCount - 1 : post.likesCount + 1,
      );
    }
  }

  @override
  Future<List<CommentModel>> fetchComments(int postId, String? currentUserId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockCommentsDb[postId] ?? [];
  }

  @override
  Future<CommentModel> addComment({
    required int postId,
    required String userId,
    required String content,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final commenter = _mockProfiles.firstWhere(
      (u) => u.id == userId,
      orElse: () => _mockProfiles.first,
    );

    final newComment = CommentModel(
      id: DateTime.now().millisecondsSinceEpoch,
      postId: postId,
      userId: userId,
      userFirstName: commenter.firstName,
      userLastName: commenter.lastName,
      userUsername: commenter.username,
      userEmojiAvatar: commenter.emojiAvatar,
      userAvatarUrl: commenter.avatarUrl,
      userIsVerified: commenter.isVerified,
      content: content.trim(),
      createdAt: DateTime.now(),
    );

    if (!_mockCommentsDb.containsKey(postId)) {
      _mockCommentsDb[postId] = [];
    }
    _mockCommentsDb[postId]!.add(newComment);

    final postIdx = _mockPostsDb.indexWhere((p) => p.id == postId);
    if (postIdx != -1) {
      final p = _mockPostsDb[postIdx];
      _mockPostsDb[postIdx] = p.copyWith(commentsCount: p.commentsCount + 1);
    }

    return newComment;
  }

  @override
  Future<void> likeComment({
    required int commentId,
    required String userId,
    required bool currentlyLiked,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<void> deletePost({required int postId, required String userId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _mockPostsDb.removeWhere((p) => p.id == postId);
  }

  @override
  Future<void> deleteComment({required int commentId, required String userId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (final comments in _mockCommentsDb.values) {
      final commentIdx = comments.indexWhere((c) => c.id == commentId);
      if (commentIdx != -1) {
        final postId = comments[commentIdx].postId;
        comments.removeAt(commentIdx);
        final postIdx = _mockPostsDb.indexWhere((p) => p.id == postId);
        if (postIdx != -1) {
          final p = _mockPostsDb[postIdx];
          if (p.commentsCount > 0) {
            _mockPostsDb[postIdx] = p.copyWith(commentsCount: p.commentsCount - 1);
          }
        }
        break;
      }
    }
  }

  @override
  Future<UserModel?> fetchUserProfile(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockProfiles.firstWhere((u) => u.id == userId);
    } catch (_) {
      return _mockProfiles.first;
    }
  }

  @override
  Future<List<UserModel>> searchUsers(String query, bool searchByUsernameOnly) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final String cleanQuery = query.trim().toLowerCase();
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
    return results;
  }

  @override
  Future<List<PostModel>> fetchUserPosts(String userId, String? currentUserId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var posts = _mockPostsDb.where((p) => p.userId == userId).toList();
    posts = posts.map((p) {
      if (p.jobId != null && p.job == null) {
        return p.copyWith(job: MockJobRepository.getJobById(p.jobId!));
      }
      return p;
    }).toList();
    return posts..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Map<String, int>> fetchUserStats(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final userPosts = _mockPostsDb.where((p) => p.userId == userId).toList();
    final totalLikes = userPosts.fold<int>(0, (sum, p) => sum + p.likesCount);
    return {'posts': userPosts.length, 'likes': totalLikes};
  }

  @override
  Future<void> voteInPoll({
    required int postId,
    required String userId,
    required int optionIndex,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
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
  }
}
