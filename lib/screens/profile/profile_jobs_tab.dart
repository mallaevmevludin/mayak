import 'package:flutter/material.dart';
import '../../models/job_model.dart';
import '../../theme/app_theme.dart';
import '../job_detail_screen.dart';

class ProfileJobsTab extends StatelessWidget {
  final List<JobModel> jobs;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final VoidCallback onJobDetailsReturned;

  const ProfileJobsTab({
    super.key,
    required this.jobs,
    required this.isLoading,
    required this.onRefresh,
    required this.onJobDetailsReturned,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primary,
          ),
        ),
      );
    }

    if (jobs.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppTheme.primary,
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 80.0, left: 32, right: 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.work_outline_rounded,
                      size: 40,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Нет заказов',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primary,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          Color statusColor = AppTheme.success;
          String statusText = 'Активен';
          if (job.status == JobStatus.closed) {
            statusColor = Colors.grey;
            statusText = 'Закрыт';
          } else if (job.status == JobStatus.pending) {
            statusColor = Colors.orange;
            statusText = 'На проверке';
          } else if (job.status == JobStatus.rejected) {
            statusColor = AppTheme.error;
            statusText = 'Отклонен';
          }

          return Card(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                width: 0.5,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JobDetailScreen(job: job),
                  ),
                );
                onJobDetailsReturned();
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${job.categoryEmoji} ${job.categoryName}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      job.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          job.formattedBudget,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: (job.status == JobStatus.closed || job.status == JobStatus.rejected) ? Colors.grey : AppTheme.success,
                          ),
                        ),
                        Text(
                          '${job.createdAt.day}.${job.createdAt.month}.${job.createdAt.year}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
