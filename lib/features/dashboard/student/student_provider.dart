import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ Enrolled Course Model (Matches Firestore data structure)
class EnrolledCourse {
  final String id; // The Course ID
  final String title;
  final String instructorName;
  final double progress; // 0.0 to 1.0
  final String? thumbnailUrl;
  final DateTime enrolledAt;
  final bool isCompleted;

  EnrolledCourse({
    required this.id,
    required this.title,
    required this.instructorName,
    this.progress = 0.0,
    this.thumbnailUrl,
    required this.enrolledAt,
    this.isCompleted = false,
  });

  factory EnrolledCourse.fromMap(Map<String, dynamic> map, String id) {
    return EnrolledCourse(
      id: id, // This is the document ID (Course ID)
      title: map['title'] ?? 'Untitled Course',
      instructorName: map['instructorName'] ?? 'Unknown',
      progress: (map['progress'] ?? 0.0).toDouble(),
      thumbnailUrl: map['thumbnailUrl'],
      enrolledAt: (map['enrolledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

// ✅ Student Stats Model
class StudentStats {
  final int enrolled;
  final int completed;
  final int inProgress;

  StudentStats({this.enrolled = 0, this.completed = 0, this.inProgress = 0});
}

// 1️⃣ Current User Stream
final currentUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.userChanges();
});

// 2️⃣ Enrolled Courses Stream
final enrolledCoursesProvider = StreamProvider<List<EnrolledCourse>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('enrolledCourses')
      .orderBy('enrolledAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => EnrolledCourse.fromMap(doc.data(), doc.id))
            .toList(),
      );
});

// 3️⃣ Calculated Stats
final studentStatsProvider = Provider<AsyncValue<StudentStats>>((ref) {
  final coursesAsync = ref.watch(enrolledCoursesProvider);

  return coursesAsync.when(
    data: (courses) {
      final completed = courses.where((c) => c.isCompleted).length;
      final inProgress = courses
          .where((c) => !c.isCompleted && c.progress > 0)
          .length;
      return AsyncValue.data(
        StudentStats(
          enrolled: courses.length,
          completed: completed,
          inProgress: inProgress,
        ),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});
