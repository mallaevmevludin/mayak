class CommentModel {
  final int id;
  final int postId;
  final String userId;
  final String userFirstName;
  final String userLastName;
  final String userUsername;
  final String? userEmojiAvatar;
  final String? userAvatarUrl;
  final bool userIsVerified;
  final String content;
  final DateTime createdAt;
  final int likesCount;
  final bool isLikedByMe;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userFirstName,
    required this.userLastName,
    required this.userUsername,
    this.userEmojiAvatar,
    this.userAvatarUrl,
    this.userIsVerified = false,
    required this.content,
    required this.createdAt,
    this.likesCount = 0,
    this.isLikedByMe = false,
  });

  CommentModel copyWith({
    int? id,
    int? postId,
    String? userId,
    String? userFirstName,
    String? userLastName,
    String? userUsername,
    String? userEmojiAvatar,
    String? userAvatarUrl,
    bool? userIsVerified,
    String? content,
    DateTime? createdAt,
    int? likesCount,
    bool? isLikedByMe,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userFirstName: userFirstName ?? this.userFirstName,
      userLastName: userLastName ?? this.userLastName,
      userUsername: userUsername ?? this.userUsername,
      userEmojiAvatar: userEmojiAvatar ?? this.userEmojiAvatar,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      userIsVerified: userIsVerified ?? this.userIsVerified,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }

  factory CommentModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final profile = json['profiles'] as Map<String, dynamic>?;

    // Parse comment likes
    bool likedByMe = false;
    int likes = 0;
    if (json['comment_likes'] != null) {
      final likesList = json['comment_likes'] as List<dynamic>;
      likes = likesList.length;
      if (currentUserId != null) {
        likedByMe = likesList.any(
          (like) => like is Map && like['user_id'] == currentUserId,
        );
      }
    } else if (json['is_liked'] != null) {
      likedByMe = json['is_liked'] as bool? ?? false;
      likes = json['likes_count'] as int? ?? 0;
    }

    return CommentModel(
      id: json['id'] as int? ?? 0,
      postId: json['post_id'] as int? ?? 0,
      userId: json['user_id'] as String? ?? '',
      userFirstName:
          profile?['first_name'] as String? ??
          json['first_name'] as String? ??
          'Пользователь',
      userLastName:
          profile?['last_name'] as String? ??
          json['last_name'] as String? ??
          '',
      userUsername:
          profile?['username'] as String? ??
          json['username'] as String? ??
          'user',
      userEmojiAvatar:
          profile?['emoji_avatar'] as String? ??
          json['emoji_avatar'] as String?,
      userAvatarUrl:
          profile?['avatar_url'] as String? ??
          json['avatar_url'] as String?,
      userIsVerified:
          profile?['is_verified'] as bool? ??
          json['is_verified'] as bool? ??
          false,
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      likesCount: likes,
      isLikedByMe: likedByMe,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
