import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/job_model.dart';
import '../services/job_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'user_profile_screen.dart';
import '../widgets/multi_image_slider.dart';
import 'create_job_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final JobModel job;

  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isProcessing = false;

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
          if (isMyJob)
            IconButton(
              icon: Icon(
                Icons.edit_rounded,
                color: isDark ? Colors.white : Colors.black,
                size: 20,
              ),
              onPressed: () async {
                final result = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => CreateJobScreen(jobToEdit: widget.job),
                );
                if (result == true && mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),
        ],
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMyJob && widget.job.status == 'rejected') ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.3),
                          width: 1,
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
                  if (isMyJob && widget.job.status == 'pending') ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                          width: 1,
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
                  if (widget.job.imageUrls.isNotEmpty) ...[
                    MultiImageSlider(
                      imageUrls: widget.job.imageUrls,
                      aspectRatio: 16 / 10,
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.job.categoryEmoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.job.categoryName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    widget.job.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Publish Date
                  Text(
                    'Опубликовано: $timeString',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Budget Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.success.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Предлагаемый бюджет',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success.withValues(alpha: 0.8),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.job.formattedBudget,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description title
                  Text(
                    'Описание задачи',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description content
                  Text(
                    widget.job.description,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF3A3A3C),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Author Header Card
                  Text(
                    'Заказчик',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                            backgroundImage: widget.job.userAvatarUrl != null &&
                                    widget.job.userAvatarUrl!.isNotEmpty
                                ? NetworkImage(widget.job.userAvatarUrl!)
                                : null,
                            child: widget.job.userAvatarUrl == null || widget.job.userAvatarUrl!.isEmpty
                                ? Text(
                                    widget.job.userEmojiAvatar ?? '👤',
                                    style: const TextStyle(fontSize: 20),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${widget.job.userFirstName} ${widget.job.userLastName}'.trim(),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    if (widget.job.userIsVerified) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.verified,
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
                                    fontSize: 13,
                                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Actions
                  if (isMyJob) ...[
                    // Management Options for Author
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _closeJob(context),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                            label: const Text('Закрыть заказ'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.success,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
                    // Contact Buttons for viewer
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _launchPhone(context, widget.job.contactPhone),
                            icon: const Icon(Icons.phone_rounded, size: 18),
                            label: const Text('Позвонить'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if (widget.job.contactTelegram != null && widget.job.contactTelegram!.trim().isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _launchTelegram(context, widget.job.contactTelegram),
                              icon: const Icon(Icons.send_rounded, size: 18),
                              label: const Text('Telegram'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2EA6DA),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
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
