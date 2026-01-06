// lib/features/instructor/pages/my_courses_page.dart

import 'package:flutter/material.dart';
import 'package:eduvox/core/models/course_model.dart';
import 'package:eduvox/core/services/course_service.dart';
import 'package:eduvox/core/services/auth_service.dart';
import 'package:eduvox/features/dashboard/instructor/screens/course_detail_screen.dart';
import 'package:eduvox/features/dashboard/instructor/dialogs/create_course_dialog.dart';

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({super.key});

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CourseService _courseService = CourseService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Published'),
            Tab(text: 'Drafts'),
          ],
        ),
      ),
      body: StreamBuilder<List<CourseModel>>(
        stream: _courseService.getInstructorCourses(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final allCourses = snapshot.data!;
          final publishedCourses = allCourses
              .where((c) => c.isPublished)
              .toList();
          final draftCourses = allCourses.where((c) => !c.isPublished).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCourseList(allCourses),
              _buildCourseList(publishedCourses),
              _buildCourseList(draftCourses),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No courses yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first course to get started',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateCourseDialog(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Course'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseList(List<CourseModel> courses) {
    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No courses here', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return _buildCourseCard(course);
      },
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(course: course),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100,
                image: course.thumbnailUrl != null
                    ? DecorationImage(
                        image: NetworkImage(course.thumbnailUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: course.thumbnailUrl == null
                  ? Center(
                      child: Icon(
                        Icons.play_circle,
                        size: 48,
                        color: Colors.deepPurple.shade300,
                      ),
                    )
                  : null,
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          course.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusBadge(course.isPublished),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    course.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Stats Row
                  Row(
                    children: [
                      _buildStatChip(
                        Icons.play_circle_outline,
                        '${course.totalLessons} lessons',
                      ),
                      const SizedBox(width: 16),
                      _buildStatChip(
                        Icons.people_outline,
                        '${course.enrolledStudents.length} students',
                      ),
                      const SizedBox(width: 16),
                      _buildStatChip(
                        Icons.timer_outlined,
                        '${course.totalDuration} min',
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

  Widget _buildStatusBadge(bool isPublished) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPublished
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublished ? Icons.public : Icons.edit,
            size: 14,
            color: isPublished ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            isPublished ? 'Live' : 'Draft',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isPublished ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
