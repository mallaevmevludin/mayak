import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/top_notification.dart';

class PendingVerificationScreen extends StatelessWidget {
  const PendingVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final email = authService.pendingEmail ?? 'вашу почту';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Clean email icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_rounded,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              Text(
                'Подтвердите e-mail',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'Для завершения регистрации необходимо подтвердить адрес электронной почты. Мы отправили письмо со ссылкой на:',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // Highlighted Email Box
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkSurface
                      : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                    width: 1,
                  ),
                ),
                child: Text(
                  email,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Пожалуйста, откройте письмо и перейдите по ссылке активации, после чего вернитесь в приложение и нажмите кнопку ниже.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 32),

              // Error banner if verification fails
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
                        Icons.warning_amber_rounded,
                        color: AppTheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authService.errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Check button
              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authService.isLoading
                      ? null
                      : () async {
                          final success = await authService
                              .verifyAndLoginPending();
                          if (success && context.mounted) {
                            TopNotification.show(
                              context,
                              message: 'Почта подтверждена! Добро пожаловать.',
                              icon: Icons.check_circle_outline_rounded,
                              iconColor: AppTheme.success,
                            );
                            Navigator.pushReplacementNamed(context, '/profile');
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: authService.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Я подтвердил почту',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Restart registration button
              OutlinedButton.icon(
                onPressed: authService.isLoading
                    ? null
                    : () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Начать заново?'),
                            content: const Text(
                              'Вы хотите отменить эту регистрацию и заполнить данные заново?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Отмена'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Начать заново',
                                  style: TextStyle(color: AppTheme.error),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await authService.clearPendingVerification();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        }
                      },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Заполнить данные заново'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
