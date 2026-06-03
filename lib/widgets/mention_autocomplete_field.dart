import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/social_service.dart';
import '../theme/app_theme.dart';

/// A TextField with @mention autocomplete overlay.
/// When user types '@', shows a dropdown of matching users.
class MentionAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool borderless;

  const MentionAutocompleteField({
    super.key,
    required this.controller,
    this.hintText = 'Написать...',
    this.maxLines = 4,
    this.focusNode,
    this.onSubmitted,
    this.autofocus = false,
    this.borderless = false,
  });

  @override
  State<MentionAutocompleteField> createState() =>
      _MentionAutocompleteFieldState();
}

class _MentionAutocompleteFieldState extends State<MentionAutocompleteField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<UserModel> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _debounce;
  int _mentionStartIndex = -1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;

    if (cursorPos < 0 || cursorPos > text.length) {
      _hideSuggestions();
      return;
    }

    // Find the '@' before cursor
    int atIndex = -1;
    for (int i = cursorPos - 1; i >= 0; i--) {
      if (text[i] == '@') {
        atIndex = i;
        break;
      }
      if (text[i] == ' ' || text[i] == '\n') {
        break;
      }
    }

    if (atIndex >= 0) {
      // Check there's no space between @ and cursor
      final query = text.substring(atIndex + 1, cursorPos);
      if (!query.contains(' ') && !query.contains('\n')) {
        _mentionStartIndex = atIndex;
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 200), () {
          _searchUsers(query);
        });
        return;
      }
    }

    _hideSuggestions();
  }

  Future<void> _searchUsers(String query) async {
    final socialService = Provider.of<SocialService>(context, listen: false);
    final results = await socialService.searchUsers(query);

    if (mounted) {
      setState(() {
        _suggestions = results;
        _showSuggestions = results.isNotEmpty;
      });
      if (_showSuggestions) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    }
  }

  void _hideSuggestions() {
    _mentionStartIndex = -1;
    _showSuggestions = false;
    _suggestions = [];
    _removeOverlay();
  }

  void _selectUser(UserModel user) {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;

    // Replace @query with @username
    final before = text.substring(0, _mentionStartIndex);
    final after = cursorPos < text.length ? text.substring(cursorPos) : '';
    final newText = '$before@${user.username} $after';

    widget.controller.text = newText;
    final newCursorPos =
        _mentionStartIndex + user.username.length + 2; // +2 for @ and space
    widget.controller.selection = TextSelection.collapsed(offset: newCursorPos);

    _hideSuggestions();
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Positioned(
          width: MediaQuery.of(context).size.width - 40,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, -8),
            followerAnchor: Alignment.bottomLeft,
            targetAnchor: Alignment.topLeft,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.4 : 0.12,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final user = _suggestions[index];
                      return InkWell(
                        onTap: () => _selectUser(user),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.04),
                                backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                                    ? NetworkImage(user.avatarUrl!)
                                    : null,
                                child: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                                    ? null
                                    : Text(
                                        user.username.isNotEmpty
                                            ? user.username[0].toUpperCase()
                                            : 'U',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${user.firstName} ${user.lastName}'
                                          .trim(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    Text(
                                      '@${user.username}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppTheme.textSecondaryDark
                                            : AppTheme.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        maxLines: widget.maxLines,
        autofocus: widget.autofocus,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: widget.borderless ? 18 : 15,
        ),
        decoration: widget.borderless
            ? InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.24)
                      : Colors.black.withValues(alpha: 0.24),
                  fontSize: 18,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                fillColor: Colors.transparent,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              )
            : InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey[100],
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppTheme.primary,
                    width: 1,
                  ),
                ),
              ),
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
