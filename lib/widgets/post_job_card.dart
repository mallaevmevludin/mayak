import 'package:flutter/material.dart';
import '../models/job_model.dart';
import '../screens/job_detail_screen.dart';
import '../theme/app_theme.dart';
import 'scale_on_tap.dart';

class PostJobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback? onDelete;

  const PostJobCard({
    super.key,
    required this.job,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final cardColor = isDark 
        ? Colors.white.withValues(alpha: 0.03) 
        : const Color(0xFFF8F9FA);
    final borderColor = isDark 
        ? Colors.white.withValues(alpha: 0.08) 
        : const Color(0xFFE9ECEF);
    
    final hasBudget = job.budget != null && job.budget!.trim().isNotEmpty;
    final budgetColor = hasBudget ? AppTheme.success : (isDark ? Colors.white54 : Colors.black54);

    return ScaleOnTap(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailScreen(job: job),
          ),
        );
      },
      scaleFactor: 0.98,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with category badge and budget
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(job.categoryEmoji, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        job.categoryName,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Budget and delete button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      job.formattedBudget,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: budgetColor,
                      ),
                    ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onDelete,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? Colors.white.withValues(alpha: 0.08) 
                                  : Colors.black.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Job Title
            Text(
              job.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            // Location and work type
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    job.formattedLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.work_outline,
                  size: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                const SizedBox(width: 2),
                Text(
                  job.workTypeName,
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
    );
  }
}
