import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eduvox/shared/theme/app_theme.dart';
import 'package:eduvox/features/dashboard/student/student_provider.dart';
import 'package:eduvox/features/dashboard/student/pages/student_course_details_page.dart';

class MyCoursesPage extends ConsumerWidget {
  const MyCoursesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(enrolledCoursesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('My Learning'), centerTitle: false),
      body: coursesAsync.when(
        data: (courses) {
          if (courses.isEmpty) {
            return _buildEmptyState(theme, isDark);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) =>
                _buildCourseItem(context, courses[index], theme, isDark),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildCourseItem(
    BuildContext context,
    EnrolledCourse course,
    ThemeData theme,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentCourseDetailPage(courseId: course.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 100,
                height: 80,
                child: course.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: course.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (c, u) => Container(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                        ),
                        errorWidget: (c, u, e) =>
                            const Icon(Icons.broken_image, size: 40),
                      )
                    : Container(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.school_rounded,
                          color: AppTheme.primary.withValues(alpha: 0.5),
                          size: 40,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.instructorName,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: course.progress,
                            backgroundColor: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              course.isCompleted
                                  ? AppTheme.success
                                  : AppTheme.primary,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(course.progress * 100).toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: course.isCompleted
                              ? AppTheme.success
                              : AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_library_outlined,
            size: 80,
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No courses enrolled',
            style: theme.textTheme.titleLarge?.copyWith(
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Go to the Home tab to browse courses',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
