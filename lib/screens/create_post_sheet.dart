import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/social_service.dart';
import '../models/user_model.dart';
import '../models/job_model.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme.dart';
import '../widgets/top_notification.dart';
import '../widgets/mention_autocomplete_field.dart';
import '../widgets/user_avatar.dart';
import '../widgets/post_job_card.dart';
import '../services/job_service.dart';
import '../services/image_upload_service.dart';
import '../services/supabase_config.dart';
import '../utils/constants.dart';

class CreatePostSheet extends StatefulWidget {
  final UserModel? currentUser;
  final JobModel? initialJob;

  const CreatePostSheet({
    super.key,
    required this.currentUser,
    this.initialJob,
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



  JobModel? _attachedJob;

  @override
  void initState() {
    super.initState();
    _attachedJob = widget.initialJob;
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
    final hasContent = _postController.text.trim().isNotEmpty || _selectedImages.isNotEmpty || _attachedJob != null;
    if (!hasContent) return true;
    if (_currentLength > AppConstants.maxPostLength) return true;

    if (showPoll) {
      if (pollQuestionController.text.trim().isEmpty) return true;
      if (pollOptionControllers.any((c) => c.text.trim().isEmpty)) return true;
    }

    return false;
  }

  void _addPollOption() {
    if (pollOptionControllers.length < AppConstants.maxPollOptions) {
      setState(() {
        pollOptionControllers.add(TextEditingController());
      });
    }
  }

  void _removePollOption(int index) {
    if (pollOptionControllers.length > AppConstants.minPollOptions) {
      setState(() {
        pollOptionControllers[index].dispose();
        pollOptionControllers.removeAt(index);
      });
    }
  }

  Widget _buildCharacterIndicator() {
    final percent = _currentLength / AppConstants.maxPostLength;
    final isClose = _currentLength >= 250;
    final isExceeded = _currentLength > AppConstants.maxPostLength;

    if (isExceeded) {
      return Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        child: Text(
          '${AppConstants.maxPostLength - _currentLength}',
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
            '${AppConstants.maxPostLength - _currentLength}',
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
    if (_selectedImages.length >= AppConstants.maxPostImages) {
      TopNotification.show(
        context,
        message: 'Максимум ${AppConstants.maxPostImages} фотографий',
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
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
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
        maxWidth: AppConstants.maxImageDimension.toDouble(),
        maxHeight: AppConstants.maxImageDimension.toDouble(),
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
      }
    } else {
      final pickedFiles = await picker.pickMultiImage(
        maxWidth: AppConstants.maxImageDimension.toDouble(),
        maxHeight: AppConstants.maxImageDimension.toDouble(),
      );
      if (pickedFiles.isNotEmpty) {
        setState(() {
          final spaceLeft = AppConstants.maxPostImages - _selectedImages.length;
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
      jobId: _attachedJob?.id,
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

  Future<void> _selectAndAttachJob() async {
    setState(() {
      _isPublishing = true;
    });
    
    List<JobModel> myJobs = [];
    try {
      myJobs = await Provider.of<JobService>(context, listen: false).fetchMyJobs();
      myJobs = myJobs.where((j) => j.status == JobStatus.active || j.status == JobStatus.pending).toList();
    } catch (e) {
      debugPrint('Error fetching my jobs for attaching: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final innerIsDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: innerIsDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: innerIsDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              Text(
                'Прикрепить заказ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: innerIsDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              if (myJobs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.work_off_outlined,
                        size: 48,
                        color: innerIsDark ? Colors.white24 : Colors.black26,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'У вас нет активных заказов',
                        style: TextStyle(
                          fontSize: 14,
                          color: innerIsDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: myJobs.length,
                    itemBuilder: (context, index) {
                      final job = myJobs[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(job.categoryEmoji, style: const TextStyle(fontSize: 16)),
                        ),
                        title: Text(
                          job.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: innerIsDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          job.formattedBudget,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _attachedJob = job;
                          });
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
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
                  if (pollOptionControllers.length > AppConstants.minPollOptions) ...[
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
          if (pollOptionControllers.length < AppConstants.maxPollOptions)
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
        color: isDark ? AppTheme.darkBg : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
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
                            child: UserAvatar.fromUsername(
                              avatarUrl: widget.currentUser?.avatarUrl,
                              username: widget.currentUser?.username ?? '',
                              size: 36,
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

                      // Attached Job Preview
                      if (_attachedJob != null) ...[
                        PostJobCard(
                          job: _attachedJob!,
                          onDelete: () {
                            setState(() {
                              _attachedJob = null;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

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
                          const SizedBox(width: 12),
                          _buildToolbarIcon(
                            icon: Icons.work_outline_rounded,
                            isActive: _attachedJob != null,
                            onTap: _selectAndAttachJob,
                            isDark: isDark,
                            tooltip: 'Прикрепить заказ',
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
