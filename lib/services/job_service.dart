import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

class JobService extends ChangeNotifier {
  final AuthService _authService;

  List<JobModel> _jobs = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<JobModel> get jobs => _jobs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get _isMockMode => !SupabaseConfig.isConfigured;

  // Local mock databases
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
      category: 'freelance',
      budget: '15 000 ₽',
      contactPhone: '+7 (999) 765-43-21',
      contactTelegram: '@sasha_fit',
      status: 'active',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
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
      category: 'freelance',
      budget: 'Договорная',
      contactPhone: '+7 (999) 111-22-33',
      contactTelegram: '@maria_zen',
      status: 'active',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
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
      category: 'construction',
      budget: '50 000 ₽',
      contactPhone: '+7 (999) 123-45-67',
      contactTelegram: '@ivan_master',
      status: 'active',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
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
      category: 'cargo',
      budget: '7 000 ₽',
      contactPhone: '+7 (999) 765-43-21',
      contactTelegram: '@sasha_fit',
      status: 'active',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  JobService(this._authService) {
    _authService.addListener(_onAuthStatusChanged);
    if (_authService.currentUser != null) {
      fetchJobs();
    }
  }

  void _onAuthStatusChanged() {
    if (_authService.currentUser == null) {
      _jobs = [];
      _safeNotify();
    } else {
      fetchJobs();
    }
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthStatusChanged);
    super.dispose();
  }

  Future<void> _saveCachedJobs(List<JobModel> jobsToCache) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'cached_jobs_${_authService.currentUser?.id}';
      final encoded = jobsToCache
          .map(
            (j) => j.toJson()
              ..addAll({
                'id': j.id,
                'first_name': j.userFirstName,
                'last_name': j.userLastName,
                'username': j.userUsername,
                'emoji_avatar': j.userEmojiAvatar,
                'avatar_url': j.userAvatarUrl,
                'is_verified': j.userIsVerified,
                'created_at': j.createdAt.toIso8601String(),
              }),
          )
          .toList();
      await prefs.setString(key, jsonEncode(encoded));
    } catch (e) {
      debugPrint('Error caching jobs: $e');
    }
  }

  Future<void> _loadCachedJobs() async {
    final user = _authService.currentUser;
    if (user == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'cached_jobs_${user.id}';
      final rawData = prefs.getString(key);
      if (rawData != null) {
        final List<dynamic> decoded = jsonDecode(rawData);
        _jobs = decoded.map((item) => JobModel.fromJson(item)).toList();
        _safeNotify();
      }
    } catch (e) {
      debugPrint('Error loading cached jobs: $e');
    }
  }

  /// Fetch jobs with optional category filter
  Future<void> fetchJobs({String? category}) async {
    final user = _authService.currentUser;
    if (user == null) return;

    // Load cache first if empty
    if (_jobs.isEmpty) {
      await _loadCachedJobs();
    }

    _setLoading(true);
    _clearError();

    try {
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 300));
        var filtered = _mockJobsDb.where((j) => j.status == 'active');
        if (category != null && category != 'all') {
          filtered = filtered.where((j) => j.category == category);
        }
        _jobs = filtered.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        var queryBuilder = Supabase.instance.client
            .from('jobs')
            .select('''
              id, title, description, category, budget, status, created_at, user_id,
              contact_phone, contact_telegram, image_urls, rejection_comment,
              profiles:user_id(first_name, last_name, username, emoji_avatar, avatar_url, is_verified)
            ''')
            .eq('status', 'active');

        if (category != null && category != 'all') {
          queryBuilder = queryBuilder.eq('category', category);
        }

        final response = await queryBuilder.order('created_at', ascending: false);
        final List<dynamic> data = response;
        _jobs = data.map((json) => JobModel.fromJson(json)).toList();

        if (category == null || category == 'all') {
          await _saveCachedJobs(_jobs);
        }
      }
      _safeNotify();
    } catch (e) {
      _setError(e.toString());
      if (_jobs.isEmpty) {
        await _loadCachedJobs();
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch jobs created by the current user
  Future<List<JobModel>> fetchMyJobs() async {
    final user = _authService.currentUser;
    if (user == null) return [];

    try {
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 200));
        return _mockJobsDb.where((j) => j.userId == user.id).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        final response = await Supabase.instance.client
            .from('jobs')
            .select('''
              id, title, description, category, budget, status, created_at, user_id,
              contact_phone, contact_telegram, image_urls, rejection_comment,
              profiles:user_id(first_name, last_name, username, emoji_avatar, avatar_url, is_verified)
            ''')
            .eq('user_id', user.id)
            .order('created_at', ascending: false);

        final List<dynamic> data = response;
        return data.map((json) => JobModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching my jobs: $e');
      return [];
    }
  }

  /// Create a new freelance job listing
  Future<bool> createJob({
    required String title,
    required String description,
    required String category,
    String? budget,
    String? contactPhone,
    String? contactTelegram,
    List<String>? imageUrls,
  }) async {
    final user = _authService.currentUser;
    if (user == null || title.trim().isEmpty || description.trim().isEmpty) return false;

    _setLoading(true);
    _clearError();

    final optimisticJob = JobModel(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: user.id,
      userFirstName: user.firstName,
      userLastName: user.lastName,
      userUsername: user.username,
      userEmojiAvatar: user.emojiAvatar,
      userAvatarUrl: user.avatarUrl,
      userIsVerified: user.isVerified,
      title: title.trim(),
      description: description.trim(),
      category: category,
      budget: budget?.trim(),
      contactPhone: contactPhone?.trim(),
      contactTelegram: contactTelegram?.trim(),
      status: 'pending',
      createdAt: DateTime.now(),
      imageUrls: imageUrls ?? const [],
    );

    _safeNotify();

    try {
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 300));
        _mockJobsDb.insert(0, optimisticJob);
        return true;
      } else {
        final Map<String, dynamic> insertData = {
          'user_id': user.id,
          'title': title.trim(),
          'description': description.trim(),
          'category': category,
          'budget': budget?.trim().isNotEmpty == true ? budget!.trim() : null,
          'contact_phone': contactPhone?.trim().isNotEmpty == true ? contactPhone!.trim() : null,
          'contact_telegram': contactTelegram?.trim().isNotEmpty == true ? contactTelegram!.trim() : null,
          'status': 'pending',
          'image_urls': imageUrls ?? const [],
        };

        await Supabase.instance.client.from('jobs').insert(insertData);
        // Do not call fetchJobs() as it only fetches 'active' jobs
        return true;
      }
    } catch (e) {
      debugPrint('Error creating job: $e');
      _safeNotify();
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Close a job (mark as closed)
  Future<bool> closeJob(int jobId) async {
    _clearError();
    _setLoading(true);
    try {
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 200));
        final dbIndex = _mockJobsDb.indexWhere((j) => j.id == jobId);
        if (dbIndex != -1) {
          _mockJobsDb[dbIndex] = _mockJobsDb[dbIndex].copyWith(status: 'closed');
        }
        _jobs.removeWhere((j) => j.id == jobId);
        _safeNotify();
        return true;
      } else {
        final user = _authService.currentUser;
        if (user == null) return false;

        await Supabase.instance.client
            .from('jobs')
            .update({'status': 'closed'})
            .eq('id', jobId)
            .eq('user_id', user.id);

        _jobs.removeWhere((j) => j.id == jobId);
        _safeNotify();
        return true;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a job listing completely
  Future<bool> deleteJob(int jobId) async {
    _clearError();
    _setLoading(true);
    try {
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 200));
        _mockJobsDb.removeWhere((j) => j.id == jobId);
        _jobs.removeWhere((j) => j.id == jobId);
        _safeNotify();
        return true;
      } else {
        final user = _authService.currentUser;
        if (user == null) return false;

        await Supabase.instance.client
            .from('jobs')
            .delete()
            .eq('id', jobId)
            .eq('user_id', user.id);

        _jobs.removeWhere((j) => j.id == jobId);
        _safeNotify();
        return true;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing job listing
  Future<bool> updateJob({
    required int jobId,
    required String title,
    required String description,
    required String category,
    String? budget,
    String? contactPhone,
    String? contactTelegram,
    required List<String> imageUrls,
    required String status,
    String? rejectionComment,
  }) async {
    final user = _authService.currentUser;
    if (user == null || title.trim().isEmpty || description.trim().isEmpty) return false;

    _setLoading(true);
    _clearError();

    try {
      if (_isMockMode) {
        await Future.delayed(const Duration(milliseconds: 300));
        final dbIndex = _mockJobsDb.indexWhere((j) => j.id == jobId);
        if (dbIndex != -1) {
          final updated = _mockJobsDb[dbIndex].copyWith(
            title: title.trim(),
            description: description.trim(),
            category: category,
            budget: budget?.trim().isNotEmpty == true ? budget!.trim() : null,
            contactPhone: contactPhone?.trim().isNotEmpty == true ? contactPhone!.trim() : null,
            contactTelegram: contactTelegram?.trim().isNotEmpty == true ? contactTelegram!.trim() : null,
            imageUrls: imageUrls,
            status: status,
            rejectionComment: rejectionComment,
            clearRejectionComment: rejectionComment == null,
          );
          _mockJobsDb[dbIndex] = updated;

          // Update active jobs list
          final activeIndex = _jobs.indexWhere((j) => j.id == jobId);
          if (activeIndex != -1) {
            if (status == 'active') {
              _jobs[activeIndex] = updated;
            } else {
              _jobs.removeAt(activeIndex);
            }
          } else if (status == 'active') {
            _jobs.insert(0, updated);
          }
        }
        _safeNotify();
        return true;
      } else {
        final Map<String, dynamic> updateData = {
          'title': title.trim(),
          'description': description.trim(),
          'category': category,
          'budget': budget?.trim().isNotEmpty == true ? budget!.trim() : null,
          'contact_phone': contactPhone?.trim().isNotEmpty == true ? contactPhone!.trim() : null,
          'contact_telegram': contactTelegram?.trim().isNotEmpty == true ? contactTelegram!.trim() : null,
          'status': status,
          'image_urls': imageUrls,
          'rejection_comment': rejectionComment,
          'updated_at': DateTime.now().toIso8601String(),
        };

        await Supabase.instance.client
            .from('jobs')
            .update(updateData)
            .eq('id', jobId)
            .eq('user_id', user.id);

        await fetchJobs(); // reload public active jobs
        return true;
      }
    } catch (e) {
      debugPrint('Error updating job: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    _safeNotify();
  }

  void _setError(String msg) {
    _errorMessage = msg
        .replaceAll('Exception: ', '')
        .replaceAll('PostgrestException: ', '');
    _safeNotify();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      _safeNotify();
    }
  }

  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
