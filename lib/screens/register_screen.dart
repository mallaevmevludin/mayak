import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/password_strength_indicator.dart';
import '../widgets/top_notification.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Step 1 Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  // Step 2 Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Step 3 Controllers
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Global Keys for Form steps
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  // Validation States for real-time green checkmarks
  bool _isFirstNameValid = false;
  bool _isLastNameValid = false;
  bool _isUsernameValid = false;
  bool _isEmailValid = false;
  bool _isPhoneValid = false;
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;

  @override
  void initState() {
    super.initState();
    _phoneController.text = '+7 ';
  }

  // Modern Validation Regexes
  final RegExp _nameRegex = RegExp(r"^[a-zA-Zа-яА-ЯёЁ\s\-]{2,30}$");
  final RegExp _usernameRegex = RegExp(r"^[a-zA-Z0-9_]{3,20}$");
  final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );

  // Check validations dynamically
  void _checkStep1Validations() {
    setState(() {
      _isFirstNameValid = _nameRegex.hasMatch(_firstNameController.text.trim());
      _isLastNameValid = _nameRegex.hasMatch(_lastNameController.text.trim());
    });
  }

  void _checkStep2Validations() {
    setState(() {
      _isUsernameValid = _usernameRegex.hasMatch(
        _usernameController.text.trim(),
      );
      _isEmailValid = _emailRegex.hasMatch(_emailController.text.trim());

      // Phone is valid if it has 10 digits (excluding +7)
      final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      _isPhoneValid = digits.length == 11; // 7 + 10 digits
    });
  }

  void _checkStep3Validations() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Password criteria check
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

  void _nextStep() {
    if (_currentStep == 0) {
      if (_step1Key.currentState!.validate()) {
        setState(() => _currentStep++);
      }
    } else if (_currentStep == 1) {
      if (_step2Key.currentState!.validate()) {
        setState(() => _currentStep++);
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitRegister() async {
    if (!_step3Key.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.registerUser(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      TopNotification.show(
        context,
        message: 'Регистрация успешна!',
        icon: Icons.check_circle_outline_rounded,
        iconColor: AppTheme.success,
      );
      Navigator.pushReplacementNamed(context, '/profile');
    } else if (authService.pendingEmail != null && mounted) {
      Navigator.pushReplacementNamed(context, '/pending-verification');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
        title: const Text('Регистрация'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _currentStep > 0
              ? _prevStep
              : () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                // Custom Step Progress bar
                _buildStepProgressBar(isDark),
                const SizedBox(height: 32),

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
                  const SizedBox(height: 24),
                ],

                // Form Step views
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildFormStepContent(theme),
                ),

                const SizedBox(height: 40),

                // Step Navigation Action buttons
                Row(
                  children: [
                    if (_currentStep > 0) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: authService.isLoading ? null : _prevStep,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: isDark
                                  ? AppTheme.borderDark
                                  : AppTheme.borderLight,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Назад',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.textPrimaryDark
                                  : AppTheme.textPrimaryLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: authService.isLoading
                              ? null
                              : (_currentStep == _totalSteps - 1
                                    ? _submitRegister
                                    : _nextStep),
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
                              : Text(
                                  _currentStep == _totalSteps - 1
                                      ? 'Завершить'
                                      : 'Продолжить',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepProgressBar(bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_totalSteps, (index) {
            String stepTitle = '';
            if (index == 0) stepTitle = 'Личные';
            if (index == 1) stepTitle = 'Контакты';
            if (index == 2) stepTitle = 'Пароль';

            final isActive = index <= _currentStep;
            final isCurrent = index == _currentStep;

            return Expanded(
              child: Column(
                children: [
                  Text(
                    stepTitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isCurrent
                          ? AppTheme.primary
                          : (isActive
                                ? (isDark
                                      ? AppTheme.textPrimaryDark
                                      : AppTheme.textPrimaryLight)
                                : AppTheme.textSecondaryDark),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: isActive
                          ? AppTheme.primary
                          : (isDark
                                ? const Color(0xFF2C2C2E)
                                : const Color(0xFFE5E5EA)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFormStepContent(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return Form(
          key: _step1Key,
          child: Column(
            key: const ValueKey('step1'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Шаг 1: Личные данные',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _firstNameController,
                labelText: 'Имя',
                hintText: 'Иван',
                prefixIcon: Icons.person_outline_rounded,
                isValidated: _isFirstNameValid,
                onChanged: (val) => _checkStep1Validations(),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Имя обязательно';
                  if (!_nameRegex.hasMatch(val.trim()))
                    return 'Имя должно содержать 2-30 букв';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _lastNameController,
                labelText: 'Фамилия',
                hintText: 'Иванов',
                prefixIcon: Icons.people_outline_rounded,
                isValidated: _isLastNameValid,
                onChanged: (val) => _checkStep1Validations(),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Фамилия обязательна';
                  if (!_nameRegex.hasMatch(val.trim()))
                    return 'Фамилия должна содержать 2-30 букв';
                  return null;
                },
              ),
            ],
          ),
        );
      case 1:
        return Form(
          key: _step2Key,
          child: Column(
            key: const ValueKey('step2'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Шаг 2: Учетная запись',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _usernameController,
                labelText: 'Логин',
                hintText: 'ivanov_dev',
                prefixIcon: Icons.alternate_email_rounded,
                isValidated: _isUsernameValid,
                onChanged: (val) => _checkStep2Validations(),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Логин обязателен';
                  if (!_usernameRegex.hasMatch(val.trim())) {
                    return '3-20 символов: латиница, цифры и _';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _emailController,
                labelText: 'Эл. почта',
                hintText: 'ivan@example.com',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                isValidated: _isEmailValid,
                onChanged: (val) => _checkStep2Validations(),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Почта обязательна';
                  if (!_emailRegex.hasMatch(val.trim()))
                    return 'Введите корректный email';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _phoneController,
                labelText: 'Номер телефона',
                hintText: '+7 (999) 123-45-67',
                prefixIcon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                inputFormatters: [RussianPhoneTextInputFormatter()],
                isValidated: _isPhoneValid,
                onChanged: (val) => _checkStep2Validations(),
                validator: (val) {
                  if (val == null || val.trim().isEmpty || val == '+7 ') {
                    return 'Номер телефона обязателен';
                  }
                  final digits = val.replaceAll(RegExp(r'\D'), '');
                  if (digits.length != 11)
                    return 'Введите полный номер телефона';
                  return null;
                },
              ),
            ],
          ),
        );
      case 2:
        return Form(
          key: _step3Key,
          child: Column(
            key: const ValueKey('step3'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Шаг 3: Безопасность',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _passwordController,
                labelText: 'Пароль',
                hintText: '••••••••',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                isValidated: _isPasswordValid,
                onChanged: (val) => _checkStep3Validations(),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Пароль обязателен';
                  if (!_isPasswordValid) return 'Пароль недостаточно надежен';
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
                onChanged: (val) => _checkStep3Validations(),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Повторите пароль';
                  if (val != _passwordController.text)
                    return 'Пароли не совпадают';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              PasswordStrengthIndicator(password: _passwordController.text),
            ],
          ),
        );
      default:
        return Container();
    }
  }
}
