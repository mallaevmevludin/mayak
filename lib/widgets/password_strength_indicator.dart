import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  bool get hasMinLength => password.length >= 8;
  bool get hasUppercase => password.contains(RegExp(r'[A-Z]'));
  bool get hasLowercase => password.contains(RegExp(r'[a-z]'));
  bool get hasDigits => password.contains(RegExp(r'[0-9]'));
  bool get hasSpecialChar =>
      password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));

  double get strengthPercent {
    int score = 0;
    if (hasMinLength) score++;
    if (hasUppercase) score++;
    if (hasLowercase) score++;
    if (hasDigits) score++;
    if (hasSpecialChar) score++;
    return score / 5.0;
  }

  Color get strengthColor {
    final percent = strengthPercent;
    if (percent <= 0.2) return AppTheme.error;
    if (percent <= 0.6) return AppTheme.warning;
    return AppTheme.success;
  }

  String get strengthText {
    final percent = strengthPercent;
    if (password.isEmpty) return 'Введите пароль';
    if (percent <= 0.2) return 'Очень слабый';
    if (percent <= 0.6) return 'Средний';
    if (percent <= 0.8) return 'Надежный';
    return 'Очень надежный';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Сложность пароля:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
              ),
            ),
            Text(
              strengthText,
              style: TextStyle(
                color: strengthColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: strengthPercent,
            backgroundColor: isDark
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFE5E5EA),
            color: strengthColor,
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 12),
        // Requirements checklist
        _buildRequirementRow('Не менее 8 символов', hasMinLength, context),
        const SizedBox(height: 6),
        _buildRequirementRow('Прописная буква (A-Z)', hasUppercase, context),
        const SizedBox(height: 6),
        _buildRequirementRow('Строчная буква (a-z)', hasLowercase, context),
        const SizedBox(height: 6),
        _buildRequirementRow('Цифра (0-9)', hasDigits, context),
        const SizedBox(height: 6),
        _buildRequirementRow(
          'Спец. символ (!@#\$%...)',
          hasSpecialChar,
          context,
        ),
      ],
    );
  }

  Widget _buildRequirementRow(String text, bool isMet, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isMet
                ? AppTheme.success.withValues(alpha: 0.15)
                : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
          ),
          child: Icon(
            isMet ? Icons.check : Icons.close,
            size: 14,
            color: isMet
                ? AppTheme.success
                : (isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 12,
            color: isMet
                ? (isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight)
                : (isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight),
            decoration: isMet ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }
}
