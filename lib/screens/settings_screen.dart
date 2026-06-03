import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/password_strength_indicator.dart';
import '../widgets/top_notification.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Настройки',
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
                // SECTION: ACCOUNT SETTINGS LINK
                _buildSectionHeader(theme, 'Профиль & Безопасность'),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Управление аккаунтом',
                  subtitle: 'Изменение логина и адреса e-mail',
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AccountSettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Пароль и безопасность',
                  subtitle: 'Смена пароля и восстановление доступа',
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SecuritySettingsScreen(),
                      ),
                    );
                  },
                ),



                // SECTION: THEME SWITCHER
                _buildSectionHeader(theme, 'Оформление'),
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
                    child: Consumer<ThemeService>(
                      builder: (context, themeService, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isDark
                                      ? Icons.dark_mode_rounded
                                      : Icons.light_mode_rounded,
                                  color: AppTheme.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Тема приложения',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(3),
                              child: Row(
                                children: [
                                  _buildThemeOption(
                                    context: context,
                                    icon: Icons.light_mode_rounded,
                                    label: 'Светлая',
                                    isSelected:
                                        themeService.themeMode ==
                                        ThemeMode.light,
                                    isDark: isDark,
                                    onTap: () => themeService.setThemeMode(
                                      ThemeMode.light,
                                    ),
                                  ),
                                  _buildThemeOption(
                                    context: context,
                                    icon: Icons.dark_mode_rounded,
                                    label: 'Тёмная',
                                    isSelected:
                                        themeService.themeMode ==
                                        ThemeMode.dark,
                                    isDark: isDark,
                                    onTap: () => themeService.setThemeMode(
                                      ThemeMode.dark,
                                    ),
                                  ),
                                  _buildThemeOption(
                                    context: context,
                                    icon: Icons.settings_suggest_rounded,
                                    label: 'Системная',
                                    isSelected:
                                        themeService.themeMode ==
                                        ThemeMode.system,
                                    isDark: isDark,
                                    onTap: () => themeService.setThemeMode(
                                      ThemeMode.system,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // LOGOUT BUTTON
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Выйти из профиля?'),
                          content: const Text(
                            'Вы уверены, что хотите выйти из своего аккаунта?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Отмена'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Выйти',
                                style: TextStyle(
                                  color: AppTheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        final authService = Provider.of<AuthService>(
                          context,
                          listen: false,
                        );
                        await authService.signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error, width: 1.0),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text(
                      'Выйти из профиля',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Card(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          width: 0.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? AppTheme.textSecondaryDark
                : AppTheme.textSecondaryLight,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: isDark ? Colors.white30 : Colors.black38,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? AppTheme.primary.withValues(alpha: 0.2)
                      : AppTheme.primary.withValues(alpha: 0.12))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    width: 1,
                  )
                : Border.all(color: Colors.transparent, width: 1),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? AppTheme.primary
                    : (isDark ? Colors.white54 : Colors.black45),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppTheme.primary
                      : (isDark ? Colors.white54 : Colors.black45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// SUBSCREEN 1: ACCOUNT SETTINGS
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _emailKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isEmailValid = false;
  String? _emailSuccessMessage;

  final _usernameKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  bool _isUsernameValid = false;
  String? _usernameSuccessMessage;

  final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );
  final RegExp _usernameRegex = RegExp(r"^[a-zA-Z0-9_]{3,20}$");

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser != null) {
      _emailController.text = authService.currentUser!.email;
      _usernameController.text = authService.currentUser!.username;
    }
  }

  void _checkEmailValidation() {
    setState(() {
      _isEmailValid = _emailRegex.hasMatch(_emailController.text.trim());
    });
  }

  void _checkUsernameValidation() {
    final newUsername = _usernameController.text.trim();
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() {
      _isUsernameValid =
          _usernameRegex.hasMatch(newUsername) &&
          newUsername != authService.currentUser?.username;
    });
  }

  Future<void> _updateEmail() async {
    if (!_emailKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final newEmail = _emailController.text.trim();

    if (newEmail == authService.currentUser?.email) {
      TopNotification.show(
        context,
        message: 'Этот адрес почты уже установлен как текущий',
        icon: Icons.warning_amber_rounded,
        iconColor: AppTheme.warning,
      );
      return;
    }

    final localContext = context;
    final success = await authService.changeEmail(newEmail: newEmail);
    if (!localContext.mounted) return;
    if (success) {
      setState(() {
        if (authService.isMockMode) {
          _emailSuccessMessage = 'Email успешно изменен на $newEmail';
        } else {
          _emailSuccessMessage =
              'Ссылка подтверждения отправлена на $newEmail. Пожалуйста, подтвердите её для завершения смены почты.';
        }
      });
      TopNotification.show(
        localContext,
        message: authService.isMockMode
            ? 'Адрес почты обновлен!'
            : 'Подтвердите смену почты по ссылке из письма!',
        icon: Icons.check_circle_outline_rounded,
        iconColor: AppTheme.success,
      );
    }
  }

  Future<void> _updateUsername() async {
    if (!_usernameKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final newUsername = _usernameController.text.trim();

    final localContext = context;
    final success = await authService.changeUsername(newUsername: newUsername);
    if (!localContext.mounted) return;
    if (success) {
      setState(() {
        _usernameSuccessMessage = 'Логин успешно изменен на $newUsername';
        _isUsernameValid = false;
      });
      TopNotification.show(
        localContext,
        message: 'Логин успешно обновлен!',
        icon: Icons.check_circle_outline_rounded,
        iconColor: AppTheme.success,
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
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
          'Управление аккаунтом',
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

                // SECTION 1: CHANGE EMAIL
                _buildSectionHeader(theme, 'Безопасность e-mail'),
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
                      key: _emailKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_emailSuccessMessage != null) ...[
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
                                _emailSuccessMessage!,
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
                            controller: _emailController,
                            labelText: 'Новый E-mail',
                            hintText: 'example@domain.com',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            isValidated: _isEmailValid,
                            onChanged: (val) => _checkEmailValidation(),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Введите e-mail';
                              }
                              if (!_emailRegex.hasMatch(val.trim())) {
                                return 'Некорректный e-mail';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 52,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: authService.isLoading || !_isEmailValid
                                  ? null
                                  : _updateEmail,
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
                                      'Изменить E-mail',
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

                const SizedBox(height: 32),

                // SECTION: CHANGE USERNAME
                _buildSectionHeader(theme, 'Логин пользователя'),
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
                      key: _usernameKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_usernameSuccessMessage != null) ...[
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
                                _usernameSuccessMessage!,
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
                            controller: _usernameController,
                            labelText: 'Новый логин',
                            hintText: 'username_dev',
                            prefixIcon: Icons.alternate_email_rounded,
                            isValidated: _isUsernameValid,
                            onChanged: (val) => _checkUsernameValidation(),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Введите логин';
                              }
                              if (!_usernameRegex.hasMatch(val.trim())) {
                                return '3-20 символов: латиница, цифры и _';
                              }
                              if (val.trim() ==
                                  authService.currentUser?.username) {
                                return 'Введите логин, отличный от текущего';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 52,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  authService.isLoading || !_isUsernameValid
                                  ? null
                                  : _updateUsername,
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
                                      'Изменить логин',
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

// SUBSCREEN 2: SECURITY SETTINGS
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
      RegExp(r'[!@#\$%^&*(),.?":{}|<>]'),
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
