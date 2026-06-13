import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/job_model.dart';
import '../models/application_model.dart';
import '../services/job_service.dart';
import '../services/auth_service.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme.dart';
import '../widgets/pill_badge.dart';
import 'user_profile_screen.dart';
import '../widgets/multi_image_slider.dart';
import 'create_job_screen.dart';
import 'create_post_sheet.dart';
import '../widgets/user_avatar.dart';

class JobDetailScreen extends StatefulWidget {
  final JobModel job;

  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isProcessing = false;
  List<ApplicationModel> _applications = [];
  bool _isLoadingApplications = false;
  bool _hasApplied = false;
  ApplicationModel? _myApplication;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    final currentUserId = Provider.of<AuthService>(context, listen: false).currentUser?.id;
    final isMyJob = widget.job.userId == currentUserId;
    final jobService = Provider.of<JobService>(context, listen: false);

    if (isMyJob) {
      setState(() => _isLoadingApplications = true);
      final apps = await jobService.fetchApplicationsForJob(widget.job.id);
      if (mounted) {
        setState(() {
          _applications = apps;
          _isLoadingApplications = false;
        });
      }
    } else if (currentUserId != null) {
      final apps = await jobService.fetchApplicationsForJob(widget.job.id);
      if (mounted) {
        final myAppIndex = apps.indexWhere((app) => app.applicantId == currentUserId);
        setState(() {
          _hasApplied = myAppIndex != -1;
          _myApplication = myAppIndex != -1 ? apps[myAppIndex] : null;
        });
      }
    }
  }

  Future<void> _applyToJob() async {
    final jobService = Provider.of<JobService>(context, listen: false);
    setState(() => _isProcessing = true);
    final success = await jobService.applyToJob(widget.job.id);
    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        _showToast(context, 'Вы успешно откликнулись на заказ!');
        _loadApplications();
      } else {
        _showToast(context, 'Не удалось отправить отклик: ${jobService.errorMessage ?? "Неизвестная ошибка"}');
      }
    }
  }

  Future<void> _handleApplicationAction(ApplicationModel app, String status) async {
    final jobService = Provider.of<JobService>(context, listen: false);
    setState(() => _isProcessing = true);
    final success = await jobService.updateApplicationStatus(app.id, status);
    
    if (success && status == 'accepted' && mounted) {
      await jobService.updateJobStatus(widget.job.id, JobStatus.in_progress);
      if (mounted) {
        _showToast(context, 'Исполнитель принят. Статус заказа изменен на "В работе".');
      }
    } else if (success && mounted) {
      _showToast(context, status == 'accepted' ? 'Отклик принят!' : 'Отклик отклонен.');
    }
    
    if (mounted) {
      setState(() => _isProcessing = false);
      _loadApplications();
    }
  }

  Future<void> _changeJobStatus(BuildContext context, JobStatus status, String title, String content) async {
    final jobService = Provider.of<JobService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              status == JobStatus.completed ? 'Завершить' : 'Подтвердить',
              style: TextStyle(color: status == JobStatus.completed ? AppTheme.success : AppTheme.primary),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isProcessing = true);
    final success = await jobService.updateJobStatus(widget.job.id, status);
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Статус заказа успешно изменен на "${status == JobStatus.completed ? "Выполнено" : status == JobStatus.in_progress ? "В работе" : "Закрыто"}"')),
      );
      navigator.pop(true);
    }
  }

  Future<void> _launchPhone(BuildContext context, String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      if (!context.mounted) return;
      _showToast(context, 'Номер телефона не указан');
      return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching phone: $e');
      if (!context.mounted) return;
      _showToast(context, 'Не удалось совершить вызов: $e');
    }
  }

  Future<void> _launchTelegram(BuildContext context, String? username) async {
    if (username == null || username.trim().isEmpty) {
      if (!context.mounted) return;
      _showToast(context, 'Telegram аккаунт не указан');
      return;
    }
    var cleanTg = username.trim();
    if (cleanTg.startsWith('@')) {
      cleanTg = cleanTg.substring(1);
    }
    if (cleanTg.startsWith('http://t.me/') || cleanTg.startsWith('https://t.me/')) {
      // already url
    } else {
      cleanTg = 'https://t.me/$cleanTg';
    }
    final uri = Uri.parse(cleanTg);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching telegram: $e');
      if (!context.mounted) return;
      _showToast(context, 'Не удалось открыть Telegram: $e');
    }
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _shareToCommunity(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CreatePostSheet(
          currentUser: currentUser,
          initialJob: widget.job,
        );
      },
    );
  }

  Future<void> _closeJob(BuildContext context) async {
    final jobService = Provider.of<JobService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Закрыть заказ?'),
        content: const Text('Заказ будет помечен как закрытый и перестанет отображаться в общей ленте.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Закрыть', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isProcessing = true);
    final success = await jobService.closeJob(widget.job.id);
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Заказ успешно закрыт')),
      );
      navigator.pop();
    }
  }

  Future<void> _deleteJob(BuildContext context) async {
    final jobService = Provider.of<JobService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить заказ?'),
        content: const Text('Это действие нельзя отменить. Заказ будет полностью удален.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isProcessing = true);
    final success = await jobService.deleteJob(widget.job.id);
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Заказ успешно удален')),
      );
      navigator.pop();
    }
  }

  Widget _buildApplicationsSection(bool isDark) {
    if (_isLoadingApplications) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_applications.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.cardBorderDark : AppTheme.lightSurface,
            width: 1.0,
          ),
        ),
        child: const Center(
          child: Text(
            'Откликов пока нет.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _applications.map((app) {
        final statusColor = app.status == 'accepted'
            ? AppTheme.success
            : app.status == 'declined'
                ? AppTheme.error
                : Colors.orange;
                
        final statusText = app.status == 'accepted'
            ? 'Принят'
            : app.status == 'declined'
                ? 'Отклонен'
                : 'Ожидает решения';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.cardBorderDark : AppTheme.lightSurface,
              width: 1.0,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  UserAvatar(
                    avatarUrl: app.applicantAvatarUrl,
                    fallbackInitial: app.applicantEmojiAvatar?.isNotEmpty == true
                        ? app.applicantEmojiAvatar!
                        : (app.applicantFirstName.isNotEmpty ? app.applicantFirstName[0] : '👤'),
                    size: 36,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${app.applicantFirstName} ${app.applicantLastName}'.trim(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (app.applicantIsVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, color: AppTheme.primary, size: 12),
                            ],
                          ],
                        ),
                        Text(
                          '@${app.applicantUsername}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              if (app.status == 'pending') ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _handleApplicationAction(app, 'declined'),
                      child: const Text('Отклонить', style: TextStyle(color: AppTheme.error, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _handleApplicationAction(app, 'accepted'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Принять', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUserId = Provider.of<AuthService>(context).currentUser?.id;
    final isMyJob = widget.job.userId == currentUserId;

    final String timeString = '${widget.job.createdAt.day}.${widget.job.createdAt.month}.${widget.job.createdAt.year}';

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Детали заказа',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.share_rounded,
              color: isDark ? Colors.white : Colors.black,
              size: 20,
            ),
            onPressed: () => _shareToCommunity(context),
          ),
          if (isMyJob)
            IconButton(
              icon: Icon(
                Icons.edit_rounded,
                color: isDark ? Colors.white : Colors.black,
                size: 20,
              ),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final result = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => CreateJobScreen(jobToEdit: widget.job),
                );
                if (result == true) {
                  navigator.pop(true);
                }
              },
            ),
        ],
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status warnings if mine
                  if (isMyJob && widget.job.status == JobStatus.rejected) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Заказ отклонен модератором',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.job.rejectionComment != null && widget.job.rejectionComment!.trim().isNotEmpty
                                ? 'Причина: ${widget.job.rejectionComment}'
                                : 'Причина не указана. Отредактируйте заказ и отправьте на проверку снова.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF3A3A3C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isMyJob && widget.job.status == JobStatus.pending) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.watch_later_outlined, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Заказ на проверке',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Этот заказ проверяется модератором и пока не виден другим пользователям.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF3A3A3C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Images
                  if (widget.job.imageUrls.isNotEmpty) ...[
                    MultiImageSlider(
                      imageUrls: widget.job.imageUrls,
                      aspectRatio: 1.6,
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Badges
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      PillBadge(
                        emoji: widget.job.categoryEmoji,
                        label: widget.job.categoryName,
                        accent: AppTheme.primary,
                      ),
                      PillBadge(
                        emoji: '📍',
                        label: widget.job.formattedLocation,
                        accent: AppTheme.warning,
                      ),
                      PillBadge(
                        emoji: '💼',
                        label: widget.job.workTypeName,
                        accent: AppTheme.primary,
                      ),
                      if (widget.job.status != JobStatus.active)
                        PillBadge(
                          emoji: widget.job.status == JobStatus.in_progress
                              ? '🔄'
                              : widget.job.status == JobStatus.completed
                                  ? '✅'
                                  : widget.job.status == JobStatus.rejected
                                      ? '❌'
                                      : '📁',
                          label: widget.job.status == JobStatus.in_progress
                              ? 'В работе'
                              : widget.job.status == JobStatus.completed
                                  ? 'Выполнено'
                                  : widget.job.status == JobStatus.rejected
                                      ? 'Отклонен'
                                      : 'Закрыт',
                          accent: widget.job.status == JobStatus.in_progress
                              ? AppTheme.primary
                              : widget.job.status == JobStatus.completed
                                  ? AppTheme.success
                                  : widget.job.status == JobStatus.rejected
                                      ? AppTheme.error
                                      : AppTheme.textSecondaryDark,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Title
                  Text(
                    widget.job.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Publish Date
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Опубликовано: $timeString',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Budget Container Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.successBgDark : AppTheme.successBgLight,
                      borderRadius: AppRadius.cardR,
                      border: Border.all(
                        color: AppTheme.success.withValues(alpha: 0.2),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'БЮДЖЕТ ЗАКАЗА',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.success.withValues(alpha: 0.7),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.job.formattedBudget,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.success,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.payments_rounded,
                            color: AppTheme.success,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description Card Container
                  Text(
                    'Описание задачи',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppTheme.cardBorderDark : AppTheme.lightSurface,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      widget.job.description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Contacts Card Container (always visible inside detail screen)
                  if ((widget.job.contactPhone != null && widget.job.contactPhone!.trim().isNotEmpty) ||
                      (widget.job.contactTelegram != null && widget.job.contactTelegram!.trim().isNotEmpty)) ...[
                    Text(
                      'Контакты для связи',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppTheme.cardBorderDark : AppTheme.lightSurface,
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          if (widget.job.contactPhone != null && widget.job.contactPhone!.trim().isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(Icons.phone_rounded, size: 18, color: isDark ? Colors.white70 : AppTheme.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.job.contactPhone!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _launchPhone(context, widget.job.contactPhone),
                                  child: Text(
                                    'Позвонить',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.white70 : AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (widget.job.contactTelegram != null && widget.job.contactTelegram!.trim().isNotEmpty)
                              Divider(
                                height: 24,
                                thickness: 0.5,
                                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                              ),
                          ],
                          if (widget.job.contactTelegram != null && widget.job.contactTelegram!.trim().isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.send_rounded, size: 16, color: Color(0xFF24A1DE)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.job.contactTelegram!.startsWith('@')
                                        ? widget.job.contactTelegram!
                                        : '@${widget.job.contactTelegram!}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _launchTelegram(context, widget.job.contactTelegram),
                                  child: const Text(
                                    'Telegram',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF24A1DE),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Customer/Author Card
                  Text(
                    'Заказчик',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(userId: widget.job.userId),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppTheme.cardBorderDark : AppTheme.lightSurface,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          UserAvatar(
                            avatarUrl: widget.job.userAvatarUrl,
                            fallbackInitial: widget.job.userEmojiAvatar?.isNotEmpty == true
                                ? widget.job.userEmojiAvatar!
                                : (widget.job.userFirstName.isNotEmpty
                                    ? widget.job.userFirstName[0].toUpperCase()
                                    : '👤'),
                            size: 44,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '${widget.job.userFirstName} ${widget.job.userLastName}'.trim(),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (widget.job.userIsVerified) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.verified_rounded,
                                        color: AppTheme.primary,
                                        size: 14,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '@${widget.job.userUsername}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: isDark ? Colors.white30 : Colors.black26,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Applicants list (Visible to Job Owner)
                  if (isMyJob) ...[
                    Text(
                      'Отклики исполнителей',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildApplicationsSection(isDark),
                    const SizedBox(height: 20),
                  ],

                  // Bottom Action Buttons
                  if (isMyJob) ...[
                    Row(
                      children: [
                        if (widget.job.status == JobStatus.active)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _closeJob(context),
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.white),
                              label: const Text('Закрыть заказ'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          )
                        else if (widget.job.status == JobStatus.in_progress)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _changeJobStatus(context, JobStatus.completed, 'Завершить заказ?', 'Пометить этот заказ как успешно выполненный?'),
                              icon: const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                              label: const Text('Завершить работу'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                widget.job.status == JobStatus.completed ? 'Заказ выполнен' : 'Заказ закрыт',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => _deleteJob(context),
                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.error.withValues(alpha: 0.1),
                            padding: const EdgeInsets.all(14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.job.status == JobStatus.active) ...[
                          if (_hasApplied)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _myApplication?.status == 'accepted'
                                    ? AppTheme.success.withValues(alpha: 0.12)
                                    : _myApplication?.status == 'declined'
                                        ? AppTheme.error.withValues(alpha: 0.12)
                                        : AppTheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _myApplication?.status == 'accepted'
                                      ? AppTheme.success
                                      : _myApplication?.status == 'declined'
                                          ? AppTheme.error
                                          : AppTheme.primary,
                                  width: 1.0,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _myApplication?.status == 'accepted'
                                    ? 'Ваш отклик принят!'
                                    : _myApplication?.status == 'declined'
                                        ? 'Ваш отклик отклонен'
                                        : 'Вы откликнулись (Ожидание решения)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _myApplication?.status == 'accepted'
                                      ? AppTheme.success
                                      : _myApplication?.status == 'declined'
                                          ? AppTheme.error
                                          : AppTheme.primary,
                                ),
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: _applyToJob,
                              icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                              label: const Text('Откликнуться на заказ'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            // Call Button
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _launchPhone(context, widget.job.contactPhone),
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF2F2F7),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.phone_rounded, size: 18, color: isDark ? Colors.white : AppTheme.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Позвонить',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : AppTheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (widget.job.contactTelegram != null && widget.job.contactTelegram!.trim().isNotEmpty) ...[
                              const SizedBox(width: 12),
                              // Telegram Button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _launchTelegram(context, widget.job.contactTelegram),
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF2EA6DA),
                                          Color(0xFF2693CD),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF2EA6DA).withValues(alpha: 0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Telegram',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
