import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/password_strength_indicator.dart';
import '../widgets/top_notification.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;

  void _checkPasswordValidation() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Requirements
    final hasMinLength = password.length >= 8;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(
      RegExp(r'[!@#\$%^&*(),.?":{}|<>]'),
    );

    setState(() {
      _isPasswordValid =
          hasMinLength &&
          hasUppercase &&
          hasLowercase &&
          hasDigits &&
          hasSpecialChar;
      _isConfirmPasswordValid =
          confirmPassword.isNotEmpty && password == confirmPassword;
    });
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.completePasswordRecovery(
      newPassword: _passwordController.text,
    );

    if (success && mounted) {
      TopNotification.show(
        context,
        message: 'Новый пароль успешно сохранен!',
        icon: Icons.check_circle_outline_rounded,
        iconColor: AppTheme.success,
      );
    }
  }

  Future<void> _cancel() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.cancelPasswordRecovery();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text('Сброс пароля'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: authService.isLoading ? null : _cancel,
            child: const Text(
              'Отмена',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Новый пароль',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Введите новый пароль для доступа к вашей учетной записи.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error banner
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
                            Icons.error_outline_rounded,
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
                    const SizedBox(height: 24),
                  ],

                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Новый пароль',
                    hintText: 'Не менее 8 символов',
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    isValidated: _isPasswordValid,
                    onChanged: (val) => _checkPasswordValidation(),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Введите новый пароль';
                      }
                      if (!_isPasswordValid) {
                        return 'Пароль не соответствует требованиям';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Подтвердите пароль',
                    hintText: 'Повторите пароль',
                    prefixIcon: Icons.lock_reset_rounded,
                    isPassword: true,
                    isValidated: _isConfirmPasswordValid,
                    onChanged: (val) => _checkPasswordValidation(),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Повторите пароль';
                      }
                      if (val != _passwordController.text) {
                        return 'Пароли не совпадают';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  PasswordStrengthIndicator(password: _passwordController.text),
                  const SizedBox(height: 36),

                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          authService.isLoading ||
                              !_isPasswordValid ||
                              !_isConfirmPasswordValid
                          ? null
                          : _savePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.primary.withValues(
                          alpha: 0.4,
                        ),
                        disabledForegroundColor: Colors.white.withValues(
                          alpha: 0.6,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: authService.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Сохранить пароль',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
