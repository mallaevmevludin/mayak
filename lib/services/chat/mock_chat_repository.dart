import '../../../models/conversation_model.dart';
import '../../../models/message_model.dart';
import 'chat_repository.dart';

/// In-memory реализация чата для офлайн/демо-режима.
class MockChatRepository implements ChatRepository {
  static final Map<int, List<MessageModel>> _messages = {};
  static int _msgSeq = 1000;

  @override
  Future<List<ConversationModel>> fetchConversations(
    String currentUserId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final conversations = <ConversationModel>[];
    for (final entry in _messages.entries) {
      if (entry.value.isEmpty) continue;
      final last = entry.value.last;
      conversations.add(
        ConversationModel(
          id: entry.key,
          otherUserId: 'mock-user-2',
          otherName: 'Александр Петров',
          otherUsername: 'sasha_fit',
          otherEmojiAvatar: '💪',
          otherIsVerified: true,
          lastMessage: last.content,
          lastMessageAt: last.createdAt,
          lastSenderId: last.senderId,
        ),
      );
    }
    return conversations;
  }

  @override
  Future<int> getOrCreateDirectConversation(String otherUserId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Одна демо-беседа на собеседника.
    final id = otherUserId.hashCode & 0x7fffffff;
    _messages.putIfAbsent(id, () => []);
    return id;
  }

  @override
  Future<List<MessageModel>> fetchMessages(
    int conversationId, {
    int limit = 50,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List<MessageModel>.from(_messages[conversationId] ?? const []);
  }

  @override
  Future<MessageModel> sendMessage({
    required int conversationId,
    required String senderId,
    required String content,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final msg = MessageModel(
      id: _msgSeq++,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      createdAt: DateTime.now(),
    );
    _messages.putIfAbsent(conversationId, () => []).add(msg);
    return msg;
  }

  @override
  Future<void> markConversationRead({
    required int conversationId,
    required String userId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
  }
}
