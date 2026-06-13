import 'dart:async';
import '../../../models/user_model.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
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

  @override
  Future<UserModel?> getSessionUser() async {
    // In mock mode, we don't automatically log in at startup unless simulated.
    return null;
  }

  @override
  Future<UserModel?> fetchProfile(String userId, String email) async {
    try {
      return _mockDb.firstWhere((u) => u.id == userId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserModel> registerUser({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final emailExists = _mockDb.any(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );
    final usernameExists = _mockDb.any(
      (u) => u.username.toLowerCase() == username.toLowerCase(),
    );

    if (emailExists) {
      throw Exception('Пользователь с такой почтой уже существует');
    }
    if (usernameExists) {
      throw Exception('Этот логин уже занят');
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

    return newUser;
  }

  @override
  Future<UserModel> loginUser({
    required String emailOrUsername,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final user = _mockDb.firstWhere(
      (u) =>
          u.email.toLowerCase() == emailOrUsername.toLowerCase() ||
          u.username.toLowerCase() == emailOrUsername.toLowerCase(),
      orElse: () => throw Exception('Пользователь не найден'),
    );

    final correctPassword =
        _mockPasswords[user.email] == password ||
        _mockPasswords[user.username] == password;
    if (!correctPassword) {
      throw Exception('Неверный пароль');
    }

    return user;
  }

  @override
  Future<void> updateProfile({
    required String userId,
    required String biography,
    required List<String> interests,
    String? emojiAvatar,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    final index = _mockDb.indexWhere((u) => u.id == userId);
    if (index == -1) {
      throw Exception('Пользователь не найден');
    }

    final currentUser = _mockDb[index];
    final updatedUser = currentUser.copyWith(
      biography: biography,
      interests: interests,
      emojiAvatar: emojiAvatar ?? currentUser.emojiAvatar,
    );

    _mockDb[index] = updatedUser;
  }

  @override
  Future<void> updateEmojiAvatar({
    required String userId,
    required String emoji,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockDb.indexWhere((u) => u.id == userId);
    if (index == -1) {
      throw Exception('Пользователь не найден');
    }
    _mockDb[index] = _mockDb[index].copyWith(emojiAvatar: emoji);
  }

  @override
  Future<void> updateAvatarUrl({
    required String userId,
    required String url,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockDb.indexWhere((u) => u.id == userId);
    if (index == -1) {
      throw Exception('Пользователь не найден');
    }
    _mockDb[index] = _mockDb[index].copyWith(avatarUrl: url);
  }

  @override
  Future<UserModel> verifyAndLoginPending({
    required String email,
    required String password,
  }) async {
    final user = _mockDb.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
      orElse: () => throw Exception('Пользователь не найден'),
    );
    return user;
  }

  @override
  Future<void> clearPendingVerification({
    required String? email,
    required String? username,
  }) async {
    // Nothing to delete in mock db since it's local memory and simulated
  }

  @override
  Future<void> signOut() async {
    // No-op for mock sign out
  }

  @override
  Future<void> changePassword({
    required String email,
    required String username,
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    
    final correctPassword =
        _mockPasswords[email] == currentPassword ||
        _mockPasswords[username] == currentPassword;
    if (!correctPassword) {
      throw Exception('Неверный текущий пароль');
    }
    _mockPasswords[email] = newPassword;
    _mockPasswords[username] = newPassword;
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final exists = _mockDb.any(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );
    if (!exists) {
      throw Exception('Пользователь с такой почтой не найден');
    }
  }

  @override
  Future<void> completePasswordRecovery({
    required String? userEmail,
    required String? userUsername,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final email = userEmail ?? _mockDb.first.email;
    final username = userUsername ?? _mockDb.first.username;
    
    _mockPasswords[email] = newPassword;
    _mockPasswords[username] = newPassword;
  }

  @override
  Future<bool> checkUsernameUnique({
    required String username,
    required String currentUserId,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    final exists = _mockDb.any(
      (u) => u.id != currentUserId && u.username.toLowerCase() == cleanUsername,
    );
    return !exists;
  }

  @override
  Future<void> changeUsername({
    required String userId,
    required String oldUsername,
    required String newUsername,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    final index = _mockDb.indexWhere((u) => u.id == userId);
    if (index == -1) {
      throw Exception('Пользователь не найден');
    }

    _mockDb[index] = _mockDb[index].copyWith(username: newUsername);

    if (_mockPasswords.containsKey(oldUsername)) {
      final pw = _mockPasswords.remove(oldUsername);
      if (pw != null) {
        _mockPasswords[newUsername] = pw;
      }
    }
  }

  @override
  Future<void> changeEmail({required String newEmail}) async {
    // Mock no-op or updating email locally if needed.
    // In our implementation we can just assume it works.
  }
}
