// lib/features/instructor/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:eduvox/core/models/course_model.dart';
import 'package:eduvox/core/services/course_service.dart';
import 'package:eduvox/core/services/auth_service.dart';
import 'package:eduvox/shared/widgets/dashboard_header.dart';
import 'package:eduvox/shared/widgets/action_button.dart';
import 'package:eduvox/features/dashboard/instructor/pages/instructor_analytics_page.dart';
import 'package:eduvox/shared/theme/app_theme.dart'; // Ensure this import exists
import '../dialogs/create_course_dialog.dart';
import '../screens/course_detail_screen.dart';

class InstructorHomePage extends StatelessWidget {
  const InstructorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final courseService = CourseService();
    final authService = AuthService();
    final userId = authService.currentUser?.uid ?? '';
    final theme = Theme.of(context);
    //final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashboardHeader(
              roleText: 'Instructor 🎓',
              icon: Icons.cast_for_education,
            ),
            const SizedBox(height: AppTheme.spacingL),

            // ✅ Stats Row
            StreamBuilder<List<CourseModel>>(
              stream: courseService.getInstructorCourses(userId),
              builder: (context, snapshot) {
                final courses = snapshot.data ?? [];
                final totalStudents = courses.fold<int>(
                  0,
                  (sum, course) => sum + course.enrolledStudents.length,
                );

                return Row(
                  children: [
                    Expanded(
                      child: _buildHighContrastStatCard(
                        context,
                        title: 'Courses',
                        value: '${courses.length}',
                        icon: Icons.book_rounded,
                        accentColor: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: _buildHighContrastStatCard(
                        context,
                        title: 'Students',
                        value: '$totalStudents',
                        icon: Icons.people_alt_rounded,
                        accentColor: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: _buildHighContrastStatCard(
                        context,
                        title: 'Published',
                        value: '${courses.where((c) => c.isPublished).length}',
                        icon: Icons.public,
                        accentColor: Colors.green,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppTheme.spacingL),

            // ✅ Quick Actions
            Row(
              children: [
                Expanded(
                  child: ActionButton(
                    title: 'Create Course',
                    icon: Icons.add_circle_outline,
                    color: Colors.deepPurple,
                    onTap: () async {
                      final course = await CreateCourseDialog.show(context);
                      if (course != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CourseDetailScreen(course: course),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: ActionButton(
                    title: 'Analytics',
                    icon: Icons.analytics_outlined,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InstructorAnalyticsPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Recent Courses Header
            Text('Recent Courses', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingM),

            // ✅ Course List
            StreamBuilder<List<CourseModel>>(
              stream: courseService.getInstructorCourses(userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(context);
                }

                final courses = snapshot.data!.take(3).toList();
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    return _buildCourseCard(context, courses[index]);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Stat Card (Kept your existing high contrast logic)
  Widget _buildHighContrastStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppTheme.spacingM,
        horizontal: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: theme.cardTheme.color, // Uses AppTheme.darkCard / lightCard
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        // Shadow for light mode
        boxShadow: isDark ? null : AppTheme.shadowSmall,
        // Border for dark mode to make it pop against the dark background
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : null,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED: Course Card to Stand Out
  Widget _buildCourseCard(BuildContext context, CourseModel course) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: theme.cardTheme.color, // Uses AppTheme colors
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        // 1. Light Mode: Add Shadow for depth
        boxShadow: isDark ? null : AppTheme.shadowSmall,
        // 2. Dark Mode: Add a thin, subtle border to define edges
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseDetailScreen(course: course),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    // Lighter purple background
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.play_circle_filled_rounded,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${course.enrolledStudents.length} Students • ${course.totalLessons} Lessons',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Arrow Icon
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.school_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No courses yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => CreateCourseDialog.show(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Your First Course'),
          ),
        ],
      ),
    );
  }
}
