import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

/// A reusable avatar widget that handles network images, fallback initials,
/// loading states, and error states consistently across the app.
class UserAvatar extends StatelessWidget {
  /// URL of the user's avatar image. If null or empty, falls back to [fallbackInitial].
  final String? avatarUrl;

  /// Single character (or short string) to show when no avatar image is available.
  final String fallbackInitial;

  /// Diameter of the avatar circle.
  final double size;

  /// Whether to show a border around the avatar.
  final bool showBorder;

  /// Width of the border. Only used when [showBorder] is true.
  final double borderWidth;

  /// Callback when the avatar is tapped. If null, the avatar is not tappable.
  final VoidCallback? onTap;

  /// Optional background color override. If null, uses theme-aware defaults.
  final Color? backgroundColor;

  /// Font size for the fallback initial. If null, calculated from [size].
  final double? initialFontSize;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.fallbackInitial = '',
    this.size = 40,
    this.showBorder = false,
    this.borderWidth = 1.5,
    this.onTap,
    this.backgroundColor,
    this.initialFontSize,
  });

  /// Convenience factory for creating an avatar from a user's first/last name.
  factory UserAvatar.fromName({
    Key? key,
    String? avatarUrl,
    required String firstName,
    required String lastName,
    double size = 40,
    bool showBorder = false,
    double borderWidth = 1.5,
    VoidCallback? onTap,
    Color? backgroundColor,
    double? initialFontSize,
  }) {
    final initials =
        '${firstName.isNotEmpty ? firstName[0].toUpperCase() : ''}'
        '${lastName.isNotEmpty ? lastName[0].toUpperCase() : ''}';
    return UserAvatar(
      key: key,
      avatarUrl: avatarUrl,
      fallbackInitial: initials.isNotEmpty ? initials : 'U',
      size: size,
      showBorder: showBorder,
      borderWidth: borderWidth,
      onTap: onTap,
      backgroundColor: backgroundColor,
      initialFontSize: initialFontSize,
    );
  }

  /// Convenience factory for creating an avatar from a username.
  factory UserAvatar.fromUsername({
    Key? key,
    String? avatarUrl,
    required String username,
    double size = 40,
    bool showBorder = false,
    double borderWidth = 1.5,
    VoidCallback? onTap,
    Color? backgroundColor,
    double? initialFontSize,
  }) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';
    return UserAvatar(
      key: key,
      avatarUrl: avatarUrl,
      fallbackInitial: initial,
      size: size,
      showBorder: showBorder,
      borderWidth: borderWidth,
      onTap: onTap,
      backgroundColor: backgroundColor,
      initialFontSize: initialFontSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveFontSize = initialFontSize ?? (size * 0.35).clamp(12.0, 30.0);
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    final bgColor = backgroundColor ??
        (isDark ? AppTheme.darkBg : Colors.white);

    final borderColor = isDark ? Colors.white24 : Colors.black12;

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: showBorder
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
      ),
      padding: showBorder ? EdgeInsets.all(size * 0.04) : EdgeInsets.zero,
      child: hasImage
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: SizedBox(
                    width: size * 0.35,
                    height: size * 0.35,
                    child: const CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) =>
                    _buildInitialsFallback(isDark, effectiveFontSize),
              ),
            )
          : _buildInitialsFallback(isDark, effectiveFontSize),
    );

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  Widget _buildInitialsFallback(bool isDark, double fontSize) {
    return Center(
      child: Text(
        fallbackInitial,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}
