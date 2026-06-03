import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/social_service.dart';
import '../theme/app_theme.dart';
import 'user_profile_screen.dart';

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
    _performSearch(query);
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
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    width: 1,
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final initial = user.username.isNotEmpty
            ? user.username[0].toUpperCase()
            : 'U';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              width: 0.8,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: isDark
                  ? AppTheme.primary.withValues(alpha: 0.15)
                  : AppTheme.primary.withValues(alpha: 0.08),
              backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                  ? null
                  : Text(
                      initial,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        fontSize: 16,
                      ),
                    ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 52,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(height: 16),
            Text(
              'Ничего не найдено',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Попробуйте изменить запрос или введите @имя_пользователя для точного поиска.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
