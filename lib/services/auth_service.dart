import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'supabase_config.dart';
import 'auth/auth_repository.dart';
import 'auth/mock_auth_repository.dart';
import 'auth/supabase_auth_repository.dart';
import 'deep_link_service.dart';

class AuthService extends ChangeNotifier {
  static final navigatorKey = GlobalKey<NavigatorState>();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  late final bool _isMockMode;
  String? _pendingEmail;
  String? _pendingPassword;
  bool _isInPasswordRecovery = false;
  final _deepLinkService = DeepLinkService();
  late final AuthRepository _repository;
  static const _secureStorage = FlutterSecureStorage();

  bool _isInitialized = false;
  bool _isRegistering = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isMockMode => _isMockMode;
  String? get pendingEmail => _pendingEmail;
  String? get pendingPassword => _pendingPassword;
  bool get isInPasswordRecovery => _isInPasswordRecovery;
  bool get isInitialized => _isInitialized;

  AuthService() {
    _isMockMode = !SupabaseConfig.isConfigured;
    if (_isMockMode) {
      debugPrint('AuthService initialized in MOCK MODE.');
      _repository = MockAuthRepository();
    } else {
      debugPrint('AuthService initialized in SUPABASE MODE.');
      _repository = SupabaseAuthRepository();
      _listenToAuthChanges();
    }
  }

  /// Check for active session on app startup
  Future<void> initializeAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pendingEmail = prefs.getString('pending_email');
      _pendingPassword = await _secureStorage.read(key: 'pending_password');
      if (_pendingEmail != null) {
        debugPrint('Found pending email verification: $_pendingEmail');
      }
    } catch (e) {
      debugPrint('Error loading pending state: $e');
    }

    if (_isMockMode) {
      _isInitialized = true;
      notifyListeners();
      return;
    }

    // Initialize custom deep link handling to guarantee recovery redirects are caught
    _initDeepLinkListener();

    try {
      final sessionUser = await _repository.getSessionUser()
          .timeout(const Duration(seconds: 8));
      if (sessionUser != null) {
        _currentUser = sessionUser;
      }
    } catch (e) {
      debugPrint('Error initializing Supabase Auth: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  void _initDeepLinkListener() async {
    // 1. Check for initial link (cold start)
    try {
      final initialUri = await _deepLinkService.getInitialLink()
          .timeout(const Duration(seconds: 3));
      if (initialUri != null) {
        debugPrint('Cold Start Deep Link captured: $initialUri');
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Error handling initial deep link: $e');
    }

    // 2. Listen to warm start deep links
    _deepLinkService.linkStream.listen(
      (uri) {
        debugPrint('Warm Start Deep Link captured: $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('Error on deep link stream: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    if (uri.host == 'reset-callback' ||
        uri.toString().contains('reset-callback')) {
      debugPrint(
        'Reset-callback deep link detected. Entering password recovery mode.',
      );
      _isInPasswordRecovery = true;
      notifyListeners();

      // Clear the Navigator stack and force navigation to ResetPasswordScreen immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/reset-password',
          (route) => false,
        );
      });
    }
  }

  void _listenToAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      final event = data.event;

      debugPrint(
        'Auth State Change: Event = $event, Has Session = ${session != null}',
      );

      if (event == AuthChangeEvent.passwordRecovery) {
        _isInPasswordRecovery = true;
        notifyListeners();
      }

      if (session != null) {
        await _fetchAndSetProfile(session.user.id, session.user.email ?? '');
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchAndSetProfile(String userId, String email) async {
    try {
      final profile = await _repository.fetchProfile(userId, email)
          .timeout(const Duration(seconds: 8));
      if (profile != null) {
        _currentUser = profile;
        notifyListeners();
      } else {
        if (_isRegistering) {
          // Fallback if public profile was not created by trigger yet during registration
          _currentUser = UserModel(
            id: userId,
            firstName: '',
            lastName: '',
            username: '',
            email: email,
            phoneNumber: '',
          );
          notifyListeners();
        } else {
          // If not registering and profile is missing, the user is invalid/deleted.
          // Sign out immediately to clear local session.
          debugPrint('Profile not found for userId: $userId. Signing out.');
          _currentUser = null;
          await signOut();
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  /// Register user
  Future<bool> registerUser({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    _isRegistering = true;
    _setLoading(true);
    _clearError();

    try {
      final user = await _repository.registerUser(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
      );

      _currentUser = user;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('CONFIRMATION_REQUIRED')) {
        _clearError();
        // Email confirmation is required!
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('pending_email', email);
          await _secureStorage.write(key: 'pending_password', value: password);
          _pendingEmail = email;
          _pendingPassword = password;
        } catch (_) {}
        _setLoading(false);
        notifyListeners();
        return false;
      } else {
        _setError(errorStr);
        _setLoading(false);
        return false;
      }
    } finally {
      _isRegistering = false;
    }
  }

  /// Sign In user (supports email or username)
  Future<bool> loginUser({
    required String emailOrUsername,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _repository.loginUser(
        emailOrUsername: emailOrUsername,
        password: password,
      );

      _currentUser = user;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Complete or update profile
  Future<bool> updateProfile({
    required String biography,
    required List<String> interests,
    String? emojiAvatar,
  }) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _repository.updateProfile(
        userId: _currentUser!.id,
        biography: biography,
        interests: interests,
        emojiAvatar: emojiAvatar,
      );

      _currentUser = _currentUser!.copyWith(
        biography: biography,
        interests: interests,
        emojiAvatar: emojiAvatar ?? _currentUser!.emojiAvatar,
      );
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Update user's emoji avatar specifically
  Future<bool> updateEmojiAvatar(String emoji) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _repository.updateEmojiAvatar(
        userId: _currentUser!.id,
        emoji: emoji,
      );

      _currentUser = _currentUser!.copyWith(emojiAvatar: emoji);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Update user's photo avatar URL specifically
  Future<bool> updateAvatarUrl(String url) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _repository.updateAvatarUrl(
        userId: _currentUser!.id,
        url: url,
      );

      _currentUser = _currentUser!.copyWith(avatarUrl: url);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Attempts to log in with the cached pending verification credentials
  Future<bool> verifyAndLoginPending() async {
    if (_pendingEmail == null || _pendingPassword == null) {
      _setError('Нет данных для проверки подтверждения');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final user = await _repository.verifyAndLoginPending(
        email: _pendingEmail!,
        password: _pendingPassword!,
      );

      _currentUser = user;
      await clearPendingVerification();
      _setLoading(false);
      return true;
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('Email not confirmed')) {
        _setError(
          'Почта еще не подтверждена. Пожалуйста, перейдите по ссылке в письме.',
        );
      } else {
        _setError('Ошибка проверки: $msg');
      }
      _setLoading(false);
      return false;
    }
  }

  /// Clears the cached pending registration credentials and deletes unconfirmed user from DB
  Future<void> clearPendingVerification() async {
    final emailToDelete = _pendingEmail;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_email');
      await _secureStorage.delete(key: 'pending_password');
      _pendingEmail = null;
      _pendingPassword = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing pending verification state: $e');
    }

    if (emailToDelete != null) {
      try {
        debugPrint('Attempting to delete unconfirmed user: $emailToDelete');
        await _repository.clearPendingVerification(
          email: emailToDelete,
          username: _currentUser?.username,
        );
        debugPrint(
          'Successfully deleted unconfirmed user $emailToDelete from DB',
        );
      } catch (e) {
        debugPrint('Error deleting unconfirmed user from DB: $e');
      }
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _repository.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    } finally {
      _currentUser = null;
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Update/Change user password (requires current password validation)
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      if (_currentUser == null) throw Exception('Пользователь не авторизован');

      await _repository.changePassword(
        email: _currentUser!.email,
        username: _currentUser!.username,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Sends a password reset recovery link to the user's email
  Future<bool> sendPasswordReset({required String email}) async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.sendPasswordReset(email: email);
      
      if (_isMockMode) {
        // Direct simulation of deep-link recovery screen for testing in mock mode
        _isInPasswordRecovery = true;
        notifyListeners();
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Completes the password recovery by setting a new password
  Future<bool> completePasswordRecovery({required String newPassword}) async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.completePasswordRecovery(
        userEmail: _currentUser?.email,
        userUsername: _currentUser?.username,
        newPassword: newPassword,
      );

      if (_isMockMode && _currentUser == null) {
        // Log in first mock user if none logged in during mock password recovery test
        await initializeAuth();
      }

      _isInPasswordRecovery = false;
      _setLoading(false);
      notifyListeners();

      // Redirect to profile
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/profile',
        (route) => false,
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Cancels the password recovery process
  Future<void> cancelPasswordRecovery() async {
    _isInPasswordRecovery = false;
    await signOut();
    
    // Redirect to login
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  /// Checks if a username is unique (not taken by another user)
  Future<bool> checkUsernameUnique(String username) async {
    if (currentUser == null) return false;
    return _repository.checkUsernameUnique(
      username: username,
      currentUserId: currentUser!.id,
    );
  }

  /// Change user username (rate limited to 2 times per 7 days)
  Future<bool> changeUsername({required String newUsername}) async {
    if (currentUser == null) {
      _setError('Пользователь не авторизован');
      return false;
    }

    final trimmedUsername = newUsername.trim();
    if (trimmedUsername.isEmpty) {
      _setError('Логин не может быть пустым');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // 1. Enforce rate limiting: max 2 changes per 7 days (168 hours)
      final prefs = await SharedPreferences.getInstance();
      final storageKey = 'username_change_timestamps_${currentUser!.id}';
      List<String> timestampStrings = prefs.getStringList(storageKey) ?? [];

      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));

      // Parse and filter out older timestamps
      List<DateTime> changeDates = timestampStrings
          .map((s) => DateTime.tryParse(s))
          .whereType<DateTime>()
          .where((dt) => dt.isAfter(oneWeekAgo))
          .toList();

      if (changeDates.length >= 2) {
        throw Exception('Вы не можете менять логин более 2 раз в неделю');
      }

      // 2. Validate uniqueness
      final isUnique = await checkUsernameUnique(trimmedUsername);
      if (!isUnique) {
        throw Exception('Этот логин уже занят');
      }

      // 3. Update username
      await _repository.changeUsername(
        userId: currentUser!.id,
        oldUsername: currentUser!.username,
        newUsername: trimmedUsername,
      );

      _currentUser = _currentUser!.copyWith(username: trimmedUsername);

      // 4. Save new change date to rate limit list
      changeDates.add(now);
      final newTimestampStrings = changeDates
          .map((dt) => dt.toIso8601String())
          .toList();
      await prefs.setStringList(storageKey, newTimestampStrings);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Update/Change user email
  Future<bool> changeEmail({required String newEmail}) async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.changeEmail(newEmail: newEmail);
      if (_isMockMode && _currentUser != null) {
        _currentUser = _currentUser!.copyWith(email: newEmail);
      }
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String msg) {
    // Simplify common Firebase/Supabase/PgSql error formats to make them friendly
    if (msg.contains('Invalid login credentials') ||
        msg.contains('invalid claim')) {
      _errorMessage = 'Неверный адрес почты/логин или пароль';
    } else if (msg.contains('Email already in use') ||
        msg.contains('User already exists')) {
      _errorMessage = 'Этот адрес почты уже используется';
    } else if (msg.contains('over_email_send_rate_limit') ||
        msg.contains('email rate limit exceeded')) {
      _errorMessage =
          'Превышен лимит отправки писем. Пожалуйста, подождите немного перед следующей попыткой.';
    } else if (msg.contains('database') || msg.contains('connection')) {
      _errorMessage = 'Ошибка подключения к серверу';
    } else {
      // Stripping "Exception: " if present
      _errorMessage = msg
          .replaceAll('Exception: ', '')
          .replaceAll('AuthException: ', '')
          .replaceAll('AuthApiException: ', '');
    }
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
