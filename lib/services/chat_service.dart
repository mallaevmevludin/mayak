import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../utils/app_error.dart';
import 'auth_service.dart';
import 'supabase_config.dart';
import 'chat/chat_repository.dart';
import 'chat/mock_chat_repository.dart';
import 'chat/supabase_chat_repository.dart';

class ChatService extends ChangeNotifier {
  final AuthService _authService;
  late final ChatRepository _repository;
  final bool _isMock;

  RealtimeChannel? _convChannel;

  ChatService(this._authService) : _isMock = !SupabaseConfig.isConfigured {
    _repository =
        _isMock ? MockChatRepository() : SupabaseChatRepository();
  }

  String? get _meId => _authService.currentUser?.id;

  Future<List<ConversationModel>> fetchConversations() async {
    final me = _meId;
    if (me == null) return [];
    try {
      return await _repository.fetchConversations(me);
    } catch (e) {
      debugPrint('fetchConversations error: ${AppError.from(e).message}');
      return [];
    }
  }

  Future<int?> openDirectConversation(String otherUserId) async {
    try {
      return await _repository.getOrCreateDirectConversation(otherUserId);
    } catch (e) {
      debugPrint('openDirectConversation error: ${AppError.from(e).message}');
      return null;
    }
  }

  Future<List<MessageModel>> fetchMessages(int conversationId) async {
    try {
      return await _repository.fetchMessages(conversationId);
    } catch (e) {
      debugPrint('fetchMessages error: ${AppError.from(e).message}');
      return [];
    }
  }

  Future<MessageModel?> sendMessage(int conversationId, String content) async {
    final me = _meId;
    if (me == null || content.trim().isEmpty) return null;
    try {
      return await _repository.sendMessage(
        conversationId: conversationId,
        senderId: me,
        content: content.trim(),
      );
    } catch (e) {
      debugPrint('sendMessage error: ${AppError.from(e).message}');
      return null;
    }
  }

  Future<void> markRead(int conversationId) async {
    final me = _meId;
    if (me == null) return;
    try {
      await _repository.markConversationRead(
        conversationId: conversationId,
        userId: me,
      );
    } catch (_) {/* не критично */}
  }

  /// Live-подписка на новые сообщения открытой беседы (только боевой режим).
  void subscribeToConversation(
    int conversationId,
    void Function(MessageModel message) onMessage,
  ) {
    if (_isMock) return;
    unsubscribeConversation();
    final client = Supabase.instance.client;
    _convChannel = client.channel('public:messages:$conversationId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'conversation_id',
          value: conversationId,
        ),
        callback: (payload) {
          onMessage(MessageModel.fromJson(payload.newRecord));
        },
      )
      ..subscribe();
  }

  void unsubscribeConversation() {
    final ch = _convChannel;
    if (ch != null) {
      Supabase.instance.client.removeChannel(ch);
      _convChannel = null;
    }
  }

  @override
  void dispose() {
    unsubscribeConversation();
    super.dispose();
  }
}
