class MessageModel {
  final int id;
  final int conversationId;
  final String senderId;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int,
      senderId: json['sender_id'] as String,
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
