import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/job_model.dart';
import '../../../models/application_model.dart';
import 'job_repository.dart';

class SupabaseJobRepository implements JobRepository {
  final SupabaseClient _client = Supabase.instance.client;

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
    var queryBuilder = _client
        .from('jobs')
        .select('''
          id, title, description, category, budget, status, created_at, user_id,
          contact_phone, contact_telegram, image_urls, rejection_comment,
          location_type, city, district, settlement, work_type,
          profiles:user_id(first_name, last_name, username, emoji_avatar, avatar_url, is_verified)
        ''')
        .eq('status', 'active');

    if (category != null && category != 'all') {
      queryBuilder = queryBuilder.eq('category', category);
    }

    if (locationType != null) {
      queryBuilder = queryBuilder.eq('location_type', locationType);
    }
    if (city != null && city.isNotEmpty) {
      queryBuilder = queryBuilder.eq('city', city);
    }
    if (district != null && district.isNotEmpty) {
      queryBuilder = queryBuilder.eq('district', district);
    }
    if (workType != null && workType.isNotEmpty) {
      queryBuilder = queryBuilder.eq('work_type', workType);
    }

    final response = await queryBuilder
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    final List<dynamic> data = response;
    return data.map((json) => JobModel.fromJson(json)).toList();
  }

  @override
  Future<List<JobModel>> fetchMyJobs(String userId) async {
    final response = await _client
        .from('jobs')
        .select('''
          id, title, description, category, budget, status, created_at, user_id,
          contact_phone, contact_telegram, image_urls, rejection_comment,
          location_type, city, district, settlement, work_type,
          profiles:user_id(first_name, last_name, username, emoji_avatar, avatar_url, is_verified)
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final List<dynamic> data = response;
    return data.map((json) => JobModel.fromJson(json)).toList();
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
    final Map<String, dynamic> insertData = {
      'user_id': userId,
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'budget': budget?.trim().isNotEmpty == true ? budget!.trim() : null,
      'contact_phone': contactPhone?.trim().isNotEmpty == true ? contactPhone!.trim() : null,
      'contact_telegram': contactTelegram?.trim().isNotEmpty == true ? contactTelegram!.trim() : null,
      'status': 'pending',
      'image_urls': imageUrls ?? const [],
      'location_type': locationType,
      'city': city?.trim().isNotEmpty == true ? city!.trim() : null,
      'district': district?.trim().isNotEmpty == true ? district!.trim() : null,
      'settlement': settlement?.trim().isNotEmpty == true ? settlement!.trim() : null,
      'work_type': workType,
    };

    final response = await _client
        .from('jobs')
        .insert(insertData)
        .select('''
          id, title, description, category, budget, status, created_at, user_id,
          contact_phone, contact_telegram, image_urls, rejection_comment,
          location_type, city, district, settlement, work_type,
          profiles:user_id(first_name, last_name, username, emoji_avatar, avatar_url, is_verified)
        ''')
        .single();

    return JobModel.fromJson(response);
  }

  @override
  Future<void> updateJobStatus({required int jobId, required String userId, required String status}) async {
    await _client
        .from('jobs')
        .update({'status': status})
        .eq('id', jobId)
        .eq('user_id', userId);
  }

  @override
  Future<void> deleteJob({required int jobId, required String userId}) async {
    await _client
        .from('jobs')
        .delete()
        .eq('id', jobId)
        .eq('user_id', userId);
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
      'location_type': locationType,
      'city': city,
      'district': district,
      'settlement': settlement,
      'work_type': workType,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('jobs')
        .update(updateData)
        .eq('id', jobId)
        .eq('user_id', userId)
        .select('''
          id, title, description, category, budget, status, created_at, user_id,
          contact_phone, contact_telegram, image_urls, rejection_comment,
          location_type, city, district, settlement, work_type,
          profiles:user_id(first_name, last_name, username, emoji_avatar, avatar_url, is_verified)
        ''')
        .single();

    return JobModel.fromJson(response);
  }

  @override
  Future<void> applyToJob({required int jobId, required String applicantId}) async {
    await _client
        .from('job_applications')
        .insert({
          'job_id': jobId,
          'applicant_id': applicantId,
          'status': 'pending',
        });
  }

  @override
  Future<List<ApplicationModel>> fetchApplications(int jobId) async {
    final response = await _client
        .from('job_applications')
        .select('''
          id, job_id, applicant_id, status, created_at,
          profiles:applicant_id(first_name, last_name, username, emoji_avatar, avatar_url, is_verified)
        ''')
        .eq('job_id', jobId)
        .order('created_at', ascending: false);

    final List<dynamic> data = response;
    return data.map((json) => ApplicationModel.fromJson(json)).toList();
  }

  @override
  Future<void> updateApplicationStatus({required int applicationId, required String status}) async {
    await _client
        .from('job_applications')
        .update({'status': status})
        .eq('id', applicationId);
  }

  @override
  Future<List<ApplicationModel>> fetchMyApplications(String applicantId) async {
    final response = await _client
        .from('job_applications')
        .select('''
          id, job_id, applicant_id, status, created_at,
          profiles:applicant_id(first_name, last_name, username, emoji_avatar, avatar_url, is_verified)
        ''')
        .eq('applicant_id', applicantId);

    final List<dynamic> data = response;
    return data.map((json) => ApplicationModel.fromJson(json)).toList();
  }
}
