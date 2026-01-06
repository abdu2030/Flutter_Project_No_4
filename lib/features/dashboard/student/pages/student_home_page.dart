import 'package:eduvox/features/dashboard/student/pages/student_course_details_page.dart';
import 'package:eduvox/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eduvox/features/dashboard/student/student_provider.dart';

import 'package:eduvox/features/home/home_page.dart'; // The Browse/Marketplace Page

// ✅ YOUR SHARED WIDGETS
import 'package:eduvox/shared/widgets/dashboard_header.dart';
import 'package:eduvox/shared/widgets/stat_card.dart';
import 'package:eduvox/shared/widgets/course_card.dart'; // Ensure this matches StudentCourseCard logic or is the generic one
import 'package:eduvox/shared/widgets/action_button.dart';

class StudentHomePage extends ConsumerWidget {
  final Function(int) onSwitchTab; // Helper to switch tabs from buttons

  const StudentHomePage({super.key, required this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 📡 Watch Real Data
    final userAsync = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(studentStatsProvider);
    final coursesAsync = ref.watch(enrolledCoursesProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1️⃣ HEADER (Real User Data)
            userAsync.when(
              data: (user) => DashboardHeader(
                roleText: 'Student 👋',
                // Assuming DashboardHeader accepts a 'userName' or 'title'
                // If your widget doesn't have these, update the widget or use the params it has
                // I am adapting to the standard signature:
                // If it only takes (roleText, icon), I will stick to that,
                // but usually you want to pass the name:
                // userName: user?.displayName ?? 'Learner',
                icon: Icons.person,
              ),
              loading: () => const DashboardHeader(
                roleText: 'Loading...',
                icon: Icons.person,
              ),
              error: (_, __) => const DashboardHeader(
                roleText: 'Student 👋',
                icon: Icons.person,
              ),
            ),

            const SizedBox(height: 24),

            // 2️⃣ STATS ROW (Real Data)
            statsAsync.when(
              data: (stats) => Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Enrolled',
                      value: '${stats.enrolled}',
                      icon: Icons.book,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Completed',
                      value: '${stats.completed}',
                      icon: Icons.check,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'In Progress',
                      value: '${stats.inProgress}',
                      icon: Icons.pending,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox(),
            ),

            const SizedBox(height: 24),

            // 3️⃣ ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: ActionButton(
                    title: 'Browse Courses',
                    icon: Icons.search,
                    color: Colors.purple,
                    onTap: () {
                      // Navigate to the full Marketplace/Home Page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ActionButton(
                    title: 'My Progress',
                    icon: Icons.bar_chart,
                    color: Colors.teal,
                    onTap: () {
                      // Switch to "My Courses" tab (index 1)
                      onSwitchTab(1);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 4️⃣ RECENT COURSE (Real Data)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Continue Learning',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            coursesAsync.when(
              data: (courses) {
                if (courses.isEmpty) {
                  return _buildEmptyState(context);
                }

                // Get the most recent course
                final recent = courses.first;

                // Make sure your shared `CourseCard` accepts these parameters.
                // If it's `StudentCourseCard` from previous steps, it matches.
                // If it's a generic one, ensure the types align.
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StudentCourseDetailPage(courseId: recent.id),
                      ),
                    );
                  },
                  // Assuming your shared CourseCard looks like this:
                  child: CourseCard(
                    // Or StudentCourseCard
                    title: recent.title,
                    subtitle: recent.instructorName,
                    progress: recent.progress,
                    color: AppTheme.primary,
                    // If your CourseCard supports thumbnails:
                    // thumbnailUrl: recent.thumbnailUrl,
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.school_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('No courses enrolled yet'),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                );
              },
              child: const Text('Find a course'),
            ),
          ],
        ),
      ),
    );
  }
}
