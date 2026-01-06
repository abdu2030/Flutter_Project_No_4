// lib/features/instructor/pages/students_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduvox/core/models/course_model.dart';
import 'package:eduvox/core/models/user_model.dart';
import 'package:eduvox/core/services/course_service.dart';
import 'package:eduvox/core/services/auth_service.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final CourseService _courseService = CourseService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedCourseId;

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Students'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Course Filter Dropdown
          StreamBuilder<List<CourseModel>>(
            stream: _courseService.getInstructorCourses(userId),
            builder: (context, snapshot) {
              final courses = snapshot.data ?? [];

              return Container(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedCourseId,
                  decoration: InputDecoration(
                    labelText: 'Filter by Course',
                    prefixIcon: const Icon(Icons.filter_list),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Courses'),
                    ),
                    ...courses.map((course) {
                      return DropdownMenuItem(
                        value: course.id,
                        child: Text(course.title),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCourseId = value);
                  },
                ),
              );
            },
          ),

          // Students List
          Expanded(
            child: StreamBuilder<List<CourseModel>>(
              stream: _courseService.getInstructorCourses(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                // Get all unique student IDs
                final courses = _selectedCourseId != null
                    ? snapshot.data!
                          .where((c) => c.id == _selectedCourseId)
                          .toList()
                    : snapshot.data!;

                final studentIds = <String>{};
                for (var course in courses) {
                  studentIds.addAll(course.enrolledStudents);
                }

                if (studentIds.isEmpty) {
                  return _buildNoStudentsState();
                }

                return _buildStudentsList(studentIds.toList(), courses);
              },
            ),
          ),
        ],
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
            'Create courses to start getting students',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoStudentsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No students yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Publish your courses to attract students',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList(
    List<String> studentIds,
    List<CourseModel> courses,
  ) {
    return FutureBuilder<List<UserModel>>(
      future: _fetchStudents(studentIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final students = snapshot.data ?? [];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            final enrolledIn = courses
                .where((c) => c.enrolledStudents.contains(student.uid))
                .toList();

            return _buildStudentCard(student, enrolledIn);
          },
        );
      },
    );
  }

  Future<List<UserModel>> _fetchStudents(List<String> studentIds) async {
    final students = <UserModel>[];

    for (var id in studentIds) {
      try {
        final doc = await _firestore.collection('users').doc(id).get();
        if (doc.exists && doc.data() != null) {
          students.add(UserModel.fromMap(doc.data()!));
        }
      } catch (e) {
        print('Error fetching student $id: $e');
      }
    }

    return students;
  }

  Widget _buildStudentCard(
    UserModel student,
    List<CourseModel> enrolledCourses,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          backgroundImage: student.profileImage != null
              ? NetworkImage(student.profileImage!)
              : null,
          child: student.profileImage == null
              ? Text(
                  (student.name ?? student.email)[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(
          student.name ?? 'Student',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(student.email),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${enrolledCourses.length} courses',
            style: const TextStyle(fontSize: 12, color: Colors.blue),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enrolled Courses:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                ...enrolledCourses.map((course) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(course.title)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
