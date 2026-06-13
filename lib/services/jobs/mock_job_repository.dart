import 'dart:async';
import '../../../models/job_model.dart';
import '../../../models/application_model.dart';
import 'job_repository.dart';

class MockJobRepository implements JobRepository {
  static JobModel? getJobById(int id) {
    try {
      return _mockJobsDb.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }

  static final List<JobModel> _mockJobsDb = [
    JobModel(
      id: 1,
      userId: 'mock-user-2',
      userFirstName: 'Александр',
      userLastName: 'Петров',
      userUsername: 'sasha_fit',
      userEmojiAvatar: '💪',
      userIsVerified: true,
      title: 'Сделать сайт-визитку на Flutter',
      description: 'Необходимо разработать простой лендинг для рекламы спортивного зала. Вся текстовая информация и макет в Figma предоставлены. Жду ваших предложений.',
      category: JobCategory.freelance,
      budget: '15 000 ₽',
      contactPhone: '+7 (999) 765-43-21',
      contactTelegram: '@sasha_fit',
      status: JobStatus.active,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      locationType: LocationType.city,
      city: 'Махачкала',
      workType: WorkType.project,
    ),
    JobModel(
      id: 2,
      userId: 'mock-user-3',
      userFirstName: 'Мария',
      userLastName: 'Смирнова',
      userUsername: 'maria_zen',
      userEmojiAvatar: '🧘',
      userIsVerified: true,
      title: 'Дизайн логотипа студии йоги',
      description: 'Ищем талантливого дизайнера для создания минималистичного и нежного логотипа. Студия открывается через месяц, нужен также базовый брендбук.',
      category: JobCategory.freelance,
      budget: 'Договорная',
      contactPhone: '+7 (999) 111-22-33',
      contactTelegram: '@maria_zen',
      status: JobStatus.active,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      locationType: LocationType.city,
      city: 'Каспийск',
      workType: WorkType.oneTime,
    ),
    JobModel(
      id: 3,
      userId: 'mock-user-1',
      userFirstName: 'Иван',
      userLastName: 'Иванов',
      userUsername: 'ivanov',
      userEmojiAvatar: '🏃',
      userIsVerified: false,
      title: 'Укладка тротуарной плитки во дворе',
      description: 'Требуется бригада мастеров для укладки тротуарной плитки во дворе частного дома. Площадь около 80 кв.м. Материалы закуплены, инструмент ваш.',
      category: JobCategory.construction,
      budget: '50 000 ₽',
      contactPhone: '+7 (999) 123-45-67',
      contactTelegram: '@ivan_master',
      status: JobStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      locationType: LocationType.district,
      district: 'Гунибский',
      settlement: 'Чох',
      workType: WorkType.permanent,
    ),
    JobModel(
      id: 4,
      userId: 'mock-user-2',
      userFirstName: 'Александр',
      userLastName: 'Петров',
      userUsername: 'sasha_fit',
      userEmojiAvatar: '💪',
      userIsVerified: true,
      title: 'Перевозка мебели из Махачкалы в Каспийск',
      description: 'Нужно перевезти диван, два кресла и шкаф-купе. Требуется большая машина (Газель) и два грузчика. Желательно в субботу утром.',
      category: JobCategory.cargo,
      budget: '7 000 ₽',
      contactPhone: '+7 (999) 765-43-21',
      contactTelegram: '@sasha_fit',
      status: JobStatus.active,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      locationType: LocationType.district,
      district: 'Левашинский',
      settlement: 'Леваши',
      workType: WorkType.oneTime,
    ),
  ];

  @override
  Future<List<JobModel>> fetchJobs({
    String? category,
    int limit = 10,
    int offset = 0,
    String? locationType,
    String? city,
    String? district,
    String? workType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var filtered = _mockJobsDb.where((j) => j.status == JobStatus.active);
    
    if (category != null && category != 'all') {
      filtered = filtered.where((j) => j.category.name == category);
    }
    if (locationType != null) {
      filtered = filtered.where((j) => j.locationType.name == locationType);
    }
    if (city != null && city.isNotEmpty) {
      filtered = filtered.where((j) => j.city?.toLowerCase() == city.toLowerCase());
    }
    if (district != null && district.isNotEmpty) {
      filtered = filtered.where((j) => j.district?.toLowerCase() == district.toLowerCase());
    }
    if (workType != null && workType.isNotEmpty) {
      filtered = filtered.where((j) => j.workType?.toDbString() == workType);
    }
    
    final sorted = filtered.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (offset >= sorted.length) return [];
    final end = (offset + limit).clamp(0, sorted.length);
    return sorted.sublist(offset, end);
  }

  @override
  Future<List<JobModel>> fetchMyJobs(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockJobsDb.where((j) => j.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<JobModel> createJob({
    required String userId,
    required String title,
    required String description,
    required String category,
    String? budget,
    String? contactPhone,
    String? contactTelegram,
    List<String>? imageUrls,
    String locationType = 'city',
    String? city,
    String? district,
    String? settlement,
    String? workType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final newJob = JobModel(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: userId,
      userFirstName: 'Иван',
      userLastName: 'Иванов',
      userUsername: 'ivanov',
      userEmojiAvatar: '🏃',
      userIsVerified: false,
      title: title.trim(),
      description: description.trim(),
      category: JobCategory.fromString(category),
      budget: budget?.trim(),
      contactPhone: contactPhone?.trim(),
      contactTelegram: contactTelegram?.trim(),
      status: JobStatus.pending,
      createdAt: DateTime.now(),
      imageUrls: imageUrls ?? const [],
      rejectionComment: null,
      locationType: LocationType.fromString(locationType),
      city: city,
      district: district,
      settlement: settlement,
      workType: workType != null ? WorkType.fromString(workType) : null,
    );

    _mockJobsDb.insert(0, newJob);
    return newJob;
  }

  @override
  Future<void> updateJobStatus({required int jobId, required String userId, required String status}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _mockJobsDb.indexWhere((j) => j.id == jobId);
    if (index != -1) {
      _mockJobsDb[index] = _mockJobsDb[index].copyWith(status: JobStatus.fromString(status));
    }
  }

  @override
  Future<void> deleteJob({required int jobId, required String userId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _mockJobsDb.removeWhere((j) => j.id == jobId);
  }

  @override
  Future<JobModel> updateJob({
    required int jobId,
    required String userId,
    required String title,
    required String description,
    required String category,
    String? budget,
    String? contactPhone,
    String? contactTelegram,
    required List<String> imageUrls,
    required String status,
    String? rejectionComment,
    String locationType = 'city',
    String? city,
    String? district,
    String? settlement,
    String? workType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockJobsDb.indexWhere((j) => j.id == jobId);
    if (index == -1) {
      throw Exception('Работа не найдена');
    }

    final updated = _mockJobsDb[index].copyWith(
      title: title.trim(),
      description: description.trim(),
      category: JobCategory.fromString(category),
      budget: budget?.trim().isNotEmpty == true ? budget!.trim() : null,
      contactPhone: contactPhone?.trim().isNotEmpty == true ? contactPhone!.trim() : null,
      contactTelegram: contactTelegram?.trim().isNotEmpty == true ? contactTelegram!.trim() : null,
      imageUrls: imageUrls,
      status: JobStatus.fromString(status),
      rejectionComment: rejectionComment,
      clearRejectionComment: rejectionComment == null,
      locationType: LocationType.fromString(locationType),
      city: city,
      district: district,
      settlement: settlement,
      workType: workType != null ? WorkType.fromString(workType) : null,
    );

    _mockJobsDb[index] = updated;
    return updated;
  }

  static final List<ApplicationModel> _mockApplicationsDb = [];

  @override
  Future<void> applyToJob({required int jobId, required String applicantId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newApp = ApplicationModel(
      id: DateTime.now().millisecondsSinceEpoch,
      jobId: jobId,
      applicantId: applicantId,
      applicantFirstName: 'Тестовый',
      applicantLastName: 'Исполнитель',
      applicantUsername: 'test_worker',
      applicantEmojiAvatar: '😎',
      applicantIsVerified: true,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    _mockApplicationsDb.add(newApp);
  }

  @override
  Future<List<ApplicationModel>> fetchApplications(int jobId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockApplicationsDb.where((app) => app.jobId == jobId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> updateApplicationStatus({required int applicationId, required String status}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _mockApplicationsDb.indexWhere((app) => app.id == applicationId);
    if (index != -1) {
      final app = _mockApplicationsDb[index];
      _mockApplicationsDb[index] = ApplicationModel(
        id: app.id,
        jobId: app.jobId,
        applicantId: app.applicantId,
        applicantFirstName: app.applicantFirstName,
        applicantLastName: app.applicantLastName,
        applicantUsername: app.applicantUsername,
        applicantEmojiAvatar: app.applicantEmojiAvatar,
        applicantAvatarUrl: app.applicantAvatarUrl,
        applicantIsVerified: app.applicantIsVerified,
        status: status,
        createdAt: app.createdAt,
      );
    }
  }

  @override
  Future<List<ApplicationModel>> fetchMyApplications(String applicantId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockApplicationsDb.where((app) => app.applicantId == applicantId).toList();
  }
}
