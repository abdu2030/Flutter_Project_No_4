// lib/features/instructor/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:eduvox/core/models/course_model.dart';
import 'package:eduvox/core/services/course_service.dart';
import 'package:eduvox/core/services/auth_service.dart';
import 'package:eduvox/shared/widgets/dashboard_header.dart';
import 'package:eduvox/shared/widgets/stat_card.dart';
import 'package:eduvox/shared/widgets/action_button.dart';
import '../dialogs/create_course_dialog.dart';
import '../screens/course_detail_screen.dart';

class InstructorHomePage extends StatelessWidget {
  const InstructorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final courseService = CourseService();
    final authService = AuthService();
    final userId = authService.currentUser?.uid ?? '';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashboardHeader(
              roleText: 'Instructor 🎓',
              icon: Icons.cast_for_education,
            ),
            const SizedBox(height: 24),

            // ✅ Stats - Now spans full width
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
                      child: StatCard(
                        title: 'Courses',
                        value: '${courses.length}',
                        icon: Icons.book,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'Students',
                        value: '$totalStudents',
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'Published',
                        value: '${courses.where((c) => c.isPublished).length}',
                        icon: Icons.public,
                        color: Colors.green,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // ✅ Quick Actions - Now spans full width
            Row(
              children: [
                Expanded(
                  child: ActionButton(
                    title: 'Create Course',
                    icon: Icons.add_circle_outline,
                    color: Colors.deepPurple,
                    onTap: () async {
                      final course = await CreateCourseDialog.show(context);
                      if (course != null) {
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
                const SizedBox(width: 12),
                Expanded(
                  child: ActionButton(
                    title: 'Analytics',
                    icon: Icons.analytics,
                    color: Colors.orange,
                    onTap: () {
                      // TODO: Analytics
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Courses
            Text(
              'Recent Courses',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, CourseModel course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.play_circle, color: Colors.deepPurple),
        ),
        title: Text(
          course.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${course.totalLessons} lessons'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(course: course),
            ),
          );
        },
      ),
    );
  }
}
