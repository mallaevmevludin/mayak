import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Единая система размеров (дизайн-токены), чтобы убрать «магические числа»
/// и разнобой скруглений/отступов/теней по экранам.

/// Отступы по сетке 4pt.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  /// Стандартный горизонтальный отступ контента от краёв экрана.
  static const double screenH = 16.0;

  /// Нижний отступ скролл-контента, чтобы он не уезжал под плавающий навбар.
  static const double bottomNavClearance = 120.0;
}

/// Единая шкала скруглений.
class AppRadius {
  AppRadius._();

  static const double chip = 10.0; // бейджи, чипы, мелкие плашки
  static const double control = 12.0; // кнопки, поля ввода
  static const double card = 16.0; // карточки (посты, вакансии, результаты)
  static const double sheet = 24.0; // нижние шторки и модалки
  static const double full = 999.0; // полностью круглые элементы

  static BorderRadius get chipR => BorderRadius.circular(chip);
  static BorderRadius get controlR => BorderRadius.circular(control);
  static BorderRadius get cardR => BorderRadius.circular(card);
  static BorderRadius get sheetR => BorderRadius.circular(sheet);
}

/// Именованные уровни прозрачности для заливок и границ —
/// заменяют разрозненные 0.04 / 0.06 / 0.08 / 0.12.
class AppAlpha {
  AppAlpha._();

  static const double hairline = 0.08; // тонкие границы поверх контента
  static const double fillSubtle = 0.05; // едва заметная заливка
  static const double fillMuted = 0.10; // приглушённая заливка / акцентный фон
  static const double fillStrong = 0.16; // выраженная акцентная заливка
}

/// Мягкие, спокойные тени в духе iOS. Минимализм: одна лёгкая тень для
/// «приподнятых» элементов; для карточек предпочитаем hairline-границу.
class AppShadows {
  AppShadows._();

  /// Лёгкая тень для карточек/плавающих панелей.
  static List<BoxShadow> soft(bool isDark) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  /// Более выраженная тень для плавающего навбара / модальных панелей.
  static List<BoxShadow> floating(bool isDark) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.10),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}

/// Удобные хелперы для часто используемых производных цветов темы.
extension AppThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get appBg => isDark ? AppTheme.darkBg : AppTheme.lightBg;
  Color get appSurface => isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
  Color get appCardBorder =>
      isDark ? AppTheme.cardBorderDark : AppTheme.cardBorderLight;
  Color get appTextPrimary =>
      isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
  Color get appTextSecondary =>
      isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
}
