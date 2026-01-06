// lib/features/dashboard/student/pages/course_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eduvox/shared/theme/app_theme.dart';
import 'package:eduvox/core/models/course_model.dart';
import 'package:eduvox/core/models/lesson_model.dart';
import 'package:eduvox/core/services/course_service.dart';
import 'package:eduvox/shared/widgets/course_detail_widgets.dart';
import 'package:eduvox/shared/screens/video_player_screen.dart';
import 'package:eduvox/shared/screens/document_viewer_screen.dart';
import 'package:eduvox/features/dashboard/student/student_dashboard.dart';
import 'package:eduvox/shared/dialogs/rating_dialog.dart';

class StudentCourseDetailPage extends StatefulWidget {
  final String courseId;

  const StudentCourseDetailPage({super.key, required this.courseId});

  @override
  State<StudentCourseDetailPage> createState() =>
      _StudentCourseDetailPageState();
}

class _StudentCourseDetailPageState extends State<StudentCourseDetailPage> {
  final CourseService _courseService = CourseService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  bool _isEnrolled = false;
  bool _isLoading = true;
  bool _isEnrolling = false; // Used for button loading state
  CourseModel? _course;
  Set<String> _completedLessons = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      final course = await _courseService.getCourse(widget.courseId);
      final isEnrolled =
          course?.enrolledStudents.contains(_currentUserId) ?? false;

      // Auto-repair missing user course data if they are in the list
      if (isEnrolled && course != null) {
        await _ensureUserHasCourseData(course);
      }

      // Fetch progress if enrolled
      if (isEnrolled) {
        final completedSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .collection('progress')
            .doc(widget.courseId)
            .get();

        if (completedSnapshot.exists) {
          final data = completedSnapshot.data();
          if (mounted) {
            setState(() {
              _completedLessons = Set<String>.from(
                data?['completedLessons'] ?? [],
              );
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _course = course;
          _isEnrolled = isEnrolled;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _ensureUserHasCourseData(CourseModel course) async {
    final userCourseRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('enrolledCourses')
        .doc(course.id);

    final docSnap = await userCourseRef.get();

    if (!docSnap.exists) {
      await userCourseRef.set({
        'courseId': course.id,
        'title': course.title,
        'instructorName': course.instructorName,
        'thumbnailUrl': course.thumbnailUrl,
        'enrolledAt': FieldValue.serverTimestamp(),
        'progress': 0.0,
        'isCompleted': false,
      });
    }
  }

  // ✅ ENROLLMENT LOGIC
  Future<void> _enrollInCourse() async {
    setState(() => _isEnrolling = true);

    try {
      // 1. Add user to Course's student list
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .update({
            'enrolledStudents': FieldValue.arrayUnion([_currentUserId]),
          });

      // 2. Add Course to User's enrolled list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .collection('enrolledCourses')
          .doc(widget.courseId)
          .set({
            'courseId': widget.courseId,
            'title': _course!.title,
            'instructorName': _course!.instructorName,
            'thumbnailUrl': _course!.thumbnailUrl,
            'enrolledAt': FieldValue.serverTimestamp(),
            'progress': 0.0,
            'isCompleted': false,
          });

      if (mounted) {
        // 3. Show Success Dialog
        await _showEnrollmentSuccessDialog();

        // 4. Navigate to Dashboard
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const StudentDashboard()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enrollment failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEnrolling = false);
      }
    }
  }

  // ✅ RATING LOGIC
  Future<void> _showRatingDialog() async {
    // 1. ✅ CAPTURE THE MESSENGER HERE (Before async gap)
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        onSubmitted: (rating) async {
          // We can set loading, but be careful with async gaps
          setState(() => _isLoading = true);

          try {
            await _courseService.rateCourse(
              widget.courseId,
              _currentUserId,
              rating,
            );

            // Refresh data
            final updatedCourse = await _courseService.getCourse(
              widget.courseId,
            );

            if (mounted) {
              setState(() {
                _course = updatedCourse;
                _isLoading = false;
              });

              // 2. ✅ USE THE CAPTURED VARIABLE (Not .of(context))
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Thanks for your rating!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              setState(() => _isLoading = false);

              // 3. ✅ USE THE CAPTURED VARIABLE HERE TOO
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(e.toString().replaceAll("Exception: ", "")),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          }
        },
      ),
    );
  }

  // ✅ UNENROLL LOGIC
  Future<void> _unenrollCourse() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unenroll?'),
        content: const Text('You will be removed from this course.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Unenroll'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isEnrolling = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .collection('enrolledCourses')
          .doc(widget.courseId)
          .delete();

      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .update({
            'enrolledStudents': FieldValue.arrayRemove([_currentUserId]),
          });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .collection('progress')
          .doc(widget.courseId)
          .delete();

      setState(() {
        _isEnrolled = false;
        _completedLessons.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unenrolled successfully'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isEnrolling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark
            ? AppTheme.darkBackground
            : AppTheme.lightBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_course == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course Not Found')),
        body: const Center(child: Text('Course not found')),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : AppTheme.lightBackground,
      body: StreamBuilder<List<LessonModel>>(
        stream: _courseService.getCourseLessons(_course!.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final lessons = snapshot.data ?? [];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // --- APP BAR ---
              CourseDetailAppBar(
                title: _course!.title,
                imageUrl: _course!.thumbnailUrl,
                accentColor: AppTheme.primaryColor,
                actions: [
                  if (_isEnrolled)
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black26,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onSelected: (value) {
                        if (value == 'unenroll') _unenrollCourse();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'unenroll',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Unenroll',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(width: 8),
                ],
              ),

              // --- CONTENT LIST ---
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (_isEnrolled) _buildProgressCard(isDark, lessons),
                    if (_isEnrolled) const SizedBox(height: 20),

                    _buildCategoryPriceRow(isDark),
                    const SizedBox(height: 20),

                    // ✅ STATS ROW (Rating, Students, Lessons)
                    CourseStatsRow(
                      rating: _course!.rating,
                      studentCount: _course!.enrolledStudents.length,
                      lessonCount: lessons.length,
                      duration:
                          '${(lessons.fold<int>(0, (sum, l) => sum + l.duration) / 60).toStringAsFixed(1)}h',
                      isDark: isDark,
                    ),

                    // ✅ RATING BUTTON & REVIEWS COUNT
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                '(${_course!.reviewCount} reviews)',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          // Only show "Rate" button if enrolled
                          if (_isEnrolled)
                            TextButton.icon(
                              onPressed: _showRatingDialog,
                              icon: const Icon(
                                Icons.star_rate_rounded,
                                size: 18,
                              ),
                              label: const Text('Rate Course'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.amber[700],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    const SectionHeader(title: 'About This Course'),
                    const SizedBox(height: 8),
                    Text(
                      _course!.description,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppTheme.textSecondary,
                        height: 1.6,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SectionHeader(title: 'Instructor'),
                    const SizedBox(height: 8),
                    InstructorInfoCard(
                      name: _course!.instructorName,
                      subtitle: 'Tap to view profile',
                      isDark: isDark,
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),
                    _buildWhatYouLearnSection(isDark),
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: 'Course Content',
                      actionText: '${lessons.length} lessons',
                    ),
                    const SizedBox(height: 12),
                  ]),
                ),
              ),

              // --- LESSONS LIST ---
              _buildLessonsList(isDark, lessons),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      bottomSheet: _buildBottomBar(isDark),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildProgressCard(bool isDark, List<LessonModel> lessons) {
    int total = lessons.length;
    int completed = _completedLessons.length;
    double progress = total == 0 ? 0 : completed / total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$completed of $total lessons completed',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPriceRow(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _course!.category,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const Spacer(),
        if (!_isEnrolled)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _course!.price == 0
                  ? AppTheme.successColor.withValues(alpha: 0.1)
                  : AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _course!.price == 0 ? 'FREE' : '\$${_course!.price}',
              style: TextStyle(
                color: _course!.price == 0
                    ? AppTheme.successColor
                    : AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        if (_isEnrolled)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor,
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  'Enrolled',
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildWhatYouLearnSection(bool isDark) {
    final learningPoints = [
      'Understand the core concepts of the subject',
      'Apply knowledge through practical examples',
      'Develop critical thinking skills',
      'Enhance problem-solving abilities',
      'Prepare for advanced topics and applications',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: "What You'll Learn"),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: learningPoints
                .map(
                  (point) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0x1A4CAF50),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: AppTheme.successColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            point,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLessonsList(bool isDark, List<LessonModel> lessons) {
    if (lessons.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'No lessons available yet',
                style: TextStyle(
                  color: isDark ? Colors.white54 : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) =>
              _buildLessonTile(lessons[index], index, isDark, lessons),
          childCount: lessons.length,
        ),
      ),
    );
  }

  Widget _buildLessonTile(
    LessonModel lesson,
    int index,
    bool isDark,
    List<LessonModel> allLessons,
  ) {
    final isLocked = !_isEnrolled && !lesson.isFree;
    final isCompleted = _completedLessons.contains(lesson.id);
    final hasVideo = lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty;
    final hasDoc = lesson.documentUrl != null && lesson.documentUrl!.isNotEmpty;
    final hasBoth = hasVideo && hasDoc;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCompleted
            ? Border.all(
                color: AppTheme.successColor.withValues(alpha: 0.5),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (isLocked) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Enroll to access this lesson'),
                  backgroundColor: AppTheme.warningColor,
                ),
              );
            } else {
              _openLesson(lesson, allLessons);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: isLocked
                        ? LinearGradient(
                            colors: [
                              Colors.grey.shade400,
                              Colors.grey.shade500,
                            ],
                          )
                        : isCompleted
                        ? LinearGradient(
                            colors: [
                              AppTheme.successColor,
                              AppTheme.successColor.withValues(alpha: 0.7),
                            ],
                          )
                        : hasVideo
                        ? const LinearGradient(
                            colors: [Color(0xFFE53935), Color(0xFFEF5350)],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
                          ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isLocked
                        ? null
                        : [
                            BoxShadow(
                              color:
                                  (isCompleted
                                          ? AppTheme.successColor
                                          : hasVideo
                                          ? Colors.red
                                          : Colors.blue)
                                      .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        isLocked
                            ? Icons.lock_rounded
                            : isCompleted
                            ? Icons.check_rounded
                            : hasVideo
                            ? Icons.play_arrow_rounded
                            : Icons.description_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      if (hasBoth && !isLocked && !isCompleted)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: hasVideo ? Colors.blue : Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              hasVideo ? Icons.description : Icons.play_arrow,
                              color: Colors.white,
                              size: 8,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isLocked
                              ? (isDark ? Colors.white38 : Colors.grey)
                              : (isDark ? Colors.white : AppTheme.textPrimary),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildInfoBadge(
                            Icons.access_time_rounded,
                            '${lesson.duration} min',
                            isDark ? Colors.white54 : Colors.grey,
                          ),
                          if (hasVideo)
                            _buildContentBadge(
                              'Video',
                              isLocked ? Colors.grey : Colors.red,
                            ),
                          if (hasDoc)
                            _buildContentBadge(
                              'Doc',
                              isLocked ? Colors.grey : Colors.blue,
                            ),
                          if (lesson.isFree && !_isEnrolled)
                            _buildContentBadge(
                              'Free Preview',
                              AppTheme.successColor,
                            ),
                          if (isCompleted)
                            _buildContentBadge(
                              'Completed',
                              AppTheme.successColor,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  isLocked
                      ? Icons.lock_outline_rounded
                      : Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: isLocked
                      ? (isDark ? Colors.white24 : Colors.grey.shade300)
                      : (isDark ? Colors.white38 : Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }

  Widget _buildContentBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!_isEnrolled) ...[
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Price',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _course!.price == 0 ? 'Free' : '\$${_course!.price}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
            ],
            Expanded(
              child: StreamBuilder<List<LessonModel>>(
                stream: _courseService.getCourseLessons(_course!.id),
                builder: (context, snapshot) {
                  final lessons = snapshot.data ?? [];
                  return ElevatedButton(
                    onPressed: _isEnrolling
                        ? null
                        : _isEnrolled
                        ? () => _continueLearning(lessons)
                        : _enrollInCourse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isEnrolling
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isEnrolled
                                    ? Icons.play_arrow_rounded
                                    : Icons.school_rounded,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isEnrolled
                                    ? 'Continue Learning'
                                    : 'Enroll Now',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ SUCCESS DIALOG
  Future<void> _showEnrollmentSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.successColor,
                      size: 64,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Enrollment Successful! 🎉',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'You have been enrolled in',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _course!.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildSuccessInfoRow(
                        Icons.play_lesson_rounded,
                        'Access all lessons',
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildSuccessInfoRow(
                        Icons.quiz_rounded,
                        'Take quizzes & assignments',
                        Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _buildSuccessInfoRow(
                        Icons.card_membership_rounded,
                        'Earn certificate on completion',
                        AppTheme.successColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.dashboard_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Go to My Courses',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        Icon(Icons.check_circle, color: color, size: 18),
      ],
    );
  }

  // --- CONTENT NAVIGATION ---
  void _openLesson(LessonModel lesson, List<LessonModel> allLessons) {
    final hasVideo = lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty;
    final hasDoc = lesson.documentUrl != null && lesson.documentUrl!.isNotEmpty;

    if (hasVideo && hasDoc) {
      _showContentOptions(lesson, allLessons);
    } else if (hasVideo) {
      _navigateToVideo(lesson, allLessons);
    } else if (hasDoc) {
      _navigateToDoc(lesson, allLessons);
    }
  }

  void _showContentOptions(LessonModel lesson, List<LessonModel> allLessons) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text(
                        lesson.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select content to view',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white54
                              : AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFEF5350)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  title: const Text(
                    'Watch Video',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Play the video lesson',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToVideo(lesson, allLessons);
                  },
                ),
                Divider(
                  height: 1,
                  indent: 80,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  title: const Text(
                    'Read Document',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'View attached materials',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToDoc(lesson, allLessons);
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToVideo(LessonModel lesson, List<LessonModel> allLessons) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(videoUrl: lesson.videoUrl!),
      ),
    ).then((_) => _markLessonComplete(lesson.id, allLessons));
  }

  void _navigateToDoc(LessonModel lesson, List<LessonModel> allLessons) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentViewerScreen(
          documentUrl: lesson.documentUrl!,
          title: lesson.title,
        ),
      ),
    ).then((_) => _markLessonComplete(lesson.id, allLessons));
  }

  Future<void> _markLessonComplete(
    String lessonId,
    List<LessonModel> allLessons,
  ) async {
    if (!_isEnrolled || _completedLessons.contains(lessonId)) return;

    setState(() {
      _completedLessons.add(lessonId);
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('progress')
        .doc(widget.courseId)
        .set({
          'completedLessons': _completedLessons.toList(),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    double progress = allLessons.isEmpty
        ? 0
        : _completedLessons.length / allLessons.length;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('enrolledCourses')
        .doc(widget.courseId)
        .update({'progress': progress, 'isCompleted': progress >= 1.0});
  }

  void _continueLearning(List<LessonModel> lessons) {
    if (lessons.isEmpty) return;

    final nextLesson = lessons.firstWhere(
      (l) => !_completedLessons.contains(l.id),
      orElse: () => lessons.first,
    );
    _openLesson(nextLesson, lessons);
  }
}
