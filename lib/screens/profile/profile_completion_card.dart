import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class ProfileCompletionCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onStartEditing;
  final VoidCallback onDismissed;
  final bool isEditing;

  const ProfileCompletionCard({
    super.key,
    required this.user,
    required this.onStartEditing,
    required this.onDismissed,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dismissible(
      key: const Key('profile_completion_card'),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) => onDismissed(),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.visibility_off_rounded, color: AppTheme.primary, size: 24),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.visibility_off_rounded, color: AppTheme.primary, size: 24),
      ),
      child: Card(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    user.isProfileComplete ? 'Профиль заполнен 🎉' : 'Заполните профиль',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    '${(user.completionProgress * 100).toInt()}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: user.completionProgress,
                  color: AppTheme.primary,
                  backgroundColor: isDark ? AppTheme.cardBorderDark : AppTheme.cardBorderLight,
                  minHeight: 6,
                ),
              ),
              if (!user.isProfileComplete && !isEditing) ...[
                const SizedBox(height: 12),
                Text(
                  'Пожалуйста, расскажите о себе и выберите ваши интересы, чтобы завершить настройку профиля.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    foregroundColor: AppTheme.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Заполнить сейчас'),
                  onPressed: onStartEditing,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
