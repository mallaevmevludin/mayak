import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/conversation_model.dart';
import '../../../models/message_model.dart';
import 'chat_repository.dart';

class SupabaseChatRepository implements ChatRepository {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<List<ConversationModel>> fetchConversations(
    String currentUserId,
  ) async {
    final response = await _client.rpc('get_my_conversations');
    return (response as List)
        .map((json) => ConversationModel.fromRpc(
              json as Map<String, dynamic>,
              currentUserId: currentUserId,
            ))
        .toList();
  }

  @override
  Future<int> getOrCreateDirectConversation(String otherUserId) async {
    final response = await _client.rpc(
      'get_or_create_direct_conversation',
      params: {'other_user': otherUserId},
    );
    return response as int;
  }

  @override
  Future<List<MessageModel>> fetchMessages(
    int conversationId, {
    int limit = 50,
  }) async {
    final response = await _client
        .from('messages')
        .select('id, conversation_id, sender_id, content, image_url, created_at')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .limit(limit);
    return (response as List)
        .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MessageModel> sendMessage({
    required int conversationId,
    required String senderId,
    required String content,
  }) async {
    final response = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': senderId,
          'content': content,
        })
        .select('id, conversation_id, sender_id, content, image_url, created_at')
        .single();
    return MessageModel.fromJson(response);
  }

  @override
  Future<void> markConversationRead({
    required int conversationId,
    required String userId,
  }) async {
    await _client
        .from('conversation_participants')
        .update({'last_read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('conversation_id', conversationId)
        .eq('user_id', userId);
  }
}
