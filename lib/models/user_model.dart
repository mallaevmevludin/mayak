class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String phoneNumber;
  final String? biography;
  final List<String> interests;
  final String? emojiAvatar;
  final String? avatarUrl;
  final bool isVerified;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    this.biography,
    this.interests = const [],
    this.emojiAvatar,
    this.avatarUrl,
    this.isVerified = false,
  });

  /// Checks if the profile is completed (biography and interests are set)
  bool get isProfileComplete {
    return biography != null &&
        biography!.trim().isNotEmpty &&
        interests.isNotEmpty;
  }

  /// Calculates profile completion progress as a fraction (0.0 to 1.0)
  double get completionProgress {
    int totalFields =
        7; // firstName, lastName, username, email, phoneNumber, biography, interests
    int completedFields = 0;

    if (firstName.trim().isNotEmpty) completedFields++;
    if (lastName.trim().isNotEmpty) completedFields++;
    if (username.trim().isNotEmpty) completedFields++;
    if (email.trim().isNotEmpty) completedFields++;
    if (phoneNumber.trim().isNotEmpty) completedFields++;
    if (biography != null && biography!.trim().isNotEmpty) completedFields++;
    if (interests.isNotEmpty) completedFields++;

    return completedFields / totalFields;
  }

  factory UserModel.fromJson(Map<String, dynamic> json, String authEmail) {
    // Map list of interests from Supabase db (text[] is returned as a list of dynamics)
    List<String> parsedInterests = [];
    if (json['interests'] != null) {
      if (json['interests'] is List) {
        parsedInterests = (json['interests'] as List)
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    return UserModel(
      id: json['id'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: authEmail,
      phoneNumber: json['phone_number'] as String? ?? '',
      biography: json['biography'] as String?,
      interests: parsedInterests,
      emojiAvatar: json['emoji_avatar'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'phone_number': phoneNumber,
      'biography': biography,
      'interests': interests,
      'emoji_avatar': emojiAvatar,
      'avatar_url': avatarUrl,
      'is_verified': isVerified,
    };
  }

  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? phoneNumber,
    String? biography,
    List<String>? interests,
    String? emojiAvatar,
    String? avatarUrl,
    bool? isVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      biography: biography ?? this.biography,
      interests: interests ?? this.interests,
      emojiAvatar: emojiAvatar ?? this.emojiAvatar,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
