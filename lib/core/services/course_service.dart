// lib/core/services/course_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Get instructor's courses
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
      'totalDuration': totalDuration, // Kept as raw minutes for consistency
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // --------------------------------------------------------------------------
  // ⭐ NEW: Rate Course Feature
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

      // 1. Check if user already rated (Optional: Allow updating rating)
      // If you want to allow updates, you'd need to subtract the old rating first.
      // For now, let's assume one-time rating for simplicity.
      if (userReviewSnapshot.exists) {
        throw Exception("You have already rated this course.");
      }

      // 2. Get current data
      final data = courseSnapshot.data() as Map<String, dynamic>;
      double currentRating = (data['rating'] ?? 0.0).toDouble();
      int currentCount = (data['reviewCount'] ?? 0).toInt();

      // 3. Calculate new average
      // Formula: ((OldRating * OldCount) + NewRating) / (OldCount + 1)
      double newAverage =
          ((currentRating * currentCount) + newRating) / (currentCount + 1);

      // 4. Update Course Document
      transaction.update(courseRef, {
        'rating': newAverage,
        'reviewCount': currentCount + 1,
      });

      // 5. Create Review Document (to track who voted)
      transaction.set(userReviewRef, {
        'userId': userId,
        'rating': newRating,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }
}
