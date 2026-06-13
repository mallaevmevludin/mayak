/// Беседа в списке чатов: собеседник + последнее сообщение + флаг непрочитанного.
class ConversationModel {
  final int id;
  final String otherUserId;
  final String otherName;
  final String otherUsername;
  final String? otherAvatarUrl;
  final String? otherEmojiAvatar;
  final bool otherIsVerified;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastSenderId;
  final bool isUnread;

  const ConversationModel({
    required this.id,
    required this.otherUserId,
    required this.otherName,
    required this.otherUsername,
    this.otherAvatarUrl,
    this.otherEmojiAvatar,
    this.otherIsVerified = false,
    this.lastMessage,
    this.lastMessageAt,
    this.lastSenderId,
    this.isUnread = false,
  });

  /// Маппинг из строки RPC `get_my_conversations`. [currentUserId] нужен, чтобы
  /// вычислить «непрочитано» (последнее сообщение позже моего last_read_at и не
  /// от меня).
  factory ConversationModel.fromRpc(
    Map<String, dynamic> json, {
    required String currentUserId,
  }) {
    final first = (json['other_first'] as String?)?.trim() ?? '';
    final last = (json['other_last'] as String?)?.trim() ?? '';
    final fullName = '$first $last'.trim();

    final lastAt = json['last_at'] != null
        ? DateTime.parse(json['last_at'] as String)
        : null;
    final lastReadAt = json['last_read_at'] != null
        ? DateTime.parse(json['last_read_at'] as String)
        : null;
    final lastSender = json['last_sender'] as String?;

    final unread = lastAt != null &&
        lastSender != currentUserId &&
        (lastReadAt == null || lastAt.isAfter(lastReadAt));

    return ConversationModel(
      id: json['conversation_id'] as int,
      otherUserId: json['other_id'] as String,
      otherName: fullName.isNotEmpty
          ? fullName
          : (json['other_username'] as String? ?? ''),
      otherUsername: json['other_username'] as String? ?? '',
      otherAvatarUrl: json['other_avatar'] as String?,
      otherEmojiAvatar: json['other_emoji'] as String?,
      otherIsVerified: json['other_verified'] as bool? ?? false,
      lastMessage: json['last_content'] as String?,
      lastMessageAt: lastAt,
      lastSenderId: lastSender,
      isUnread: unread,
    );
  }
}
