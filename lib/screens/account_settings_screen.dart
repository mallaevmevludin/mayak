import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/top_notification.dart';

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
