import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';
import '../models/user_model.dart';
import 'supabase_config.dart';

class AuthService extends ChangeNotifier {
  static final navigatorKey = GlobalKey<NavigatorState>();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  late final bool _isMockMode;
  String? _pendingEmail;
  String? _pendingPassword;
  bool _isInPasswordRecovery = false;
  final _appLinks = AppLinks();

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

  // Local memory Database for Mock Mode
  static final List<UserModel> _mockDb = [
    UserModel(
      id: 'mock-user-1',
      firstName: 'Иван',
      lastName: 'Иванов',
      username: 'ivanov',
      email: 'ivan@example.com',
      phoneNumber: '+7 (999) 123-45-67',
      biography: 'Разработчик на Flutter, люблю спорт и чтение.',
      interests: ['Flutter', 'Dart', 'Спорт', 'Чтение'],
      isVerified: true,
    ),
  ];

  static final Map<String, String> _mockPasswords = {
    'ivan@example.com': 'Password123!',
    'ivanov': 'Password123!',
  };

  AuthService() {
    _isMockMode = !SupabaseConfig.isConfigured;
    if (_isMockMode) {
      debugPrint('AuthService initialized in MOCK MODE.');
    } else {
      debugPrint('AuthService initialized in SUPABASE MODE.');
      _listenToAuthChanges();
    }
  }

  /// Check for active session on app startup
  Future<void> initializeAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pendingEmail = prefs.getString('pending_email');
      _pendingPassword = prefs.getString('pending_password');
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
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await _fetchAndSetProfile(session.user.id, session.user.email ?? '');
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
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('Cold Start Deep Link captured: $initialUri');
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Error handling initial deep link: $e');
    }

    // 2. Listen to warm start deep links
    _appLinks.uriLinkStream.listen(
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
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        _currentUser = UserModel.fromJson(data, email);
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
      if (_isMockMode) {
        await Future.delayed(
          const Duration(milliseconds: 1500),
        ); // Simulate network

        // Check duplicates in mock db
        final emailExists = _mockDb.any(
          (u) => u.email.toLowerCase() == email.toLowerCase(),
        );
        final usernameExists = _mockDb.any(
          (u) => u.username.toLowerCase() == username.toLowerCase(),
        );

        if (emailExists) {
          throw 'Пользователь с такой почтой уже существует';
        }
        if (usernameExists) {
          throw 'Этот логин уже занят';
        }

        final newUser = UserModel(
          id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
          firstName: firstName,
          lastName: lastName,
          username: username,
          email: email,
          phoneNumber: phoneNumber,
        );

        _mockDb.add(newUser);
        _mockPasswords[email] = password;
        _mockPasswords[username] = password;

        _currentUser = newUser;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        // Supabase registration
        // Clean up any unconfirmed user with the same email or username first
        try {
          await Supabase.instance.client.rpc(
            'delete_unconfirmed_user_by_email_or_username',
            params: {'target_email': email, 'target_username': username},
          );
        } catch (e) {
          debugPrint('Error cleaning up existing unconfirmed user: $e');
        }

        // First check if username is unique in profiles
        final usernameCheck = await Supabase.instance.client
            .from('profiles')
            .select('id')
            .eq('username', username)
            .maybeSingle();

        if (usernameCheck != null) {
          throw 'Этот логин уже занят';
        }

        final AuthResponse res = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {
            'first_name': firstName,
            'last_name': lastName,
            'username': username,
            'phone_number': phoneNumber,
          },
        );

        if (res.user == null) {
          throw 'Ошибка регистрации. Попробуйте еще раз.';
        }

        if (res.session == null) {
          // Email confirmation is required!
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('pending_email', email);
          await prefs.setString('pending_password', password);
          _pendingEmail = email;
          _pendingPassword = password;
          _setLoading(false);
          notifyListeners();
          throw 'CONFIRMATION_REQUIRED';
        }

        // Wait a small delay for DB trigger to complete, then fetch profile
        await Future.delayed(const Duration(milliseconds: 800));
        await _fetchAndSetProfile(res.user!.id, email);

        _setLoading(false);
        return true;
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('CONFIRMATION_REQUIRED')) {
        _clearError();
      } else {
        _setError(errorStr);
      }
      _setLoading(false);
      return false;
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
      if (_isMockMode) {
        await Future.delayed(
          const Duration(milliseconds: 1500),
        ); // Simulate network

        final user = _mockDb.firstWhere(
          (u) =>
              u.email.toLowerCase() == emailOrUsername.toLowerCase() ||
              u.username.toLowerCase() == emailOrUsername.toLowerCase(),
          orElse: () => throw 'Пользователь не найден',
        );

        final correctPassword =
            _mockPasswords[user.email] == password ||
            _mockPasswords[user.username] == password;
        if (!correctPassword) {
          throw 'Неверный пароль';
        }

        _currentUser = user;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        String targetEmail = emailOrUsername;

        // If it's not a standard email format, assume it's a username and look up the email
        if (!emailOrUsername.contains('@')) {
          final profileData = await Supabase.instance.client
              .from('profiles')
              .select('email')
              .eq('username', emailOrUsername)
              .maybeSingle();

          if (profileData == null || profileData['email'] == null) {
            throw 'Пользователь с таким логином не найден';
          }
          targetEmail = profileData['email'] as String;
        }

        final AuthResponse res = await Supabase.instance.client.auth
            .signInWithPassword(email: targetEmail, password: password);

        if (res.user == null) {
          throw 'Ошибка входа';
        }

        await _fetchAndSetProfile(res.user!.id, targetEmail);
        _setLoading(false);
        return true;
      }
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
      if (_isMockMode) {
        await Future.delayed(
          const Duration(milliseconds: 1000),
        ); // Simulate network

        final index = _mockDb.indexWhere((u) => u.id == _currentUser!.id);
        final updatedUser = _currentUser!.copyWith(
          biography: biography,
          interests: interests,
          emojiAvatar: emojiAvatar ?? _currentUser!.emojiAvatar,
        );

        if (index != -1) {
          _mockDb[index] = updatedUser;
        }
        _currentUser = updatedUser;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        final Map<String, dynamic> updateData = {
          'biography': biography,
          'interests': interests,
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (emojiAvatar != null) {
          updateData['emoji_avatar'] = emojiAvatar;
        }

        await Supabase.instance.client
            .from('profiles')
            .update(updateData)
            .eq('id', _currentUser!.id);

        _currentUser = _currentUser!.copyWith(
          biography: biography,
          interests: interests,
          emojiAvatar: emojiAvatar ?? _currentUser!.emojiAvatar,
        );
        _setLoading(false);
        notifyListeners();
        return true;
      }
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
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 500));
        final index = _mockDb.indexWhere((u) => u.id == _currentUser!.id);
        final updatedUser = _currentUser!.copyWith(emojiAvatar: emoji);
        if (index != -1) {
          _mockDb[index] = updatedUser;
        }
        _currentUser = updatedUser;
      } else {
        await Supabase.instance.client
            .from('profiles')
            .update({
              'emoji_avatar': emoji,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', _currentUser!.id);

        _currentUser = _currentUser!.copyWith(emojiAvatar: emoji);
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

  /// Update user's photo avatar URL specifically
  Future<bool> updateAvatarUrl(String url) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _clearError();

    try {
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 500));
        final index = _mockDb.indexWhere((u) => u.id == _currentUser!.id);
        final updatedUser = _currentUser!.copyWith(avatarUrl: url);
        if (index != -1) {
          _mockDb[index] = updatedUser;
        }
        _currentUser = updatedUser;
      } else {
        await Supabase.instance.client
            .from('profiles')
            .update({
              'avatar_url': url,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', _currentUser!.id);

        _currentUser = _currentUser!.copyWith(avatarUrl: url);
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



  /// Attempts to log in with the cached pending verification credentials
  Future<bool> verifyAndLoginPending() async {
    if (_pendingEmail == null || _pendingPassword == null) {
      _setError('Нет данных для проверки подтверждения');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      if (_isMockMode) {
        // Mock mode automatically succeeds
        _currentUser = _mockDb.firstWhere(
          (u) => u.email.toLowerCase() == _pendingEmail!.toLowerCase(),
          orElse: () => throw 'Пользователь не найден',
        );
        await clearPendingVerification();
        _setLoading(false);
        return true;
      } else {
        final AuthResponse res = await Supabase.instance.client.auth
            .signInWithPassword(
              email: _pendingEmail!,
              password: _pendingPassword!,
            );

        if (res.user == null) {
          throw 'Ошибка входа';
        }

        final email = res.user!.email ?? _pendingEmail!;

        // Successfully logged in! Clear pending state.
        await clearPendingVerification();
        await _fetchAndSetProfile(res.user!.id, email);
        _setLoading(false);
        return true;
      }
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
      await prefs.remove('pending_password');
      _pendingEmail = null;
      _pendingPassword = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing pending verification state: $e');
    }

    if (!_isMockMode && emailToDelete != null) {
      try {
        debugPrint('Attempting to delete unconfirmed user: $emailToDelete');
        await Supabase.instance.client.rpc(
          'delete_unconfirmed_user_by_email_or_username',
          params: {'target_email': emailToDelete, 'target_username': ''},
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
      if (!_isMockMode) {
        await Supabase.instance.client.auth.signOut();
      }
    } catch (e) {
      debugPrint('Error signing out of Supabase: $e');
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
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 1000));
        if (_currentUser != null) {
          final correctPassword =
              _mockPasswords[_currentUser!.email] == currentPassword ||
              _mockPasswords[_currentUser!.username] == currentPassword;
          if (!correctPassword) {
            throw 'Неверный текущий пароль';
          }
          _mockPasswords[_currentUser!.email] = newPassword;
          _mockPasswords[_currentUser!.username] = newPassword;
        }
        _setLoading(false);
        return true;
      } else {
        if (_currentUser == null) throw 'Пользователь не авторизован';

        // 1. Verify current password
        try {
          await Supabase.instance.client.auth.signInWithPassword(
            email: _currentUser!.email,
            password: currentPassword,
          );
        } catch (e) {
          throw 'Неверный текущий (старый) пароль';
        }

        // 2. Update to new password
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: newPassword),
        );
        _setLoading(false);
        return true;
      }
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
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 1000));
        final exists = _mockDb.any(
          (u) => u.email.toLowerCase() == email.toLowerCase(),
        );
        if (!exists) {
          throw 'Пользователь с такой почтой не найден';
        }
        // Direct simulation of deep-link recovery screen for testing
        _isInPasswordRecovery = true;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        await Supabase.instance.client.auth.resetPasswordForEmail(
          email,
          redirectTo: 'myhey://reset-callback',
        );
        _setLoading(false);
        return true;
      }
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
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 1000));
        if (_currentUser != null) {
          _mockPasswords[_currentUser!.email] = newPassword;
          _mockPasswords[_currentUser!.username] = newPassword;
        } else {
          // If no current user is logged in, find any user and log them in
          _mockPasswords[_mockDb.first.email] = newPassword;
          _mockPasswords[_mockDb.first.username] = newPassword;
          _currentUser = _mockDb.first;
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
      } else {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: newPassword),
        );
        _isInPasswordRecovery = false;
        _setLoading(false);
        notifyListeners();

        // Redirect to profile
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/profile',
          (route) => false,
        );
        return true;
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Cancels the password recovery process
  Future<void> cancelPasswordRecovery() async {
    _isInPasswordRecovery = false;
    if (!_isMockMode) {
      await signOut();
    } else {
      _currentUser = null;
      notifyListeners();
    }
    // Redirect to login
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  /// Checks if a username is unique (not taken by another user)
  Future<bool> checkUsernameUnique(String username) async {
    if (currentUser == null) return false;
    final cleanUsername = username.trim().toLowerCase();

    if (_isMockMode) {
      // Mock db check, excluding current user
      final exists = _mockDb.any(
        (u) =>
            u.id != currentUser!.id &&
            u.username.toLowerCase() == cleanUsername,
      );
      return !exists;
    } else {
      try {
        final res = await Supabase.instance.client
            .from('profiles')
            .select('id')
            .eq('username', username.trim())
            .neq('id', currentUser!.id)
            .maybeSingle();
        return res == null;
      } catch (e) {
        debugPrint('Error checking username uniqueness: $e');
        return false;
      }
    }
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
        throw 'Вы не можете менять логин более 2 раз в неделю';
      }

      // 2. Validate uniqueness
      final isUnique = await checkUsernameUnique(trimmedUsername);
      if (!isUnique) {
        throw 'Этот логин уже занят';
      }

      // 3. Update username
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 1000));

        final index = _mockDb.indexWhere((u) => u.id == currentUser!.id);
        final updatedUser = currentUser!.copyWith(username: trimmedUsername);
        if (index != -1) {
          _mockDb[index] = updatedUser;
        }

        // Also update passwords mock db key
        final oldUsername = currentUser!.username;
        if (_mockPasswords.containsKey(oldUsername)) {
          final pw = _mockPasswords.remove(oldUsername);
          if (pw != null) {
            _mockPasswords[trimmedUsername] = pw;
          }
        }

        _currentUser = updatedUser;
      } else {
        await Supabase.instance.client
            .from('profiles')
            .update({
              'username': trimmedUsername,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', currentUser!.id);

        _currentUser = _currentUser!.copyWith(username: trimmedUsername);
      }

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
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 1000));
        if (_currentUser != null) {
          final updatedUser = _currentUser!.copyWith(email: newEmail);
          final index = _mockDb.indexWhere((u) => u.id == _currentUser!.id);
          if (index != -1) {
            _mockDb[index] = updatedUser;
          }
          _currentUser = updatedUser;
        }
        _setLoading(false);
        return true;
      } else {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(email: newEmail),
        );
        _setLoading(false);
        return true;
      }
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
