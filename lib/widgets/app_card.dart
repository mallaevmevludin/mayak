import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_theme.dart';
import 'scale_on_tap.dart';

/// Единый «корпус» карточки — общий контейнер для постов, вакансий и
/// результатов поиска. Скругление [AppRadius.card], hairline-граница и
/// опциональная мягкая тень (минимализм: по умолчанию тени нет).
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  /// Показывать ли лёгкую тень. По умолчанию true — белые карточки на белом
  /// фоне в светлой теме «приподнимаются» мягкой тенью (стиль iOS).
  final bool elevated;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    final container = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: AppRadius.cardR,
        border: Border.all(color: context.appCardBorder, width: 0.5),
        boxShadow: elevated ? AppShadows.soft(isDark) : null,
      ),
      child: child,
    );

    if (onTap == null) return container;
    return ScaleOnTap(onTap: onTap!, scaleFactor: 0.97, child: container);
  }
}
