import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/password_strength_indicator.dart';
import '../widgets/top_notification.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final _passwordKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isCurrentPasswordValid = false;
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;
  String? _passwordSuccessMessage;

  void _checkPasswordValidation() {
    final currentPassword = _currentPasswordController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final hasMinLength = password.length >= 8;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(
      RegExp(r'[!@#\$%^\&*(),.?":{}|<>]'),
    );

    setState(() {
      _isCurrentPasswordValid = currentPassword.isNotEmpty;
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

  Future<void> _updatePassword() async {
    if (!_passwordKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final localContext = context;
    final success = await authService.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _passwordController.text,
    );

    if (!localContext.mounted) return;
    if (success) {
      setState(() {
        _passwordSuccessMessage = 'Пароль успешно изменен!';
        _currentPasswordController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _isCurrentPasswordValid = false;
        _isPasswordValid = false;
        _isConfirmPasswordValid = false;
      });
      TopNotification.show(
        localContext,
        message: 'Пароль успешно изменен!',
        icon: Icons.check_circle_outline_rounded,
        iconColor: AppTheme.success,
      );
    }
  }

  Future<void> _forgotPassword() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final email = authService.currentUser?.email;
    if (email == null) return;

    final localContext = context;
    final confirm = await showDialog<bool>(
      context: localContext,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить пароль?'),
        content: Text(
          'Отправить ссылку для сброса пароля на вашу почту $email?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Отправить',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await authService.sendPasswordReset(email: email);
      if (!localContext.mounted) return;
      if (success) {
        setState(() {
          _passwordSuccessMessage =
              'Ссылка для сброса пароля отправлена на вашу почту!';
        });
        TopNotification.show(
          localContext,
          message: 'Ссылка для сброса пароля отправлена!',
          icon: Icons.check_circle_outline_rounded,
          iconColor: AppTheme.success,
        );
      }
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
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
      appBar: AppBar(
        title: const Text(
          'Пароль и безопасность',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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

                // SECTION 2: CHANGE PASSWORD
                _buildSectionHeader(theme, 'Безопасность пароля'),
                const SizedBox(height: 12),
                Card(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark
                          ? AppTheme.borderDark
                          : AppTheme.borderLight,
                      width: 0.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _passwordKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_passwordSuccessMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.success,
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                _passwordSuccessMessage!,
                                style: const TextStyle(
                                  color: AppTheme.success,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          CustomTextField(
                            controller: _currentPasswordController,
                            labelText: 'Текущий пароль',
                            hintText: 'Введите текущий пароль',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                            isValidated: _isCurrentPasswordValid,
                            onChanged: (val) => _checkPasswordValidation(),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Введите текущий пароль';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            controller: _passwordController,
                            labelText: 'Новый пароль',
                            hintText: '••••••••',
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
                            hintText: '••••••••',
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
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: authService.isLoading
                                  ? null
                                  : _forgotPassword,
                              child: const Text('Забыли пароль?'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          PasswordStrengthIndicator(
                            password: _passwordController.text,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 52,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  authService.isLoading ||
                                      !_isCurrentPasswordValid ||
                                      !_isPasswordValid ||
                                      !_isConfirmPasswordValid
                                  ? null
                                  : _updatePassword,
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
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Изменить пароль',
                                      style: TextStyle(
                                        fontSize: 15,
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
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.brightness == Brightness.dark
              ? Colors.white70
              : Colors.black87,
        ),
      ),
    );
  }
}
