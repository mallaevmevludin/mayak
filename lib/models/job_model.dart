enum JobStatus {
  active,
  pending,
  closed,
  rejected,
  // ignore: constant_identifier_names
  in_progress,
  completed;

  static JobStatus fromString(String value) {
    // Map database snake_case or legacy strings if needed
    final clean = value.replaceAll('-', '_').toLowerCase();
    return JobStatus.values.firstWhere(
      (e) => e.name == clean,
      orElse: () => JobStatus.active,
    );
  }
}


enum JobCategory {
  construction('🛠', 'Строительство и ремонт'),
  handyman('👨‍🔧', 'Услуги мастеров'),
  cargo('🚚', 'Грузоперевозки'),
  agriculture('🐑', 'Сельское хозяйство'),
  autoservice('🚗', 'Автосервис'),
  security('🛡', 'Охрана и безопасность'),
  beauty('✂️', 'Салоны и красота'),
  education('📚', 'Обучение и репетиторы'),
  freelance('💻', 'Фриланс и удаленка'),
  other('✨', 'Другие услуги');

  final String emoji;
  final String displayName;

  const JobCategory(this.emoji, this.displayName);

  static JobCategory fromString(String value) {
    return JobCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => JobCategory.other,
    );
  }
}

enum WorkType {
  oneTime('Разовая работа'),
  permanent('Постоянная занятость'),
  project('Проектная работа');

  final String displayName;

  const WorkType(this.displayName);

  static WorkType fromString(String value) {
    final clean = value.replaceAll('_', '').toLowerCase();
    if (clean == 'onetime') return WorkType.oneTime;
    return WorkType.values.firstWhere(
      (e) => e.name.toLowerCase() == clean,
      orElse: () => WorkType.oneTime,
    );
  }

  String toDbString() {
    switch (this) {
      case WorkType.oneTime:
        return 'one_time';
      case WorkType.permanent:
        return 'permanent';
      case WorkType.project:
        return 'project';
    }
  }
}

enum LocationType {
  city,
  district;

  static LocationType fromString(String value) {
    return LocationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LocationType.city,
    );
  }
}

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
  final JobCategory category;
  final String? budget;
  final String? contactPhone;
  final String? contactTelegram;
  final JobStatus status;
  final DateTime createdAt;
  final List<String> imageUrls;
  final String? rejectionComment;
  final LocationType locationType;
  final String? city;
  final String? district;
  final String? settlement;
  final WorkType? workType;

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
    this.status = JobStatus.active,
    required this.createdAt,
    this.imageUrls = const [],
    this.rejectionComment,
    this.locationType = LocationType.city,
    this.city,
    this.district,
    this.settlement,
    this.workType,
  });

  bool get isActive => status == JobStatus.active;

  String get formattedBudget {
    return formatBudgetHelper(budget);
  }

  static String formatBudgetHelper(String? budgetStr) {
    if (budgetStr == null || budgetStr.trim().isEmpty) {
      return 'Договорная';
    }
    
    final clean = budgetStr.trim();
    
    final hasCurrency = clean.endsWith('₽') || 
                        clean.toLowerCase().endsWith('руб') || 
                        clean.toLowerCase().endsWith('руб.') ||
                        clean.toLowerCase().endsWith('рублей');
                        
    if (hasCurrency) {
      return clean;
    }
    
    if (clean.contains('-') || clean.toLowerCase().contains('от') || clean.toLowerCase().contains('до')) {
      return '$clean ₽';
    }
    
    final cleanDigits = clean.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanDigits.isNotEmpty) {
      final buffer = StringBuffer();
      for (int i = 0; i < cleanDigits.length; i++) {
        buffer.write(cleanDigits[i]);
        final reversedIndex = cleanDigits.length - 1 - i;
        if (reversedIndex % 3 == 0 && reversedIndex > 0) {
          buffer.write(' ');
        }
      }
      return '${buffer.toString()} ₽';
    }
    
    return '$clean ₽';
  }

  String get categoryEmoji => category.emoji;

  String get categoryName => category.displayName;

  String get formattedLocation {
    if (locationType == LocationType.district) {
      final districtStr = district != null && district!.isNotEmpty ? '$district р-н' : '';
      final settlementStr = settlement != null && settlement!.isNotEmpty ? 'с. $settlement' : '';
      if (districtStr.isNotEmpty && settlementStr.isNotEmpty) {
        return '$districtStr, $settlementStr';
      }
      return districtStr.isNotEmpty ? districtStr : (settlementStr.isNotEmpty ? settlementStr : 'Дагестан');
    } else {
      return city != null && city!.isNotEmpty ? 'г. $city' : 'г. Махачкала';
    }
  }

  String get workTypeName => workType?.displayName ?? 'Разовая работа';

  static const List<String> locationsOfDagestan = [
    'Махачкала',
    'Каспийск',
    'Дербент',
    'Хасавюрт',
    'Избербаш',
    'Буйнакск',
    'Кизляр',
    'Дагестанские Огни',
    'Южно-Сухокумск',
    'Агульский район',
    'Акушинский район',
    'Ахвахский район',
    'Ахтынский район',
    'Бабаюртовский район',
    'Ботлихский район',
    'Буйнакский район',
    'Гергебильский район',
    'Гунибский район',
    'Дахадаевский район',
    'Дербентский район',
    'Докузпаринский район',
    'Казбековский район',
    'Кайтагский район',
    'Карабудахкентский район',
    'Каayakентский район',
    'Кизлярский район',
    'Кулинский район',
    'Кумторкалинский район',
    'Курахский район',
    'Лакский район',
    'Левашинский район',
    'Магарамкентский район',
    'Новолакский район',
    'Ногайский район',
    'Рутульский район',
    'Сергокалинский район',
    'Сулейман-Стальский район',
    'Табасаранский район',
    'Тарумовский район',
    'Тляратинский район',
    'Унцукульский район',
    'Хасавюртовский район',
    'Хивский район',
    'Хунзахский район',
    'Цумадинский район',
    'Цунтинский район',
    'Чародинский район',
    'Шамильский район',
  ];

  static const Map<String, String> workTypes = {
    'one_time': 'Разовая работа',
    'permanent': 'Постоянная занятость',
    'project': 'Проектная работа',
  };

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
    JobCategory? category,
    String? budget,
    String? contactPhone,
    String? contactTelegram,
    JobStatus? status,
    DateTime? createdAt,
    List<String>? imageUrls,
    String? rejectionComment,
    bool clearRejectionComment = false,
    LocationType? locationType,
    String? city,
    String? district,
    String? settlement,
    WorkType? workType,
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
      locationType: locationType ?? this.locationType,
      city: city ?? this.city,
      district: district ?? this.district,
      settlement: settlement ?? this.settlement,
      workType: workType ?? this.workType,
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
      category: JobCategory.fromString(json['category'] as String? ?? 'other'),
      budget: json['budget'] as String?,
      contactPhone: json['contact_phone'] as String?,
      contactTelegram: json['contact_telegram'] as String?,
      status: JobStatus.fromString(json['status'] as String? ?? 'active'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      imageUrls: parsedImageUrls,
      rejectionComment: json['rejection_comment'] as String?,
      locationType: LocationType.fromString(json['location_type'] as String? ?? 'city'),
      city: json['city'] as String?,
      district: json['district'] as String?,
      settlement: json['settlement'] as String?,
      workType: json['work_type'] != null ? WorkType.fromString(json['work_type'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'budget': budget,
      'contact_phone': contactPhone,
      'contact_telegram': contactTelegram,
      'status': status.name,
      if (userId.isNotEmpty) 'user_id': userId,
      'image_urls': imageUrls,
      'rejection_comment': rejectionComment,
      'location_type': locationType.name,
      'city': city,
      'district': district,
      'settlement': settlement,
      'work_type': workType?.toDbString(),
    };
  }
}
