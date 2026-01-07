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

  // Selected Filter
  String? _selectedCourseId;

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Students'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<CourseModel>>(
        stream: _courseService.getInstructorCourses(userId),
        builder: (context, snapshot) {
          // 1. Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. No Data
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final allCourses = snapshot.data!;

          // 3. Filter Logic
          // If a course is selected in dropdown, use only that. Otherwise use all.
          final filteredCourses = _selectedCourseId != null
              ? allCourses.where((c) => c.id == _selectedCourseId).toList()
              : allCourses;

          // 4. Extract Unique Student IDs
          final Set<String> studentIds = {};
          for (var course in filteredCourses) {
            studentIds.addAll(course.enrolledStudents);
          }

          return Column(
            children: [
              // --- FILTER DROPDOWN ---
              Container(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedCourseId,
                  decoration: InputDecoration(
                    labelText: 'Filter by Course',
                    prefixIcon: const Icon(Icons.filter_list),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Courses'),
                    ),
                    ...allCourses.map((course) {
                      return DropdownMenuItem(
                        value: course.id,
                        child: Text(
                          course.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCourseId = value);
                  },
                ),
              ),

              // --- STUDENT LIST ---
              Expanded(
                child: studentIds.isEmpty
                    ? _buildNoStudentsState()
                    : _StudentListBuilder(
                        studentIds: studentIds.toList(),
                        allInstructorCourses: allCourses,
                      ),
              ),
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
            'No students found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing the filter or waiting for enrollments',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ✅ SEPARATE WIDGET FOR FETCHING USER DETAILS
// This separates the UI logic from the data fetching logic to prevent refresh loops
// ---------------------------------------------------------------------------
class _StudentListBuilder extends StatelessWidget {
  final List<String> studentIds;
  final List<CourseModel> allInstructorCourses;

  const _StudentListBuilder({
    required this.studentIds,
    required this.allInstructorCourses,
  });

  // Optimized Fetching: Uses 'whereIn' to fetch 10 students at a time
  Future<List<UserModel>> _fetchStudentsEfficiently() async {
    if (studentIds.isEmpty) return [];

    final List<UserModel> fetchedStudents = [];
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Firestore 'whereIn' is limited to 10 items. We must chunk the list.
    for (var i = 0; i < studentIds.length; i += 10) {
      final end = (i + 10 < studentIds.length) ? i + 10 : studentIds.length;
      final chunk = studentIds.sublist(i, end);

      try {
        final querySnapshot = await firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (var doc in querySnapshot.docs) {
          fetchedStudents.add(UserModel.fromMap(doc.data()));
        }
      } catch (e) {
        debugPrint("Error fetching student chunk: $e");
      }
    }

    return fetchedStudents;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: _fetchStudentsEfficiently(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading students: ${snapshot.error}'),
          );
        }

        final students = snapshot.data ?? [];

        if (students.isEmpty) {
          return const Center(child: Text("Could not load student details"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];

            // Calculate which courses THIS specific student is enrolled in
            // (Only checking courses that belong to this instructor)
            final enrolledIn = allInstructorCourses
                .where((c) => c.enrolledStudents.contains(student.uid))
                .toList();

            return _StudentCard(student: student, enrolledCourses: enrolledIn);
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// ✅ STUDENT CARD WIDGET
// ---------------------------------------------------------------------------
class _StudentCard extends StatelessWidget {
  final UserModel student;
  final List<CourseModel> enrolledCourses;

  const _StudentCard({required this.student, required this.enrolledCourses});

  @override
  Widget build(BuildContext context) {
    // Handle case where name might be null
    final displayName = student.name != null && student.name!.isNotEmpty
        ? student.name!
        : 'Student';

    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          backgroundImage:
              student.profileImage != null && student.profileImage!.isNotEmpty
              ? NetworkImage(student.profileImage!)
              : null,
          child: student.profileImage == null || student.profileImage!.isEmpty
              ? Text(
                  initial,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                )
              : null,
        ),
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          student.email,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${enrolledCourses.length} courses',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Enrolled In:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                ...enrolledCourses.map((course) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            course.title,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
