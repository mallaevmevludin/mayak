class ApplicationModel {
  final int id;
  final int jobId;
  final String applicantId;
  final String applicantFirstName;
  final String applicantLastName;
  final String applicantUsername;
  final String? applicantEmojiAvatar;
  final String? applicantAvatarUrl;
  final bool applicantIsVerified;
  final String status; // 'pending', 'accepted', 'declined'
  final DateTime createdAt;

  ApplicationModel({
    required this.id,
    required this.jobId,
    required this.applicantId,
    required this.applicantFirstName,
    required this.applicantLastName,
    required this.applicantUsername,
    this.applicantEmojiAvatar,
    this.applicantAvatarUrl,
    this.applicantIsVerified = false,
    required this.status,
    required this.createdAt,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    // Under select queries, profiles is joined as 'profiles'
    final profile = json['profiles'] as Map<String, dynamic>?;

    return ApplicationModel(
      id: json['id'] as int? ?? 0,
      jobId: json['job_id'] as int? ?? 0,
      applicantId: json['applicant_id'] as String? ?? '',
      applicantFirstName: profile?['first_name'] as String? ?? json['first_name'] as String? ?? 'Пользователь',
      applicantLastName: profile?['last_name'] as String? ?? json['last_name'] as String? ?? '',
      applicantUsername: profile?['username'] as String? ?? json['username'] as String? ?? 'user',
      applicantEmojiAvatar: profile?['emoji_avatar'] as String? ?? json['emoji_avatar'] as String?,
      applicantAvatarUrl: profile?['avatar_url'] as String? ?? json['avatar_url'] as String?,
      applicantIsVerified: profile?['is_verified'] as bool? ?? json['is_verified'] as bool? ?? false,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'applicant_id': applicantId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
