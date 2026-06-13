enum NotificationType { like, comment, follow, mention, unknown }

NotificationType _typeFromString(String? raw) {
  switch (raw) {
    case 'like':
      return NotificationType.like;
    case 'comment':
      return NotificationType.comment;
    case 'follow':
      return NotificationType.follow;
    case 'mention':
      return NotificationType.mention;
    default:
      return NotificationType.unknown;
  }
}

class NotificationModel {
  final int id;
  final NotificationType type;
  final String actorId;
  final String actorName;
  final String actorUsername;
  final String? actorAvatarUrl;
  final String? actorEmojiAvatar;
  final bool actorIsVerified;
  final int? postId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.actorId,
    required this.actorName,
    required this.actorUsername,
    this.actorAvatarUrl,
    this.actorEmojiAvatar,
    this.actorIsVerified = false,
    this.postId,
    this.isRead = false,
    required this.createdAt,
  });

  /// Текст действия для отображения (без имени — имя показываем отдельно).
  String get actionText {
    switch (type) {
      case NotificationType.like:
        return 'оценил(а) вашу публикацию';
      case NotificationType.comment:
        return 'прокомментировал(а) вашу публикацию';
      case NotificationType.follow:
        return 'подписался(ась) на вас';
      case NotificationType.mention:
        return 'упомянул(а) вас';
      case NotificationType.unknown:
        return 'взаимодействовал(а) с вами';
    }
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final actor = (json['actor'] as Map<String, dynamic>?) ?? const {};
    final firstName = (actor['first_name'] as String?)?.trim() ?? '';
    final lastName = (actor['last_name'] as String?)?.trim() ?? '';
    final fullName = '$firstName $lastName'.trim();

    return NotificationModel(
      id: json['id'] as int,
      type: _typeFromString(json['type'] as String?),
      actorId: json['actor_id'] as String,
      actorName:
          fullName.isNotEmpty ? fullName : (actor['username'] as String? ?? ''),
      actorUsername: actor['username'] as String? ?? '',
      actorAvatarUrl: actor['avatar_url'] as String?,
      actorEmojiAvatar: actor['emoji_avatar'] as String?,
      actorIsVerified: actor['is_verified'] as bool? ?? false,
      postId: json['post_id'] as int?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
