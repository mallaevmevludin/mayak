import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_theme.dart';

/// Единая «шапка» экрана в стиле iOS — заголовок-плашка слева и
/// опциональные действия справа. Заменяет скопированные вручную шапки
/// в ленте, вакансиях, профиле и поиске.
class AppHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;

  const AppHeader({
    super.key,
    required this.title,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs + 2,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: AppRadius.controlR,
              boxShadow: AppShadows.soft(isDark),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.appTextPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const Spacer(),
          ...actions,
        ],
      ),
    );
  }
}

/// Круглая кнопка-действие для [AppHeader] — единый вид «таблеток» справа.
class AppHeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const AppHeaderAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(left: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: AppRadius.controlR,
          boxShadow: AppShadows.soft(isDark),
        ),
        child: Icon(icon, color: iconColor ?? AppTheme.primary, size: 22),
      ),
    );
  }
}
