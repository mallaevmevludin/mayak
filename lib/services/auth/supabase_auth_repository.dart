import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/user_model.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<UserModel?> getSessionUser() async {
    final session = _client.auth.currentSession;
    if (session != null) {
      return fetchProfile(session.user.id, session.user.email ?? '');
    }
    return null;
  }

  @override
  Future<UserModel?> fetchProfile(String userId, String email) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle()
        .timeout(const Duration(seconds: 8));

    if (data != null) {
      return UserModel.fromJson(data, email);
    }
    return null;
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
    // Clean up any unconfirmed user with the same email or username first
    try {
      await _client.rpc(
        'delete_unconfirmed_user_by_email_or_username',
        params: {'target_email': email, 'target_username': username},
      );
    } catch (_) {}

    // First check if username is unique in profiles
    final usernameCheck = await _client
        .from('profiles')
        .select('id')
        .eq('username', username)
        .maybeSingle();

    if (usernameCheck != null) {
      throw Exception('Этот логин уже занят');
    }

    final AuthResponse res = await _client.auth.signUp(
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
      throw Exception('Ошибка регистрации. Попробуйте еще раз.');
    }

    if (res.session == null) {
      // Email confirmation is required!
      throw Exception('CONFIRMATION_REQUIRED');
    }

    // Wait a small delay for DB trigger to complete, then fetch profile
    await Future.delayed(const Duration(milliseconds: 800));
    final profile = await fetchProfile(res.user!.id, email);
    if (profile == null) {
      // Fallback if public profile was not created by trigger yet
      return UserModel(
        id: res.user!.id,
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        phoneNumber: phoneNumber,
      );
    }

    return profile;
  }

  @override
  Future<UserModel> loginUser({
    required String emailOrUsername,
    required String password,
  }) async {
    String targetEmail = emailOrUsername;

    // If it's not a standard email format, assume it's a username and look up the email
    if (!emailOrUsername.contains('@')) {
      final profileData = await _client
          .from('profiles')
          .select('email')
          .eq('username', emailOrUsername)
          .maybeSingle();

      if (profileData == null || profileData['email'] == null) {
        throw Exception('Пользователь с таким логином не найден');
      }
      targetEmail = profileData['email'] as String;
    }

    final AuthResponse res = await _client.auth.signInWithPassword(
      email: targetEmail,
      password: password,
    );

    if (res.user == null) {
      throw Exception('Ошибка входа');
    }

    final profile = await fetchProfile(res.user!.id, targetEmail);
    if (profile == null) {
      throw Exception('Профиль пользователя не найден');
    }

    return profile;
  }

  @override
  Future<void> updateProfile({
    required String userId,
    required String biography,
    required List<String> interests,
    String? emojiAvatar,
  }) async {
    final Map<String, dynamic> updateData = {
      'biography': biography,
      'interests': interests,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (emojiAvatar != null) {
      updateData['emoji_avatar'] = emojiAvatar;
    }

    await _client
        .from('profiles')
        .update(updateData)
        .eq('id', userId);
  }

  @override
  Future<void> updateEmojiAvatar({
    required String userId,
    required String emoji,
  }) async {
    await _client
        .from('profiles')
        .update({
          'emoji_avatar': emoji,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  @override
  Future<void> updateAvatarUrl({
    required String userId,
    required String url,
  }) async {
    await _client
        .from('profiles')
        .update({
          'avatar_url': url,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  @override
  Future<UserModel> verifyAndLoginPending({
    required String email,
    required String password,
  }) async {
    final AuthResponse res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (res.user == null) {
      throw Exception('Ошибка входа');
    }

    final profile = await fetchProfile(res.user!.id, email);
    if (profile == null) {
      throw Exception('Профиль пользователя не найден');
    }

    return profile;
  }

  @override
  Future<void> clearPendingVerification({
    required String? email,
    required String? username,
  }) async {
    if (email != null) {
      try {
        await _client.rpc(
          'delete_unconfirmed_user_by_email_or_username',
          params: {'target_email': email, 'target_username': username ?? ''},
        );
      } catch (_) {}
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> changePassword({
    required String email,
    required String username,
    required String currentPassword,
    required String newPassword,
  }) async {
    // 1. Verify current password
    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
    } catch (_) {
      throw Exception('Неверный текущий (старый) пароль');
    }

    // 2. Update to new password
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'myhey://reset-callback',
    );
  }

  @override
  Future<void> completePasswordRecovery({
    required String? userEmail,
    required String? userUsername,
    required String newPassword,
  }) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  @override
  Future<bool> checkUsernameUnique({
    required String username,
    required String currentUserId,
  }) async {
    final res = await _client
        .from('profiles')
        .select('id')
        .eq('username', username.trim())
        .neq('id', currentUserId)
        .maybeSingle();
    return res == null;
  }

  @override
  Future<void> changeUsername({
    required String userId,
    required String oldUsername,
    required String newUsername,
  }) async {
    await _client
        .from('profiles')
        .update({
          'username': newUsername.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  @override
  Future<void> changeEmail({required String newEmail}) async {
    await _client.auth.updateUser(
      UserAttributes(email: newEmail),
    );
  }
}
