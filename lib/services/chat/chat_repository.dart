import '../../../models/conversation_model.dart';
import '../../../models/message_model.dart';

abstract class ChatRepository {
  /// Список бесед текущего пользователя.
  Future<List<ConversationModel>> fetchConversations(String currentUserId);

  /// Найти или создать личную беседу с пользователем; вернуть её id.
  Future<int> getOrCreateDirectConversation(String otherUserId);

  /// Сообщения беседы (по возрастанию времени).
  Future<List<MessageModel>> fetchMessages(int conversationId, {int limit = 50});

  /// Отправить сообщение.
  Future<MessageModel> sendMessage({
    required int conversationId,
    required String senderId,
    required String content,
  });

  /// Пометить беседу прочитанной (обновить last_read_at).
  Future<void> markConversationRead({
    required int conversationId,
    required String userId,
  });
}
