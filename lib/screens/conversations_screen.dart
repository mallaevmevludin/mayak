import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/conversation_model.dart';
import '../services/chat_service.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/user_avatar.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  bool _isLoading = true;
  List<ConversationModel> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final chat = Provider.of<ChatService>(context, listen: false);
    final items = await chat.fetchConversations();
    if (!mounted) return;
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _open(ConversationModel c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: c.id,
          otherName: c.otherName,
          otherUsername: c.otherUsername,
          otherAvatarUrl: c.otherAvatarUrl,
        ),
      ),
    );
    _load(); // обновить список (последнее сообщение/прочитано) по возвращении
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inDays > 7) return '${(d.inDays / 7).floor()} нед.';
    if (d.inDays > 0) return '${d.inDays} дн.';
    if (d.inHours > 0) return '${d.inHours} ч.';
    if (d.inMinutes > 0) return '${d.inMinutes} мин.';
    return 'сейчас';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBg,
      appBar: AppBar(
        title: const Text(
          'Сообщения',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary,
                ),
              )
            : _items.isEmpty
                ? const AppEmptyState(
                    icon: Icons.forum_outlined,
                    title: 'Нет переписок',
                    subtitle:
                        'Откройте профиль пользователя и нажмите «Написать», чтобы начать диалог.',
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.bottomNavClearance,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (context, index) => _tile(_items[index]),
                  ),
      ),
    );
  }

  Widget _tile(ConversationModel c) {
    return InkWell(
      onTap: () => _open(c),
      borderRadius: AppRadius.cardR,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
        child: Row(
          children: [
            UserAvatar.fromUsername(
              username: c.otherUsername,
              avatarUrl: c.otherAvatarUrl,
              size: 52,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.otherName.isNotEmpty
                              ? c.otherName
                              : '@${c.otherUsername}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.appTextPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _timeAgo(c.lastMessageAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.lastMessage ?? 'Нет сообщений',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: c.isUnread
                                ? context.appTextPrimary
                                : context.appTextSecondary,
                            fontWeight:
                                c.isUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (c.isUnread) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
