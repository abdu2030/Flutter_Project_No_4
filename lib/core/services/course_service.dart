// lib/core/services/course_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==============================================================================
  // ✅ FOR STUDENTS: Get Only Published Courses
  // ==============================================================================
  Stream<List<CourseModel>> getPublishedCourses() {
    return _firestore
        .collection('courses')
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final courses = snapshot.docs
              .map((doc) => CourseModel.fromMap(doc.data()))
              .toList();

          // Sort by newest first
          courses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return courses;
        });
  }

  // ==============================================================================
  // ✅ FOR STUDENTS: Get Enrolled Courses (My Learning)
  // ==============================================================================
  Stream<List<Map<String, dynamic>>> getEnrolledCourses(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('enrolledCourses')
        .orderBy('enrolledAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  // ==============================================================================
  // ✅ FOR INSTRUCTORS: Get All Courses (Drafts + Published)
  // ==============================================================================
  Stream<List<CourseModel>> getInstructorCourses(String instructorId) {
    if (instructorId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('courses')
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map((snapshot) {
          final courses = snapshot.docs
              .map((doc) => CourseModel.fromMap(doc.data()))
              .toList();

          courses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return courses;
        });
  }

  // ✅ Create course
  Future<CourseModel> createCourse(CourseModel course) async {
    await _firestore.collection('courses').doc(course.id).set(course.toMap());
    return course;
  }

  // ✅ Get single course
  Future<CourseModel?> getCourse(String courseId) async {
    final doc = await _firestore.collection('courses').doc(courseId).get();
    if (doc.exists && doc.data() != null) {
      return CourseModel.fromMap(doc.data()!);
    }
    return null;
  }

  // ✅ Update course
  Future<void> updateCourse(CourseModel course) async {
    await _firestore
        .collection('courses')
        .doc(course.id)
        .update(course.toMap());
  }

  // ✅ Delete course
  Future<void> deleteCourse(String courseId) async {
    final lessons = await _firestore
        .collection('courses')
        .doc(courseId)
        .collection('lessons')
        .get();

    for (var doc in lessons.docs) {
      await doc.reference.delete();
    }
    await _firestore.collection('courses').doc(courseId).delete();
  }

  // ✅ Toggle publish
  Future<void> togglePublish(String courseId, bool isPublished) async {
    await _firestore.collection('courses').doc(courseId).update({
      'isPublished': isPublished,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // ✅ Get lessons for course (Stream)
  Stream<List<LessonModel>> getCourseLessons(String courseId) {
    return _firestore
        .collection('courses')
        .doc(courseId)
        .collection('lessons')
        .snapshots()
        .map((snapshot) {
          final lessons = snapshot.docs
              .map((doc) => LessonModel.fromMap(doc.data()))
              .toList();

          lessons.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
          return lessons;
        });
  }

  // ✅ Get lessons once
  Future<List<LessonModel>> getCourseLessonsOnce(String courseId) async {
    final snapshot = await _firestore
        .collection('courses')
        .doc(courseId)
        .collection('lessons')
        .get();

    final lessons = snapshot.docs
        .map((doc) => LessonModel.fromMap(doc.data()))
        .toList();

    lessons.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return lessons;
  }

  // ✅ Add lesson
  Future<LessonModel> addLesson(LessonModel lesson) async {
    await _firestore
        .collection('courses')
        .doc(lesson.courseId)
        .collection('lessons')
        .doc(lesson.id)
        .set(lesson.toMap());

    await _updateCourseStats(lesson.courseId);
    return lesson;
  }

  // ✅ Update lesson
  Future<void> updateLesson(LessonModel lesson) async {
    await _firestore
        .collection('courses')
        .doc(lesson.courseId)
        .collection('lessons')
        .doc(lesson.id)
        .update(lesson.toMap());
  }

  // ✅ Delete lesson
  Future<void> deleteLesson(String courseId, String lessonId) async {
    await _firestore
        .collection('courses')
        .doc(courseId)
        .collection('lessons')
        .doc(lessonId)
        .delete();

    await _updateCourseStats(courseId);
  }

  // ✅ Update course stats (Internal Helper)
  Future<void> _updateCourseStats(String courseId) async {
    final lessons = await getCourseLessonsOnce(courseId);

    final totalLessons = lessons.length;
    final totalDuration = lessons.fold<int>(0, (sum, l) => sum + l.duration);

    await _firestore.collection('courses').doc(courseId).update({
      'totalLessons': totalLessons,
      'totalDuration': totalDuration,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // --------------------------------------------------------------------------
  // ✅ RATE OR UPDATE COURSE (Logic Fixed)
  // --------------------------------------------------------------------------
  Future<void> rateCourse(
    String courseId,
    String userId,
    double newRating,
  ) async {
    final courseRef = _firestore.collection('courses').doc(courseId);
    final userReviewRef = courseRef.collection('reviews').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final courseSnapshot = await transaction.get(courseRef);
      final userReviewSnapshot = await transaction.get(userReviewRef);

      if (!courseSnapshot.exists) {
        throw Exception("Course does not exist!");
      }

      final data = courseSnapshot.data() as Map<String, dynamic>;
      double currentAvgRating = (data['rating'] ?? 0.0).toDouble();
      int currentReviewCount = (data['reviewCount'] ?? 0).toInt();

      // Calculate total points before this new rating
      double currentTotalScore = currentAvgRating * currentReviewCount;

      if (userReviewSnapshot.exists) {
        // 🔄 CASE 1: UPDATE EXISTING RATING
        final reviewData = userReviewSnapshot.data() as Map<String, dynamic>;
        double previousUserRating = (reviewData['rating'] ?? 0.0).toDouble();

        // 1. Remove old rating
        // 2. Add new rating
        double newTotalScore =
            currentTotalScore - previousUserRating + newRating;

        // 3. Recalculate average (Count does not change)
        double newAvg = newTotalScore / currentReviewCount;

        transaction.update(courseRef, {
          'rating': newAvg,
          // reviewCount stays the same
        });

        transaction.update(userReviewRef, {
          'rating': newRating,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // ➕ CASE 2: NEW RATING
        double newTotalScore = currentTotalScore + newRating;
        int newReviewCount = currentReviewCount + 1;
        double newAvg = newTotalScore / newReviewCount;

        transaction.update(courseRef, {
          'rating': newAvg,
          'reviewCount': newReviewCount,
        });

        transaction.set(userReviewRef, {
          'userId': userId,
          'rating': newRating,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
