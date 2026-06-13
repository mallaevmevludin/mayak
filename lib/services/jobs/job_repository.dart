import '../../../models/job_model.dart';
import '../../../models/application_model.dart';

abstract class JobRepository {
  Future<List<JobModel>> fetchJobs({
    String? category,
    int limit = 10,
    int offset = 0,
    String? locationType,
    String? city,
    String? district,
    String? workType,
  });
  
  Future<List<JobModel>> fetchMyJobs(String userId);

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
  });

  Future<void> updateJobStatus({
    required int jobId,
    required String userId,
    required String status,
  });

  Future<void> deleteJob({
    required int jobId,
    required String userId,
  });

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
  });

  // Job application methods
  Future<void> applyToJob({required int jobId, required String applicantId});
  
  Future<List<ApplicationModel>> fetchApplications(int jobId);
  
  Future<void> updateApplicationStatus({required int applicationId, required String status});
  
  Future<List<ApplicationModel>> fetchMyApplications(String applicantId);
}

