import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/social_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../widgets/top_notification.dart';
import '../widgets/post_card.dart';
import '../widgets/mention_autocomplete_field.dart';
import '../widgets/sliding_segmented_control.dart';
import '../services/image_upload_service.dart';
import '../services/supabase_config.dart';
import '../widgets/skeleton_item.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  int _selectedTab = 0; // 0 = Лента, 1 = Популярное
  final ScrollController _scrollController = ScrollController();
  double _appBarOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SocialService>(context, listen: false).fetchPosts();
    });
  }

  void _onScroll() {
    if (!mounted) return;
    final offset = _scrollController.offset;
    final newOpacity = (offset / 60.0).clamp(0.0, 1.0);
    if (newOpacity != _appBarOpacity) {
      setState(() {
        _appBarOpacity = newOpacity;
      });
    }
  }

  Future<void> _refresh() async {
    await Provider.of<SocialService>(context, listen: false).fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final socialService = Provider.of<SocialService>(context);

    // Sort posts by tab: 0 = recent, 1 = most liked
    List posts = List.from(socialService.posts);
    if (_selectedTab == 1) {
      posts.sort((a, b) => b.likesCount.compareTo(a.likesCount));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.primary,
        displacement: 60,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ── iOS-style Large Title AppBar ──
            SliverAppBar(
              expandedHeight: 100,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 10),
                title: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.25 : 0.04,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Сообщество',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              actions: [
                GestureDetector(
                  onTap: _showCreatePostDialog,
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.25 : 0.04,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),

            // ── Segment control (Лента / Популярное) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                child: SlidingSegmentedControl(
                  children: const ['Лента', 'Популярное'],
                  selectedIndex: _selectedTab,
                  onValueChanged: (index) {
                    setState(() {
                      _selectedTab = index;
                    });
                  },
                ),
              ),
            ),

            // ── Loading indicator while refreshing (posts already visible) ──
            if (socialService.isLoading && posts.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: const LinearProgressIndicator(
                      minHeight: 2,
                      color: AppTheme.primary,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
              ),

            // ── Posts ──
            if (socialService.isLoading && socialService.posts.isEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: _buildPostSkeleton(isDark),
                  );
                }, childCount: 3),
              )
            else if (posts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.forum_outlined,
                        size: 56,
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Постов пока нет',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Напишите что-нибудь первым!',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final post = posts[index];
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      8,
                      0,
                      8,
                      index == posts.length - 1 ? 120 : 0,
                    ),
                    child: PostCard(post: post),
                  );
                }, childCount: posts.length),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostSkeleton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SkeletonItem(
                width: 40,
                height: 40,
                borderRadius: 20,
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonItem(
                    width: 120,
                    height: 14,
                    borderRadius: 4,
                  ),
                  SizedBox(height: 6),
                  SkeletonItem(
                    width: 80,
                    height: 10,
                    borderRadius: 3,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const SkeletonItem(
            width: double.infinity,
            height: 12,
            borderRadius: 3,
          ),
          const SizedBox(height: 8),
          const SkeletonItem(
            width: double.infinity,
            height: 12,
            borderRadius: 3,
          ),
          const SizedBox(height: 8),
          const SkeletonItem(
            width: 180,
            height: 12,
            borderRadius: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const SkeletonItem(
                width: 50,
                height: 24,
                borderRadius: 12,
              ),
              const SizedBox(width: 20),
              const SkeletonItem(
                width: 50,
                height: 24,
                borderRadius: 12,
              ),
              const Spacer(),
              SkeletonItem(
                width: 70,
                height: 12,
                borderRadius: 3,
                key: UniqueKey(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreatePostDialog() {
    final currentUser = Provider.of<AuthService>(
      context,
      listen: false,
    ).currentUser;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CreatePostSheet(currentUser: currentUser);
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class CreatePostSheet extends StatefulWidget {
  final UserModel? currentUser;

  const CreatePostSheet({
    super.key,
    required this.currentUser,
  });

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final TextEditingController _postController = TextEditingController();
  int _currentLength = 0;
  bool _isPublishing = false;

  final List<File> _selectedImages = [];
  String? _imageFormat;
  int? _imageWidth;
  int? _imageHeight;

  bool showPoll = false;

  final TextEditingController pollQuestionController = TextEditingController();
  final List<TextEditingController> pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  String? _detectedUrl;
  final RegExp _urlRegex = RegExp(
    r'(https?:\/\/[^\s]+|[a-zA-Z0-9][-a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+\b[^\s]*)',
    caseSensitive: false,
  );



  @override
  void initState() {
    super.initState();
    _postController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _postController.text;
    String? url;
    final match = _urlRegex.firstMatch(text);
    if (match != null) {
      url = match.group(0)!;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
    }
    setState(() {
      _currentLength = text.length;
      _detectedUrl = url;
    });
  }

  @override
  void dispose() {
    _postController.removeListener(_onTextChanged);
    _postController.dispose();
    pollQuestionController.dispose();
    for (var c in pollOptionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isPublishDisabled {
    final hasContent = _postController.text.trim().isNotEmpty || _selectedImages.isNotEmpty;
    if (!hasContent) return true;
    if (_currentLength > 280) return true;

    if (showPoll) {
      if (pollQuestionController.text.trim().isEmpty) return true;
      if (pollOptionControllers.any((c) => c.text.trim().isEmpty)) return true;
    }

    return false;
  }

  void _addPollOption() {
    if (pollOptionControllers.length < 5) {
      setState(() {
        pollOptionControllers.add(TextEditingController());
      });
    }
  }

  void _removePollOption(int index) {
    if (pollOptionControllers.length > 2) {
      setState(() {
        pollOptionControllers[index].dispose();
        pollOptionControllers.removeAt(index);
      });
    }
  }

  Widget _buildCharacterIndicator() {
    final percent = _currentLength / 280;
    final isClose = _currentLength >= 250;
    final isExceeded = _currentLength > 280;

    if (isExceeded) {
      return Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        child: Text(
          '${280 - _currentLength}',
          style: const TextStyle(
            color: AppTheme.error,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            value: percent > 1.0 ? 1.0 : percent,
            strokeWidth: 2,
            backgroundColor: Colors.grey.withValues(alpha: 0.15),
            color: isClose ? AppTheme.warning : AppTheme.primary,
          ),
        ),
        if (isClose)
          Text(
            '${280 - _currentLength}',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: isClose ? AppTheme.warning : AppTheme.primary,
            ),
          ),
      ],
    );
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 5) {
      TopNotification.show(
        context,
        message: 'Максимум 5 фотографий',
        icon: Icons.warning_amber_rounded,
        iconColor: AppTheme.warning,
      );
      return;
    }

    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Выберите источник',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
                title: const Text('Галерея'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
                title: const Text('Камера'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    if (source == ImageSource.camera) {
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2000,
        maxHeight: 2000,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
      }
    } else {
      final pickedFiles = await picker.pickMultiImage(
        maxWidth: 2000,
        maxHeight: 2000,
      );
      if (pickedFiles.isNotEmpty) {
        setState(() {
          final spaceLeft = 5 - _selectedImages.length;
          _selectedImages.addAll(
            pickedFiles.take(spaceLeft).map((xfile) => File(xfile.path)),
          );
        });
      }
    }
  }

  Future<void> _publishPost() async {
    if (_isPublishDisabled || _isPublishing) return;

    setState(() {
      _isPublishing = true;
    });

    final text = _postController.text.trim();
    final socialService = Provider.of<SocialService>(context, listen: false);

    final List<String> imageUrls = [];
    try {
      if (_selectedImages.isNotEmpty) {
        if (!SupabaseConfig.isConfigured) {
          // Mock mode: simulate upload and use standard premium placeholder image
          for (int i = 0; i < _selectedImages.length; i++) {
            imageUrls.add('https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=800&q=80');
          }
        } else {
          for (final file in _selectedImages) {
            final optimizedResult = await ImageUploadService.optimizeImage(file);
            final uploadResult = await ImageUploadService.uploadPostImage(
              imageFile: optimizedResult['optimized']!,
              thumbnailFile: optimizedResult['thumbnail']!,
            );
            imageUrls.add(uploadResult['imageUrl']!);
          }
        }
        _imageFormat = '1:1'; // default aspect ratio for slider
      }
    } catch (e, stackTrace) {
      debugPrint('social_feed_screen image upload failed with exception: $e');
      debugPrint('social_feed_screen stack trace:\n$stackTrace');
      setState(() {
        _isPublishing = false;
      });
      if (mounted) {
        TopNotification.show(
          context,
          message: 'Ошибка загрузки фото: ${e.toString().replaceAll("Exception: ", "")}',
          icon: Icons.error_outline,
          iconColor: AppTheme.error,
        );
      }
      return;
    }

    String? linkUrl = _detectedUrl;
    String? linkTitle = _detectedUrl;
    if (linkUrl != null) {
      try {
        final uri = Uri.parse(linkUrl);
        linkTitle = uri.host.isNotEmpty ? uri.host : linkUrl;
        if (linkTitle.startsWith('www.')) {
          linkTitle = linkTitle.substring(4);
        }
      } catch (_) {}
    }

    String? pollQuestion = showPoll ? pollQuestionController.text.trim() : null;
    List<String>? pollOptions;
    if (showPoll) {
      pollOptions = pollOptionControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
    }

    final success = await socialService.createPost(
      text,
      linkUrl: linkUrl,
      linkTitle: linkTitle,
      pollQuestion: pollQuestion,
      pollOptions: pollOptions,
      imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
      imageFormat: _imageFormat,
      imageWidth: _imageWidth,
      imageHeight: _imageHeight,
      imageUrls: imageUrls,
    );

    if (success && mounted) {
      setState(() {
        _isPublishing = false;
      });
      Navigator.pop(context);
      TopNotification.show(
        context,
        message: 'Пост опубликован!',
        icon: Icons.check_circle_outline,
        iconColor: AppTheme.success,
      );
    } else {
      setState(() {
        _isPublishing = false;
      });
      if (mounted) {
        TopNotification.show(
          context,
          message: socialService.errorMessage ?? 'Ошибка публикации поста',
          icon: Icons.error_outline,
          iconColor: AppTheme.error,
        );
      }
    }
  }

  Widget _buildToolbarIcon({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
    required String tooltip,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04))
              : Colors.transparent,
          border: Border.all(
            color: isActive
                ? (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08))
                : Colors.transparent,
            width: 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 20,
          color: isActive
              ? AppTheme.primary
              : (isDark
                    ? Colors.white.withValues(alpha: 0.38)
                    : Colors.black.withValues(alpha: 0.38)),
        ),
      ),
    );
  }

  Widget _buildPollBuilder(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Опрос',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    showPoll = false;
                    pollQuestionController.clear();
                    for (var c in pollOptionControllers) {
                      c.clear();
                    }
                  });
                },
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppTheme.error.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: pollQuestionController,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              hintText: 'Задайте вопрос...',
              hintStyle: TextStyle(
                fontSize: 14,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.3),
              ),
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            onChanged: (_) => setState(() {}),
          ),
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
            height: 1,
          ),
          const SizedBox(height: 8),
          ...List.generate(pollOptionControllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pollOptionControllers[index],
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Вариант ${index + 1}',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.3),
                        ),
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  if (pollOptionControllers.length > 2) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _removePollOption(index),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          if (pollOptionControllers.length < 5)
            GestureDetector(
              onTap: _addPollOption,
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Добавить вариант',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetectedUrlBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.link_rounded, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _detectedUrl!,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black87,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161618) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          body: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04),
                        ),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: isDark
                              ? Colors.white70
                              : Colors.black.withValues(alpha: 0.7),
                          size: 22,
                        ),
                      ),
                    ),
                    // Center title
                    Text(
                      'Новый пост',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    // Right Publish button
                    GestureDetector(
                      onTap: (_isPublishDisabled || _isPublishing) ? null : _publishPost,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (_isPublishDisabled || _isPublishing)
                              ? (isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.black.withValues(alpha: 0.03))
                              : AppTheme.primary,
                        ),
                        child: _isPublishing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                Icons.arrow_upward_rounded,
                                color: (_isPublishDisabled || _isPublishing)
                                    ? (isDark
                                          ? Colors.white.withValues(alpha: 0.25)
                                          : Colors.black.withValues(alpha: 0.25))
                                    : Colors.white,
                                size: 22,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // User avatar & text input
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.04),
                              backgroundImage: (widget.currentUser?.avatarUrl != null &&
                                      widget.currentUser!.avatarUrl!.isNotEmpty)
                                  ? NetworkImage(widget.currentUser!.avatarUrl!)
                                  : null,
                              child: (widget.currentUser?.avatarUrl != null &&
                                      widget.currentUser!.avatarUrl!.isNotEmpty)
                                  ? null
                                  : Text(
                                      widget.currentUser?.username.isNotEmpty ==
                                              true
                                          ? widget.currentUser!.username[0]
                                                .toUpperCase()
                                          : 'U',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MentionAutocompleteField(
                              controller: _postController,
                              hintText: 'Что нового?',
                              maxLines: 8,
                              autofocus: true,
                              borderless: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Selected Image Previews (Multiple)
                      if (_selectedImages.isNotEmpty) ...[
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              final file = _selectedImages[index];
                              return Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.file(
                                        file,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    // Delete button
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedImages.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Collapsible Poll Builder (Placed above the toolbar)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        reverseDuration: const Duration(milliseconds: 250),
                        switchInCurve: Curves.easeInOut,
                        switchOutCurve: Curves.easeInOut,
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return SizeTransition(
                                sizeFactor: animation,
                                child: child,
                              );
                            },
                        child: showPoll
                            ? KeyedSubtree(
                                key: const ValueKey('poll_builder'),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildPollBuilder(isDark),
                                ),
                              )
                            : const SizedBox(key: ValueKey('poll_empty')),
                      ),



                      // Auto-detected URL banner (Placed above the toolbar)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        reverseDuration: const Duration(milliseconds: 250),
                        switchInCurve: Curves.easeInOut,
                        switchOutCurve: Curves.easeInOut,
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return SizeTransition(
                                sizeFactor: animation,
                                child: child,
                              );
                            },
                        child: _detectedUrl != null
                            ? KeyedSubtree(
                                key: const ValueKey('detected_url_banner'),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildDetectedUrlBanner(isDark),
                                ),
                              )
                            : const SizedBox(key: ValueKey('url_empty')),
                      ),

                      // Pinned/Bottom-most row containing icons and character indicator
                      Row(
                        children: [
                          _buildToolbarIcon(
                            icon: Icons.bar_chart_rounded,
                            isActive: showPoll,
                            onTap: () {
                              setState(() {
                                showPoll = !showPoll;
                              });
                            },
                            isDark: isDark,
                            tooltip: 'Добавить опрос',
                          ),
                          const SizedBox(width: 12),
                          _buildToolbarIcon(
                            icon: Icons.photo_library_outlined,
                            isActive: _selectedImages.isNotEmpty,
                            onTap: _pickImage,
                            isDark: isDark,
                            tooltip: 'Добавить фото',
                          ),
                          const Spacer(),
                          _buildCharacterIndicator(),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
