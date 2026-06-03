import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/top_notification.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoginValid = false;
  bool _isPasswordValid = false;

  void _checkValidation() {
    setState(() {
      _isLoginValid = _loginController.text.trim().isNotEmpty;
      _isPasswordValid = _passwordController.text.length >= 6;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.loginUser(
      emailOrUsername: _loginController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  Future<void> _forgotPassword() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final inputEmail = _loginController.text.trim();

    final RegExp emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    String targetEmail = '';

    if (emailRegex.hasMatch(inputEmail)) {
      targetEmail = inputEmail;
    }

    final TextEditingController emailDialogController = TextEditingController(
      text: targetEmail,
    );
    final emailFormKey = GlobalKey<FormState>();

    final emailToReset = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Восстановление пароля'),
        content: Form(
          key: emailFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Введите ваш E-mail, и мы отправим ссылку для сброса пароля.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailDialogController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  hintText: 'example@domain.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Введите e-mail';
                  }
                  if (!emailRegex.hasMatch(val.trim())) {
                    return 'Некорректный e-mail';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (emailFormKey.currentState!.validate()) {
                Navigator.pop(context, emailDialogController.text.trim());
              }
            },
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

    if (emailToReset != null && emailToReset.isNotEmpty) {
      final success = await authService.sendPasswordReset(email: emailToReset);
      if (success && mounted) {
        TopNotification.show(
          context,
          message: authService.isMockMode
              ? 'Ссылка для сброса пароля отправлена (тестовый режим)!'
              : 'Ссылка для сброса пароля отправлена на почту $emailToReset!',
          icon: Icons.check_circle_outline_rounded,
          iconColor: AppTheme.success,
        );
      } else if (mounted) {
        TopNotification.show(
          context,
          message: authService.errorMessage ?? 'Ошибка отправки запроса',
          icon: Icons.error_outline_rounded,
          iconColor: AppTheme.error,
        );
      }
    }
  }

  void _autofillMockCredentials() {
    setState(() {
      _loginController.text = 'ivanov';
      _passwordController.text = 'Password123!';
      _isLoginValid = true;
      _isPasswordValid = true;
    });
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Clean top icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary,
                    ),
                    child: const Icon(
                      Icons.lock_person_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Рады видеть вас!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Войдите в свой аккаунт для продолжения',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                // Mock Mode Info Banner
                if (authService.isMockMode) ...[
                  Card(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: AppTheme.warning,
                        width: 0.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppTheme.warning,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Запущен тестовый режим (Supabase не настроен). Данные сохраняются локально.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.warning.withValues(
                                alpha: 0.2,
                              ),
                              foregroundColor: AppTheme.warning,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.flash_on_rounded, size: 18),
                            label: const Text('Заполнить тестовые данные'),
                            onPressed: _autofillMockCredentials,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Error Message banner
                if (authService.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.error, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            authService.errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _loginController,
                        labelText: 'Почта или Логин',
                        hintText: 'Введите почту или логин',
                        prefixIcon: Icons.person_outline_rounded,
                        isValidated: _isLoginValid,
                        onChanged: (val) {
                          _checkValidation();
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите адрес почты или логин';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      CustomTextField(
                        controller: _passwordController,
                        labelText: 'Пароль',
                        hintText: 'Введите пароль',
                        prefixIcon: Icons.lock_outline_rounded,
                        isPassword: true,
                        isValidated: _isPasswordValid,
                        onChanged: (val) {
                          _checkValidation();
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите пароль';
                          }
                          if (value.length < 6) {
                            return 'Пароль должен содержать от 6 символов';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: authService.isLoading ? null : _forgotPassword,
                    child: const Text('Забыли пароль?'),
                  ),
                ),
                const SizedBox(height: 24),

                // Solid Button
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authService.isLoading ? null : _submit,
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
                            'Войти',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Еще нет аккаунта?',
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text('Зарегистрироваться'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
