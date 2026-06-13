import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../services/auth_service.dart';
import '../services/social_service.dart';
import '../services/job_service.dart';
import '../services/image_upload_service.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme.dart';
import '../widgets/interests_selector.dart';
import '../widgets/top_notification.dart';
import '../widgets/user_avatar.dart';
import 'crop_editor_screen.dart';
import 'profile/profile_completion_card.dart';
import 'profile/profile_posts_tab.dart';
import 'profile/profile_jobs_tab.dart';
import 'profile/profile_info_tab.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _bioController = TextEditingController();
  List<String> _tempInterests = [];
  bool _isEditing = false;
  List<PostModel> _userPosts = [];
  bool _isLoadingPosts = true;
  bool _isCompletionCardDismissed = false;
  List<dynamic> _myJobs = []; // Using dynamic to avoid circular model issues if any
  bool _isLoadingMyJobs = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bioController.addListener(_bioListener);
    _scrollController.addListener(_scrollListener);
    _loadUserPosts();
    _loadMyJobs();
    _loadCompletionCardDismissState();
  }

  void _scrollListener() {
    // Optional scroll behavior
  }

  Future<void> _loadCompletionCardDismissState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isCompletionCardDismissed =
            prefs.getBool('dismissed_profile_completion_card') ?? false;
      });
    } catch (_) {}
  }

  Future<void> _dismissCompletionCard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dismissed_profile_completion_card', true);
      setState(() {
        _isCompletionCardDismissed = true;
      });
      if (mounted) {
        TopNotification.show(
          context,
          message: 'Карточка прогресса скрыта',
          icon: Icons.visibility_off_rounded,
          actionLabel: 'Отменить',
          onActionPressed: () async {
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('dismissed_profile_completion_card', false);
              if (mounted) {
                setState(() {
                  _isCompletionCardDismissed = false;
                });
              }
            } catch (_) {}
          },
        );
      }
    } catch (_) {}
  }

  void _showAvatarOptions(BuildContext context, AuthService authService) {
    final user = authService.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkSurface
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Фото профиля',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                dense: true,
                visualDensity: const VisualDensity(vertical: -2),
                leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
                title: const Text('Выбрать из галереи'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndUploadAvatar(context, authService, ImageSource.gallery);
                },
              ),
              ListTile(
                dense: true,
                visualDensity: const VisualDensity(vertical: -2),
                leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
                title: const Text('Сделать снимок'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndUploadAvatar(context, authService, ImageSource.camera);
                },
              ),
              if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                  title: const Text(
                    'Удалить фото',
                    style: TextStyle(color: AppTheme.error),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final oldAvatarUrl = user.avatarUrl;
                    await authService.updateAvatarUrl('');
                    if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
                      debugPrint('[AVATAR_LOG] Deleting removed avatar from Yandex Cloud S3: $oldAvatarUrl');
                      try {
                        await ImageUploadService.deletePostImage(oldAvatarUrl);
                        if (context.mounted) {
                          TopNotification.show(
                            context,
                            message: 'Аватар удален из хранилища!',
                            icon: Icons.check_circle_outline_rounded,
                            iconColor: AppTheme.success,
                          );
                        }
                      } catch (e) {
                        debugPrint('[AVATAR_LOG] Failed to delete removed avatar: $e');
                        if (context.mounted) {
                          TopNotification.show(
                            context,
                            message: 'Ошибка при удалении из хранилища: $e',
                            icon: Icons.error_outline_rounded,
                            iconColor: AppTheme.error,
                          );
                        }
                      }
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(
    BuildContext context,
    AuthService authService,
    ImageSource source,
  ) async {
    debugPrint('[AVATAR_LOG] Entering _pickAndUploadAvatar, source: $source');
    bool isLoadingShown = false;
    try {
      final picker = ImagePicker();
      debugPrint('[AVATAR_LOG] Calling picker.pickImage...');
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
      );
      if (pickedFile == null) {
        debugPrint('[AVATAR_LOG] picker.pickImage returned null (user canceled or permission denied)');
        return;
      }
      debugPrint('[AVATAR_LOG] picker.pickImage succeeded. path: ${pickedFile.path}');

      if (!context.mounted) {
        debugPrint('[AVATAR_LOG] Context not mounted after picking image');
        return;
      }

      debugPrint('[AVATAR_LOG] Navigating to CropEditorScreen...');
      final CropResult? result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CropEditorScreen(
            imageFile: File(pickedFile.path),
            isCircle: true,
          ),
        ),
      );

      debugPrint('[AVATAR_LOG] Returned from CropEditorScreen, result is null: ${result == null}');
      if (result == null) {
        debugPrint('[AVATAR_LOG] Crop result is null (user canceled crop or load failed)');
        return;
      }

      if (!context.mounted) {
        debugPrint('[AVATAR_LOG] Context not mounted after returning from CropEditorScreen');
        return;
      }

      debugPrint('[AVATAR_LOG] Showing loading dialog overlay...');
      isLoadingShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primary,
          ),
        ),
      );

      debugPrint('[AVATAR_LOG] Uploading cropped file to Storage, path: ${result.croppedFile.path}');
      final publicUrl = await ImageUploadService.uploadAvatar(
        imageFile: result.croppedFile,
      );
      debugPrint('[AVATAR_LOG] Upload succeeded, publicUrl: $publicUrl');

      // Hide loading dialog
      if (context.mounted && isLoadingShown) {
        debugPrint('[AVATAR_LOG] Hiding loading dialog...');
        Navigator.pop(context);
        isLoadingShown = false;
      }

      final oldAvatarUrl = authService.currentUser?.avatarUrl;
      debugPrint('[AVATAR_LOG] Updating user avatar_url in auth database...');
      await authService.updateAvatarUrl(publicUrl);
      debugPrint('[AVATAR_LOG] authService.updateAvatarUrl completed');

      if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
        debugPrint('[AVATAR_LOG] Deleting old avatar from S3 storage: $oldAvatarUrl');
        try {
          await ImageUploadService.deletePostImage(oldAvatarUrl);
        } catch (e) {
          debugPrint('[AVATAR_LOG] Failed to delete old avatar: $e');
        }
      }

      if (context.mounted) {
        TopNotification.show(
          context,
          message: 'Аватар успешно обновлен!',
          icon: Icons.check_circle_outline_rounded,
          iconColor: AppTheme.success,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[AVATAR_LOG] Catch block triggered: $e');
      debugPrint('[AVATAR_LOG] StackTrace: $stackTrace');
      if (context.mounted) {
        if (isLoadingShown) {
          Navigator.pop(context);
        }
        TopNotification.show(
          context,
          message: 'Не удалось загрузить аватар: $e',
          icon: Icons.error_outline_rounded,
          iconColor: AppTheme.error,
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.updateProfile(
      biography: _bioController.text.trim(),
      interests: _tempInterests,
    );

    if (success && mounted) {
      TopNotification.show(
        context,
        message: 'Профиль успешно обновлен!',
        icon: Icons.check_circle_outline_rounded,
        iconColor: AppTheme.success,
      );
      setState(() {
        _isEditing = false;
      });
    }
  }

  Future<void> _loadUserPosts() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user != null) {
      final socialService = Provider.of<SocialService>(context, listen: false);
      final posts = await socialService.fetchUserPosts(user.id);
      if (mounted) {
        setState(() {
          _userPosts = posts;
          _isLoadingPosts = false;
        });
      }
    }
  }

  Future<void> _loadMyJobs() async {
    final jobService = Provider.of<JobService>(context, listen: false);
    final jobs = await jobService.fetchMyJobs();
    if (mounted) {
      setState(() {
        _myJobs = jobs;
        _isLoadingMyJobs = false;
      });
    }
  }

  void _bioListener() {
    if (_isEditing) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bioController.removeListener(_bioListener);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user != null) {
      debugPrint('ProfileView: Current user: ${user.username}, biography: "${user.biography}", interests: ${user.interests}');
    }

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isEditing) {
      if (_bioController.text.isEmpty && user.biography != null) {
        _bioController.text = user.biography!;
      }
      if (_tempInterests.isEmpty && user.interests.isNotEmpty) {
        _tempInterests = List<String>.from(user.interests);
      }
    }

    // Reactively map posts from the central social service
    final socialService = Provider.of<SocialService>(context);
    final displayPosts = _userPosts.map((localPost) {
      return socialService.posts.firstWhere(
        (p) => p.id == localPost.id,
        orElse: () => localPost,
      );
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: false,
              pinned: true,
              backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              title: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: AppRadius.controlR,
                  border: Border.all(
                    color: context.appCardBorder,
                    width: 0.5,
                  ),
                  boxShadow: AppShadows.soft(isDark),
                ),
                child: Text(
                  'Профиль',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: context.appTextPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              centerTitle: true,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderSection(user, theme, isDark, authService),
                    if (!_isCompletionCardDismissed) ...[
                      const SizedBox(height: 12),
                      ProfileCompletionCard(
                        user: user,
                        isEditing: _isEditing,
                        onStartEditing: () => setState(() => _isEditing = true),
                        onDismissed: _dismissCompletionCard,
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (!_isEditing)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
                  tabBar: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Посты'),
                      Tab(text: 'Заказы'),
                      Tab(text: 'Инфо'),
                    ],
                    labelColor: AppTheme.primary,
                    unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                    indicatorColor: AppTheme.primary,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
              ),
          ];
        },
        body: _isEditing
            ? SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                child: _buildProfileEditMode(theme, isDark, authService.isLoading),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  ProfilePostsTab(
                    posts: displayPosts,
                    isLoading: _isLoadingPosts,
                    onRefresh: _loadUserPosts,
                    onDeletePost: (post) {
                      setState(() {
                        _userPosts.removeWhere((p) => p.id == post.id);
                      });
                    },
                    onLikeTogglePost: (post) {
                      setState(() {
                        final idx = _userPosts.indexWhere((p) => p.id == post.id);
                        if (idx != -1) {
                          final p = _userPosts[idx];
                          final wasLiked = p.isLikedByMe;
                          _userPosts[idx] = p.copyWith(
                            isLikedByMe: !wasLiked,
                            likesCount: wasLiked ? p.likesCount - 1 : p.likesCount + 1,
                          );
                        }
                      });
                    },
                  ),
                  ProfileJobsTab(
                    jobs: _myJobs.cast(), // Safety cast to JobModel
                    isLoading: _isLoadingMyJobs,
                    onRefresh: _loadMyJobs,
                    onJobDetailsReturned: _loadMyJobs,
                  ),
                  ProfileInfoTab(user: user),
                ],
              ),
      ),
    );
  }

  Widget _buildHeaderSection(
      UserModel user, ThemeData theme, bool isDark, AuthService authService) {
    final totalPosts = _userPosts.length;
    final totalLikes = _userPosts.fold<int>(0, (sum, post) => sum + post.likesCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                UserAvatar.fromName(
                  firstName: user.firstName,
                  lastName: user.lastName,
                  avatarUrl: user.avatarUrl,
                  size: 92,
                  showBorder: true,
                  borderWidth: 1.5,
                  onTap: _isEditing ? () => _showAvatarOptions(context, authService) : null,
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => _showAvatarOptions(context, authService),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppTheme.darkBg : Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildHeaderStat(
                    '$totalPosts',
                    'Посты',
                  ),
                  _buildHeaderStat(
                    '$totalLikes',
                    'Лайки',
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Flexible(
              child: Text(
                '${user.firstName} ${user.lastName}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
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
                size: 20,
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '@${user.username}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (user.biography != null && user.biography!.trim().isNotEmpty) ...[
          Text(
            user.biography!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        if (_isEditing)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: authService.isLoading
                      ? null
                      : () {
                          setState(() {
                            _isEditing = false;
                          });
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Отмена',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: authService.isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: authService.isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Сохранить',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text(
                    'Редактировать профиль',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                    width: 0.5,
                  ),
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                  icon: const Icon(Icons.settings_rounded, color: AppTheme.primary),
                  tooltip: 'Настройки',
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildHeaderStat(String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileEditMode(ThemeData theme, bool isDark, bool isLoading) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Редактирование профиля',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (authService.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.error, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppTheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    authService.errorMessage!,
                    style: const TextStyle(
                      color: AppTheme.error,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        Text(
          'О себе (Биография)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bioController,
          maxLines: 4,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText:
                'Расскажите о себе, своих увлечениях и профессиональной деятельности...',
            fillColor: isDark ? AppTheme.darkSurface : Colors.white,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 20),

        InterestsSelector(
          selectedInterests: _tempInterests,
          onInterestsChanged: (interests) {
            setState(() {
              _tempInterests = interests;
            });
          },
        ),
      ],
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate({required this.tabBar, required this.backgroundColor});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: backgroundColor.withValues(alpha: 0.85),
          child: tabBar,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return oldDelegate.tabBar != tabBar || oldDelegate.backgroundColor != backgroundColor;
  }
}
