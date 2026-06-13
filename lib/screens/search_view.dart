import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/social_service.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_empty_state.dart';
import 'user_profile_screen.dart';
import '../widgets/user_avatar.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isLoading = false;
  String _lastQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadInitialSuggestions();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialSuggestions() async {
    setState(() {
      _isLoading = true;
    });
    final socialService = Provider.of<SocialService>(context, listen: false);
    // Fetch suggestions by using an empty query or standard recommendations
    final results = await socialService.searchUsers(' ');
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query == _lastQuery) return;
    _lastQuery = query;

    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      _performSearch(query);
    } else {
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        _performSearch(query);
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      _loadInitialSuggestions();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final socialService = Provider.of<SocialService>(context, listen: false);
    final results = await socialService.searchUsers(query);

    if (mounted && query == _searchController.text) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text(
          'Поиск',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Field
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                  borderRadius: AppRadius.cardR,
                  border: Border.all(
                    color: context.appCardBorder,
                    width: 0.5,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Поиск по имени, фамилии или @логину...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Search Results or Placeholder
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  : _searchResults.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildResultsList(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(bool isDark) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.bottomNavClearance,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];

        return AppCard(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
          padding: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs + 2,
            ),
            leading: UserAvatar.fromUsername(
              username: user.username,
              avatarUrl: user.avatarUrl,
              size: 48,
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    '${user.firstName} ${user.lastName}'.trim().isNotEmpty
                        ? '${user.firstName} ${user.lastName}'
                        : 'Пользователь',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (user.isVerified) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.verified_rounded,
                    color: AppTheme.primary,
                    size: 16,
                  ),
                ],
              ],
            ),
            subtitle: Text(
              '@${user.username}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileScreen(userId: user.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return const AppEmptyState(
      icon: Icons.search_off_rounded,
      title: 'Ничего не найдено',
      subtitle:
          'Попробуйте изменить запрос или введите @имя_пользователя для точного поиска.',
    );
  }
}
