import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_theme.dart';

/// Единый «бейдж» (плашка) — заменяет три разрозненные реализации `_buildPill`
/// в job_card, job_detail и плашках-тегах в ленте.
///
/// По умолчанию — нейтральная серая плашка. Передайте [accent], чтобы получить
/// акцентный вариант (мягкий фон + цветной текст), например для статусов.
class PillBadge extends StatelessWidget {
  final String label;

  /// Эмодзи слева (если задан).
  final String? emoji;

  /// Иконка слева (если задана). Имеет приоритет над [emoji].
  final IconData? icon;

  /// Акцентный цвет. Если null — нейтральная серая плашка.
  final Color? accent;

  const PillBadge({
    super.key,
    required this.label,
    this.emoji,
    this.icon,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    final Color bg;
    final Color fg;
    if (accent != null) {
      bg = accent!.withValues(alpha: AppAlpha.fillMuted);
      fg = accent!;
    } else {
      bg = isDark ? AppTheme.cardBorderDark : AppTheme.lightSurface;
      fg = isDark ? const Color(0xFFE5E5EA) : const Color(0xFF48484A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.chipR,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: AppSpacing.xs + 2),
          ] else if (emoji != null && emoji!.isNotEmpty) ...[
            Text(emoji!, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: AppSpacing.xs + 2),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
