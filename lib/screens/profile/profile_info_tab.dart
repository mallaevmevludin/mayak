import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class ProfileInfoTab extends StatelessWidget {
  final UserModel user;

  const ProfileInfoTab({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Учетная информация',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildInfoTile(context, Icons.mail_outline_rounded, 'Эл. почта', user.email),
            const SizedBox(height: 12),
            _buildInfoTile(
              context,
              Icons.phone_android_rounded,
              'Номер телефона',
              user.phoneNumber,
            ),
            const SizedBox(height: 20),
            Text(
              'О себе (Биография)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  width: 0.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  (user.biography != null && user.biography!.trim().isNotEmpty)
                      ? user.biography!
                      : 'Биография пока не заполнена. Нажмите редактировать, чтобы добавить информацию.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle:
                        (user.biography == null || user.biography!.trim().isEmpty)
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Интересы',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (user.interests.isEmpty)
              Card(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                    width: 0.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Интересы пока не добавлены.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: user.interests.map((interest) {
                  return Chip(
                    label: Text(
                      interest,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide.none,
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String title, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.isNotEmpty ? value : '—',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
