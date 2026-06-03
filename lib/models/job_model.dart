class JobModel {
  final int id;
  final String userId;
  final String userFirstName;
  final String userLastName;
  final String userUsername;
  final String? userEmojiAvatar;
  final String? userAvatarUrl;
  final bool userIsVerified;
  final String title;
  final String description;
  final String category; // 'dev', 'design', etc.
  final String? budget;
  final String? contactPhone;
  final String? contactTelegram;
  final String status; // 'active' or 'closed'
  final DateTime createdAt;
  final List<String> imageUrls;
  final String? rejectionComment;

  JobModel({
    required this.id,
    required this.userId,
    required this.userFirstName,
    required this.userLastName,
    required this.userUsername,
    this.userEmojiAvatar,
    this.userAvatarUrl,
    this.userIsVerified = false,
    required this.title,
    required this.description,
    required this.category,
    this.budget,
    this.contactPhone,
    this.contactTelegram,
    this.status = 'active',
    required this.createdAt,
    this.imageUrls = const [],
    this.rejectionComment,
  });

  bool get isActive => status == 'active';

  String get formattedBudget {
    return formatBudgetHelper(budget);
  }

  static String formatBudgetHelper(String? budgetStr) {
    if (budgetStr == null || budgetStr.trim().isEmpty) {
      return 'Договорная';
    }
    
    final clean = budgetStr.trim();
    
    // Check if the budget is a pure integer or double (e.g. "120000" or "5000")
    final RegExp pureNumberRegex = RegExp(r'^\d+$');
    if (pureNumberRegex.hasMatch(clean)) {
      final buffer = StringBuffer();
      for (int i = 0; i < clean.length; i++) {
        buffer.write(clean[i]);
        final reversedIndex = clean.length - 1 - i;
        if (reversedIndex % 3 == 0 && reversedIndex > 0) {
          buffer.write(' ');
        }
      }
      return '${buffer.toString()} ₽';
    }
    
    if (clean.endsWith('₽') || clean.contains(' ')) {
      return clean;
    }
    
    // Format any sequence of 4 or more digits
    final formatted = clean.replaceAllMapped(RegExp(r'\d{4,}'), (match) {
      final digits = match.group(0)!;
      final buffer = StringBuffer();
      for (int i = 0; i < digits.length; i++) {
        buffer.write(digits[i]);
        final reversedIndex = digits.length - 1 - i;
        if (reversedIndex % 3 == 0 && reversedIndex > 0) {
          buffer.write(' ');
        }
      }
      return buffer.toString();
    });
    
    if (RegExp(r'^\d+(\s\d+)*$').hasMatch(formatted)) {
      return '$formatted ₽';
    }
    
    return formatted;
  }

  String get categoryEmoji {
    return categories[category]?['emoji'] ?? '✨';
  }

  String get categoryName {
    return categories[category]?['name'] ?? 'Другое';
  }

  static const Map<String, Map<String, String>> categories = {
    'construction': {'emoji': '🛠', 'name': 'Строительство и ремонт'},
    'handyman': {'emoji': '👨‍🔧', 'name': 'Услуги мастеров'},
    'cargo': {'emoji': '🚚', 'name': 'Грузоперевозки'},
    'agriculture': {'emoji': '🐑', 'name': 'Сельское хозяйство'},
    'autoservice': {'emoji': '🚗', 'name': 'Автосервис'},
    'security': {'emoji': '🛡', 'name': 'Охрана и безопасность'},
    'beauty': {'emoji': '✂️', 'name': 'Салоны и красота'},
    'education': {'emoji': '📚', 'name': 'Обучение и репетиторы'},
    'freelance': {'emoji': '💻', 'name': 'Фриланс и удаленка'},
    'other': {'emoji': '✨', 'name': 'Другие услуги'},
  };

  JobModel copyWith({
    int? id,
    String? userId,
    String? userFirstName,
    String? userLastName,
    String? userUsername,
    String? userEmojiAvatar,
    String? userAvatarUrl,
    bool? userIsVerified,
    String? title,
    String? description,
    String? category,
    String? budget,
    String? contactPhone,
    String? contactTelegram,
    String? status,
    DateTime? createdAt,
    List<String>? imageUrls,
    String? rejectionComment,
    bool clearRejectionComment = false,
  }) {
    return JobModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userFirstName: userFirstName ?? this.userFirstName,
      userLastName: userLastName ?? this.userLastName,
      userUsername: userUsername ?? this.userUsername,
      userEmojiAvatar: userEmojiAvatar ?? this.userEmojiAvatar,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      userIsVerified: userIsVerified ?? this.userIsVerified,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      budget: budget ?? this.budget,
      contactPhone: contactPhone ?? this.contactPhone,
      contactTelegram: contactTelegram ?? this.contactTelegram,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      imageUrls: imageUrls ?? this.imageUrls,
      rejectionComment: clearRejectionComment ? null : (rejectionComment ?? this.rejectionComment),
    );
  }

  factory JobModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;

    final dynamic imageUrlsJson = json['image_urls'];
    List<String> parsedImageUrls = [];
    if (imageUrlsJson != null) {
      if (imageUrlsJson is List) {
        parsedImageUrls = imageUrlsJson
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      } else {
        parsedImageUrls = [imageUrlsJson.toString()];
      }
    }

    return JobModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as String? ?? '',
      userFirstName: profile?['first_name'] as String? ?? json['first_name'] as String? ?? 'Пользователь',
      userLastName: profile?['last_name'] as String? ?? json['last_name'] as String? ?? '',
      userUsername: profile?['username'] as String? ?? json['username'] as String? ?? 'user',
      userEmojiAvatar: profile?['emoji_avatar'] as String? ?? json['emoji_avatar'] as String?,
      userAvatarUrl: profile?['avatar_url'] as String? ?? json['avatar_url'] as String?,
      userIsVerified: profile?['is_verified'] as bool? ?? json['is_verified'] as bool? ?? false,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'other',
      budget: json['budget'] as String?,
      contactPhone: json['contact_phone'] as String?,
      contactTelegram: json['contact_telegram'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      imageUrls: parsedImageUrls,
      rejectionComment: json['rejection_comment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'budget': budget,
      'contact_phone': contactPhone,
      'contact_telegram': contactTelegram,
      'status': status,
      if (userId.isNotEmpty) 'user_id': userId,
      'image_urls': imageUrls,
      'rejection_comment': rejectionComment,
    };
  }
}
