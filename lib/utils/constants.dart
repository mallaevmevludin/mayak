/// Centralized application constants to replace magic numbers scattered across the codebase.
class AppConstants {
  AppConstants._();

  // ── Post limits ──
  static const int maxPostLength = 280;
  static const int maxPollOptions = 5;
  static const int minPollOptions = 2;
  static const int maxPostImages = 5;

  // ── Username limits ──
  static const int maxUsernameChangesPerWeek = 2;
  static const int usernameMinLength = 3;
  static const int usernameMaxLength = 20;
  static const Duration usernameChangeCooldown = Duration(days: 7);

  // ── Network ──
  static const Duration networkTimeout = Duration(seconds: 10);
  static const Duration mockDelay = Duration(milliseconds: 300);
  static const Duration shortMockDelay = Duration(milliseconds: 100);

  // ── Image upload ──
  static const int maxImageDimension = 2000;

  // ── Animation durations ──
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 600);
  static const Duration pageTransitionDuration = Duration(milliseconds: 400);
  static const Duration reverseTransitionDuration = Duration(milliseconds: 300);

  // ── UI sizes ──
  static const double bottomNavBarHeight = 120.0;
  static const double avatarSizeSmall = 40.0;
  static const double avatarSizeMedium = 56.0;
  static const double avatarSizeLarge = 92.0;
}
