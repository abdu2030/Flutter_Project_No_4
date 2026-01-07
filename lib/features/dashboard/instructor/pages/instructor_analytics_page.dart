// lib/features/instructor/pages/instructor_analytics_page.dart

import 'package:flutter/material.dart';
import 'package:eduvox/core/models/course_model.dart';
import 'package:eduvox/core/services/course_service.dart';
import 'package:eduvox/core/services/auth_service.dart';
import 'package:eduvox/shared/theme/app_theme.dart';

class InstructorAnalyticsPage extends StatelessWidget {
  const InstructorAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService().currentUser?.uid ?? '';
    final theme = Theme.of(context);
    //final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Scaffold background is handled automatically by AppTheme.lightTheme/darkTheme
      appBar: AppBar(
        title: const Text('Analytics'),
        // AppTheme handles AppBar styling, but we ensure it matches the surface
        backgroundColor: theme.appBarTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: StreamBuilder<List<CourseModel>>(
        stream: CourseService().getInstructorCourses(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final courses = snapshot.data ?? [];

          // --- CALCULATIONS ---
          int totalStudents = 0;
          double totalRevenue = 0;
          double totalRatingSum = 0;
          int ratedCoursesCount = 0;

          // 1. Create a separate list for sorting (Fixes the cascade error)
          final sortedCourses = List<CourseModel>.from(courses);

          // 2. Sort the list here
          sortedCourses.sort(
            (a, b) =>
                b.enrolledStudents.length.compareTo(a.enrolledStudents.length),
          );

          for (var course in courses) {
            int students = course.enrolledStudents.length;
            totalStudents += students;
            totalRevenue += (course.price * students);

            if (course.rating > 0) {
              totalRatingSum += course.rating;
              ratedCoursesCount++;
            }
          }

          double avgRating = ratedCoursesCount > 0
              ? totalRatingSum / ratedCoursesCount
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. REVENUE CARD (Big)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: BoxDecoration(
                    // Using successColor for money, creating a gradient manually
                    // to match AppTheme style but keep semantic meaning
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.successColor,
                        AppTheme.successColor.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.successColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Estimated Revenue',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Text(
                        '$totalRevenue ETB',
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 32, // Specific size for emphasis
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),

                // 2. GRID STATS
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticTile(
                        context,
                        title: 'Total Students',
                        value: '$totalStudents',
                        icon: Icons.people_alt_rounded,
                        color: AppTheme.info, // Using AppTheme alias
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: _buildAnalyticTile(
                        context,
                        title: 'Avg Rating',
                        value: avgRating.toStringAsFixed(1),
                        icon: Icons.star_rounded,
                        color: AppTheme.warning, // Using AppTheme alias
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXL),

                // 3. TOP PERFORMING COURSES HEADER
                Text(
                  'Top Performing Courses',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.spacingM),

                if (courses.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      child: Text(
                        'No data available',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  )
                else
                  // 3. Use the sorted list
                  ...sortedCourses
                      .take(5)
                      .map((course) => _buildCourseRow(context, course)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalyticTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        // Use AppTheme shadows in light mode, simpler/none in dark
        boxShadow: isDark ? null : AppTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(title, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildCourseRow(BuildContext context, CourseModel course) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: isDark ? null : AppTheme.shadowSmall,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingXS,
        ),
        title: Text(
          course.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '${course.enrolledStudents.length} Students • ${course.rating} ★',
            style: theme.textTheme.bodySmall,
          ),
        ),
        trailing: Text(
          '${(course.price * course.enrolledStudents.length).toStringAsFixed(0)} ETB',
          style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.success),
        ),
      ),
    );
  }
}
