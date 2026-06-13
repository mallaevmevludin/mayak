import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job_model.dart';
import '../models/application_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';
import 'jobs/job_repository.dart';
import 'jobs/mock_job_repository.dart';
import 'jobs/supabase_job_repository.dart';

class JobService extends ChangeNotifier {
  final AuthService _authService;
  late final JobRepository _repository;

  List<JobModel> _jobs = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<JobModel> get jobs => _jobs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool _hasMore = true;
  bool _isLoadingMore = false;
  String? _currentCategory;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  bool get _isMockMode => !SupabaseConfig.isConfigured;

  JobService(this._authService) {
    if (_isMockMode) {
      _repository = MockJobRepository();
    } else {
      _repository = SupabaseJobRepository();
    }

    _authService.addListener(_onAuthStatusChanged);
    if (_authService.currentUser != null) {
      fetchJobs(isRefresh: true);
    }
  }

  void _onAuthStatusChanged() {
    if (_authService.currentUser == null) {
      _jobs = [];
      _safeNotify();
    } else {
      fetchJobs(isRefresh: true);
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

  String? _currentLocationType;
  String? _currentCity;
  String? _currentDistrict;
  String? _currentWorkType;

  /// Fetch jobs with optional category filter and pagination
  Future<void> fetchJobs({
    String? category,
    bool isRefresh = false,
    String? locationType,
    String? city,
    String? district,
    String? workType,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final bool isCategoryChanged = category != _currentCategory;
    final bool isFiltersChanged = isCategoryChanged ||
        locationType != _currentLocationType ||
        city != _currentCity ||
        district != _currentDistrict ||
        workType != _currentWorkType;

    if (isRefresh || isFiltersChanged) {
      _jobs = [];
      _hasMore = true;
      _isLoadingMore = false;
      _currentCategory = category;
      _currentLocationType = locationType;
      _currentCity = city;
      _currentDistrict = district;
      _currentWorkType = workType;
    }

    if (!_hasMore) return;

    final bool isFirstLoad = _jobs.isEmpty;
    final int queryOffset = isFirstLoad ? 0 : _jobs.length;

    // Load cache first if empty
    if (isFirstLoad) {
      await _loadCachedJobs();
      _setLoading(true);
    } else {
      _isLoadingMore = true;
      _safeNotify();
    }

    _clearError();

    try {
      final fetched = await _repository.fetchJobs(
        category: category,
        limit: 10,
        offset: queryOffset,
        locationType: locationType,
        city: city,
        district: district,
        workType: workType,
      );

      if (fetched.length < 10) {
        _hasMore = false;
      }

      if (isRefresh || isFiltersChanged || isFirstLoad) {
        _jobs = fetched;
      } else {
        final existingIds = _jobs.map((j) => j.id).toSet();
        final newJobs = fetched.where((j) => !existingIds.contains(j.id)).toList();
        _jobs.addAll(newJobs);
      }

      if (!_isMockMode && (isRefresh || isFirstLoad) && (category == null || category == 'all') && locationType == null && city == null && district == null && workType == null) {
        await _saveCachedJobs(_jobs);
      }
      _safeNotify();
    } catch (e) {
      _setError(e.toString());
      if (_jobs.isEmpty) {
        await _loadCachedJobs();
      }
    } finally {
      _setLoading(false);
      _isLoadingMore = false;
      _safeNotify();
    }
  }

  /// Fetch jobs created by the current user
  Future<List<JobModel>> fetchMyJobs() async {
    final user = _authService.currentUser;
    if (user == null) return [];

    try {
      return await _repository.fetchMyJobs(user.id);
    } catch (e) {
      debugPrint('Error fetching my jobs: $e');
      return [];
    }
  }

  /// Create a new freelance job listing
  Future<JobModel?> createJob({
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
    final user = _authService.currentUser;
    if (user == null || title.trim().isEmpty || description.trim().isEmpty) return null;

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

    // Show optimistic job locally (e.g. for my jobs listing tab if applicable)
    _safeNotify();

    try {
      final created = await _repository.createJob(
        userId: user.id,
        title: title,
        description: description,
        category: category,
        budget: budget,
        contactPhone: contactPhone,
        contactTelegram: contactTelegram,
        imageUrls: imageUrls,
        locationType: locationType,
        city: city,
        district: district,
        settlement: settlement,
        workType: workType,
      );

      if (_isMockMode) {
        // In mock mode, replace the optimistic job with the returned job
        final idx = _jobs.indexWhere((j) => j.id == optimisticJob.id);
        if (idx != -1) {
          _jobs[idx] = created;
        }
      } else {
        // Add to local list in Supabase mode
        _jobs.insert(0, created);
      }
      _safeNotify();
      return created;
    } catch (e) {
      debugPrint('Error creating job: $e');
      _safeNotify();
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Close a job (mark as closed)
  Future<bool> closeJob(int jobId) async {
    return updateJobStatus(jobId, JobStatus.closed);
  }

  /// Update a job status (e.g. active, in_progress, completed, closed)
  Future<bool> updateJobStatus(int jobId, JobStatus status) async {
    _clearError();
    _setLoading(true);
    try {
      final user = _authService.currentUser;
      if (user == null) return false;

      await _repository.updateJobStatus(jobId: jobId, userId: user.id, status: status.name);

      // Update locally in _jobs list
      final index = _jobs.indexWhere((j) => j.id == jobId);
      if (index != -1) {
        if (status == JobStatus.active) {
          _jobs[index] = _jobs[index].copyWith(status: status);
        } else {
          // If it's not active anymore (e.g., in_progress, completed, closed), we remove it from the list of public jobs
          _jobs.removeAt(index);
        }
      }
      _safeNotify();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Apply for a job listing
  Future<bool> applyToJob(int jobId) async {
    final user = _authService.currentUser;
    if (user == null) return false;

    _setLoading(true);
    _clearError();
    try {
      await _repository.applyToJob(jobId: jobId, applicantId: user.id);
      _safeNotify();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch applications for a specific job
  Future<List<ApplicationModel>> fetchApplicationsForJob(int jobId) async {
    _clearError();
    try {
      return await _repository.fetchApplications(jobId);
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  /// Update application status (accept or decline)
  Future<bool> updateApplicationStatus(int applicationId, String status) async {
    _clearError();
    _setLoading(true);
    try {
      await _repository.updateApplicationStatus(applicationId: applicationId, status: status);
      _safeNotify();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch current user's job applications
  Future<List<ApplicationModel>> fetchMyApplications() async {
    final user = _authService.currentUser;
    if (user == null) return [];

    _clearError();
    try {
      return await _repository.fetchMyApplications(user.id);
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  /// Delete a job listing completely
  Future<bool> deleteJob(int jobId) async {
    _clearError();
    _setLoading(true);
    try {
      final user = _authService.currentUser;
      if (user == null) return false;

      await _repository.deleteJob(jobId: jobId, userId: user.id);

      _jobs.removeWhere((j) => j.id == jobId);
      _safeNotify();
      return true;
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
    String locationType = 'city',
    String? city,
    String? district,
    String? settlement,
    String? workType,
  }) async {
    final user = _authService.currentUser;
    if (user == null || title.trim().isEmpty || description.trim().isEmpty) return false;

    _setLoading(true);
    _clearError();

    try {
      final updated = await _repository.updateJob(
        jobId: jobId,
        userId: user.id,
        title: title,
        description: description,
        category: category,
        budget: budget,
        contactPhone: contactPhone,
        contactTelegram: contactTelegram,
        imageUrls: imageUrls,
        status: status,
        rejectionComment: rejectionComment,
        locationType: locationType,
        city: city,
        district: district,
        settlement: settlement,
        workType: workType,
      );

      if (_isMockMode) {
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
      } else {
        await fetchJobs(); // reload public active jobs in Supabase mode
      }
      _safeNotify();
      return true;
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
