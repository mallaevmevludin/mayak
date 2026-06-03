class PollModel {
  final String question;
  final List<String> options;
  final List<int> optionVotes; // Vote count per option index
  final int? userVotedIndex; // Current user's vote index, if any
  final int totalVotes;

  PollModel({
    required this.question,
    required this.options,
    required this.optionVotes,
    this.userVotedIndex,
    required this.totalVotes,
  });

  PollModel copyWith({
    String? question,
    List<String>? options,
    List<int>? optionVotes,
    int? userVotedIndex,
    int? totalVotes,
  }) {
    return PollModel(
      question: question ?? this.question,
      options: options ?? this.options,
      optionVotes: optionVotes ?? this.optionVotes,
      userVotedIndex: userVotedIndex ?? this.userVotedIndex,
      totalVotes: totalVotes ?? this.totalVotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'option_votes': optionVotes,
      'user_voted_index': userVotedIndex,
      'total_votes': totalVotes,
    };
  }

  factory PollModel.fromJson(Map<String, dynamic> json) {
    return PollModel(
      question: json['question'] as String? ?? '',
      options: json['options'] is List
          ? List<String>.from((json['options'] as List).map((e) => e?.toString() ?? ''))
          : [],
      optionVotes: json['option_votes'] is List
          ? List<int>.from((json['option_votes'] as List).map((e) => int.tryParse(e?.toString() ?? '') ?? 0))
          : [],
      userVotedIndex: json['user_voted_index'] as int?,
      totalVotes: json['total_votes'] as int? ?? 0,
    );
  }
}

class PostModel {
  final int id;
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
  final int commentsCount;
  final bool isLikedByMe;
  final String? linkUrl;
  final String? linkTitle;
  final PollModel? poll;
  final String? imageUrl;
  final String? imageFormat;
  final int? imageWidth;
  final int? imageHeight;
  final DateTime? imageUploadedAt;
  final List<String> imageUrls;

  PostModel({
    required this.id,
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
    this.commentsCount = 0,
    this.isLikedByMe = false,
    this.linkUrl,
    this.linkTitle,
    this.poll,
    this.imageUrl,
    this.imageFormat,
    this.imageWidth,
    this.imageHeight,
    this.imageUploadedAt,
    this.imageUrls = const [],
  });

  PostModel copyWith({
    int? id,
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
    int? commentsCount,
    bool? isLikedByMe,
    String? linkUrl,
    String? linkTitle,
    PollModel? poll,
    String? imageUrl,
    String? imageFormat,
    int? imageWidth,
    int? imageHeight,
    DateTime? imageUploadedAt,
    List<String>? imageUrls,
  }) {
    return PostModel(
      id: id ?? this.id,
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
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      linkUrl: linkUrl ?? this.linkUrl,
      linkTitle: linkTitle ?? this.linkTitle,
      poll: poll ?? this.poll,
      imageUrl: imageUrl ?? this.imageUrl,
      imageFormat: imageFormat ?? this.imageFormat,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      imageUploadedAt: imageUploadedAt ?? this.imageUploadedAt,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  factory PostModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final profile = json['profiles'] as Map<String, dynamic>?;

    // Check likes
    bool likedByMe = false;
    int likes = 0;
    if (json['post_likes'] != null) {
      final likesList = json['post_likes'] as List<dynamic>;
      likes = likesList.length;
      if (currentUserId != null) {
        likedByMe = likesList.any(
          (like) =>
              like is Map &&
              (like['user_id'] == currentUserId ||
                  like['profiles']?['id'] == currentUserId),
        );
      }
    } else if (json['is_liked'] != null) {
      likedByMe = json['is_liked'] as bool? ?? false;
      likes = json['likes_count'] as int? ?? 0;
    }

    int comments = 0;
    if (json['comments'] != null) {
      comments = (json['comments'] as List<dynamic>).length;
    } else if (json['comments_count'] != null) {
      comments = json['comments_count'] as int? ?? 0;
    }

    final linkUrlVal = json['link_url'] as String?;
    final linkTitleVal = json['link_title'] as String?;

    // Parse poll info
    dynamic pollData = json['polls'];
    if (pollData is List && pollData.isNotEmpty) {
      pollData = pollData.first;
    }
    PollModel? pollVal;
    if (pollData is Map) {
      final question = pollData['question'] as String? ?? '';
      final optionsList = pollData['options'] is List
          ? List<String>.from((pollData['options'] as List).map((e) => e?.toString() ?? ''))
          : <String>[];

      // Calculate votes from poll_votes
      final votesList = json['poll_votes'] as List<dynamic>? ?? [];
      final List<int> optionVotes = List.filled(optionsList.length, 0);
      int? userVotedIndex;
      int totalVotes = 0;

      for (final vote in votesList) {
        if (vote is Map) {
          final optIndex = vote['option_index'] as int?;
          final voterId = vote['user_id'] as String?;
          if (optIndex != null &&
              optIndex >= 0 &&
              optIndex < optionsList.length) {
            optionVotes[optIndex]++;
            totalVotes++;
            if (currentUserId != null && voterId == currentUserId) {
              userVotedIndex = optIndex;
            }
          }
        }
      }

      pollVal = PollModel(
        question: question,
        options: optionsList,
        optionVotes: optionVotes,
        userVotedIndex: userVotedIndex,
        totalVotes: totalVotes,
      );
    } else if (json['poll'] != null) {
      pollVal = PollModel.fromJson(json['poll'] as Map<String, dynamic>);
    }

    // Parse image urls list
    final dynamic imageUrlsJson = json['image_urls'];
    List<String> parsedImageUrls = [];
    if (imageUrlsJson != null) {
      if (imageUrlsJson is List) {
        parsedImageUrls = imageUrlsJson
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      } else {
        parsedImageUrls = [imageUrlsJson.toString()];
      }
    } else if (json['image_url'] != null) {
      parsedImageUrls = [json['image_url'] as String];
    }

    return PostModel(
      id: json['id'] as int? ?? 0,
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
      commentsCount: comments,
      isLikedByMe: likedByMe,
      linkUrl: linkUrlVal,
      linkTitle: linkTitleVal,
      poll: pollVal,
      imageUrl: json['image_url'] as String?,
      imageFormat: json['image_format'] as String?,
      imageWidth: json['image_width'] as int?,
      imageHeight: json['image_height'] as int?,
      imageUploadedAt: json['image_uploaded_at'] != null
          ? DateTime.parse(json['image_uploaded_at'] as String)
          : null,
      imageUrls: parsedImageUrls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'link_url': linkUrl,
      'link_title': linkTitle,
      'poll': poll?.toJson(),
      'image_url': imageUrls.isNotEmpty ? imageUrls.first : imageUrl,
      'image_format': imageFormat,
      'image_width': imageWidth,
      'image_height': imageHeight,
      'image_uploaded_at': imageUploadedAt?.toIso8601String(),
      'image_urls': imageUrls,
    };
  }
}
