import '../../../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> getSessionUser();
  Future<UserModel?> fetchProfile(String userId, String email);
  
  Future<UserModel> registerUser({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
  });

  Future<UserModel> loginUser({
    required String emailOrUsername,
    required String password,
  });

  Future<void> updateProfile({
    required String userId,
    required String biography,
    required List<String> interests,
    String? emojiAvatar,
  });

  Future<void> updateEmojiAvatar({
    required String userId,
    required String emoji,
  });

  Future<void> updateAvatarUrl({
    required String userId,
    required String url,
  });

  Future<UserModel> verifyAndLoginPending({
    required String email,
    required String password,
  });

  Future<void> clearPendingVerification({
    required String? email,
    required String? username,
  });

  Future<void> signOut();

  Future<void> changePassword({
    required String email,
    required String username,
    required String currentPassword,
    required String newPassword,
  });

  Future<void> sendPasswordReset({required String email});

  Future<void> completePasswordRecovery({
    required String? userEmail,
    required String? userUsername,
    required String newPassword,
  });

  Future<bool> checkUsernameUnique({
    required String username,
    required String currentUserId,
  });

  Future<void> changeUsername({
    required String userId,
    required String oldUsername,
    required String newUsername,
  });

  Future<void> changeEmail({
    required String newEmail,
  });
}
