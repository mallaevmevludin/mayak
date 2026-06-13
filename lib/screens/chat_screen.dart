import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/message_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/user_avatar.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String otherName;
  final String otherUsername;
  final String? otherAvatarUrl;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherName,
    required this.otherUsername,
    this.otherAvatarUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _sending = false;

  ChatService get _chat =>
      Provider.of<ChatService>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final messages = await _chat.fetchMessages(widget.conversationId);
    if (!mounted) return;
    setState(() {
      _messages = messages;
      _isLoading = false;
    });
    _chat.markRead(widget.conversationId);
    _chat.subscribeToConversation(widget.conversationId, _onIncoming);
    _scrollToBottom();
  }

  void _onIncoming(MessageModel message) {
    if (!mounted) return;
    // Не дублируем собственные отправленные (они уже добавлены оптимистично).
    if (_messages.any((m) => m.id == message.id)) return;
    setState(() => _messages = [..._messages, message]);
    _chat.markRead(widget.conversationId);
    _scrollToBottom();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _input.clear();
    final sent = await _chat.sendMessage(widget.conversationId, text);
    if (!mounted) return;
    setState(() {
      if (sent != null && !_messages.any((m) => m.id == sent.id)) {
        _messages = [..._messages, sent];
      }
      _sending = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _chat.unsubscribeConversation();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myId = Provider.of<AuthService>(context, listen: false).currentUser?.id;

    return Scaffold(
      backgroundColor: context.appBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar.fromUsername(
              username: widget.otherUsername,
              avatarUrl: widget.otherAvatarUrl,
              size: 36,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.otherName.isNotEmpty
                        ? widget.otherName
                        : '@${widget.otherUsername}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@${widget.otherUsername}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  : _messages.isEmpty
                      ? const AppEmptyState(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Нет сообщений',
                          subtitle: 'Напишите первым — поздоровайтесь 👋',
                        )
                      : ListView.builder(
                          controller: _scroll,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.lg,
                            AppSpacing.md,
                          ),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final m = _messages[index];
                            return _bubble(m, m.senderId == myId);
                          },
                        ),
            ),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _bubble(MessageModel m, bool isMine) {
    final isDark = context.isDark;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMine
              ? AppTheme.primary
              : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.card),
            topRight: const Radius.circular(AppRadius.card),
            bottomLeft: Radius.circular(isMine ? AppRadius.card : AppSpacing.xs),
            bottomRight: Radius.circular(isMine ? AppSpacing.xs : AppRadius.card),
          ),
        ),
        child: Text(
          m.content,
          style: TextStyle(
            fontSize: 15,
            height: 1.35,
            color: isMine ? Colors.white : context.appTextPrimary,
          ),
        ),
      ),
    );
  }

  Widget _composer() {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.appBg,
        border: Border(
          top: BorderSide(color: context.appCardBorder, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Сообщение…',
                filled: true,
                fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sheet),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_upward_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
