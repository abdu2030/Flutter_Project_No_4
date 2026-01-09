// lib/features/dashboard/student/pages/course_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

// Core & Shared
import 'package:eduvox/shared/theme/app_theme.dart';
import 'package:eduvox/core/models/course_model.dart';
import 'package:eduvox/core/models/lesson_model.dart';
import 'package:eduvox/core/models/user_model.dart'; 
import 'package:eduvox/core/services/course_service.dart';
import 'package:eduvox/core/services/auth_service.dart'; 
import 'package:eduvox/core/services/chapa_service.dart';

// Widgets & Screens
import 'package:eduvox/shared/widgets/course_detail_widgets.dart';
import 'package:eduvox/shared/screens/video_player_screen.dart';
import 'package:eduvox/shared/screens/document_viewer_screen.dart';
import 'package:eduvox/shared/screens/chapa_payment_screen.dart';
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

  
  String? _currentUserEmail;
  String? _currentUserFirstName;
  String? _currentUserLastName;

  bool _isEnrolled = false;
  bool _isLoading = true;
  bool _isEnrolling = false;

  CourseModel? _course;
  Set<String> _completedLessons = {};
  double? _userRating;

  @override
  void initState() {
    super.initState();
    _initData();
    _loadUserData();
  }

 

  Future<void> _loadUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (userDoc.exists && mounted) {
        final data = userDoc.data()!;
        setState(() {
          _currentUserEmail = data['email'] ?? '';
          _currentUserFirstName =
              data['firstName'] ?? data['name']?.split(' ').first ?? 'User';
          _currentUserLastName =
              data['lastName'] ?? data['name']?.split(' ').last ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _initData() async {
    try {
      final course = await _courseService.getCourse(widget.courseId);
      final isEnrolled =
          course?.enrolledStudents.contains(_currentUserId) ?? false;

      if (isEnrolled && course != null) {
        await _ensureUserHasCourseData(course);

        // Fetch progress
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

        
        final reviewDoc = await FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.courseId)
            .collection('reviews')
            .doc(_currentUserId)
            .get();

        if (reviewDoc.exists && mounted) {
          setState(() {
            _userRating = (reviewDoc.data()?['rating'] ?? 0).toDouble();
          });
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



  void _showInstructorProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.4,
        maxChildSize: 0.7,
        builder: (_, controller) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: FutureBuilder<UserModel?>(
              future: AuthService().getUserData(_course!.instructorId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: Text("Instructor info unavailable"),
                  );
                }

                final instructor = snapshot.data!;
                final socials = instructor.socials ?? {};

                return ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Avatar & Name
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppTheme.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            backgroundImage: instructor.profileImage != null
                                ? NetworkImage(instructor.profileImage!)
                                : null,
                            child: instructor.profileImage == null
                                ? Text(
                                    (instructor.name ?? 'I')[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            instructor.name ?? 'Instructor',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            instructor.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white60 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      "Connect",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildContactTile(
                      icon: Icons.email_outlined,
                      title: "Email",
                      subtitle: instructor.email,
                      onTap: () {},
                      isDark: isDark,
                    ),

                    if (instructor.phone != null &&
                        instructor.phone!.isNotEmpty)
                      _buildContactTile(
                        icon: Icons.phone_outlined,
                        title: "Phone",
                        subtitle: instructor.phone!,
                        onTap: () {},
                        isDark: isDark,
                      ),

                    const SizedBox(height: 16),

                    if (socials.isNotEmpty) ...[
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        "Social Media",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          if (socials['website']?.isNotEmpty ?? false)
                            _buildSocialChip(
                              Icons.language,
                              "Website",
                              socials['website'],
                              isDark,
                            ),
                          if (socials['linkedin']?.isNotEmpty ?? false)
                            _buildSocialChip(
                              Icons.business,
                              "LinkedIn",
                              socials['linkedin'],
                              isDark,
                            ),
                          if (socials['twitter']?.isNotEmpty ?? false)
                            _buildSocialChip(
                              Icons.alternate_email,
                              "Twitter/X",
                              socials['twitter'],
                              isDark,
                            ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  // --- UI HELPERS FOR MODAL ---

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSocialChip(
    IconData icon,
    String label,
    String? url,
    bool isDark,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: AppTheme.primaryColor,
      side: BorderSide.none,
      onPressed: () {
        debugPrint("Opening $url");
      },
    );
  }

  // --- MAIN BUILD METHOD ---

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
              // 1. App Bar
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

              // 2. Content List
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (_isEnrolled) _buildProgressCard(isDark, lessons),
                    if (_isEnrolled) const SizedBox(height: 20),
                    _buildCategoryPriceRow(isDark),
                    const SizedBox(height: 20),
                    CourseStatsRow(
                      rating: _course!.rating,
                      studentCount: _course!.enrolledStudents.length,
                      lessonCount: lessons.length,
                      duration:
                          '${(_course!.totalDuration / 60).toStringAsFixed(1)}h',
                      isDark: isDark,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          if (_isEnrolled)
                            TextButton.icon(
                              onPressed: _showRatingDialog,
                              icon: Icon(
                                _userRating != null
                                    ? Icons.star
                                    : Icons.star_border_rounded,
                                size: 18,
                                color: _userRating != null
                                    ? Colors.amber[700]
                                    : AppTheme.primaryColor,
                              ),
                              label: Text(
                                _userRating != null
                                    ? 'You rated: $_userRating'
                                    : 'Rate Course',
                                style: TextStyle(
                                  fontWeight: _userRating != null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: _userRating != null
                                    ? Colors.amber[700]
                                    : AppTheme.primaryColor,
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

                    // ✅ Instructor Card with onTap
                    InstructorInfoCard(
                      name: _course!.instructorName,
                      subtitle: 'Tap to view profile',
                      isDark: isDark,
                      onTap: _showInstructorProfile, // Connected!
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

              // 3. Lessons List
              _buildLessonsList(isDark, lessons),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      bottomSheet: _buildBottomBar(isDark),
    );
  }

  // --- HELPER WIDGETS ---

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
            children:
                [
                      'Understand the core concepts',
                      'Apply knowledge practically',
                      'Develop critical thinking',
                    ]
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: isLocked
                ? LinearGradient(
                    colors: [Colors.grey.shade400, Colors.grey.shade500],
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
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Main Icon
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

              // Second Icon Overlay (Only if Both and Not Completed/Locked)
              if (hasBoth && !isLocked && !isCompleted)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.description,
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                ),
            ],
          ),
        ),
        title: Text(
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
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: isDark ? Colors.white38 : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                '${lesson.duration} min',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 12),

              // Content Badges
              if (hasVideo) _buildContentBadge('Video', Colors.red),
              if (hasDoc) ...[
                const SizedBox(width: 6),
                _buildContentBadge('Doc', Colors.blue),
              ],
              if (lesson.isFree && !_isEnrolled) ...[
                const SizedBox(width: 6),
                _buildContentBadge('Free', AppTheme.successColor),
              ],
            ],
          ),
        ),
        trailing: Icon(
          isLocked
              ? Icons.lock_outline_rounded
              : Icons.arrow_forward_ios_rounded,
          size: 18,
          color: isLocked
              ? (isDark ? Colors.white24 : Colors.grey.shade300)
              : (isDark ? Colors.white38 : Colors.grey),
        ),
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
      ),
    );
  }

  // Helper for the colored badges (Video, Doc, Free)
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
                                    : _course!.price == 0
                                    ? 'Enroll Now - Free'
                                    : 'Pay ${_course!.price} ETB',
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

  // --- LOGIC FUNCTIONS ---

  Future<void> _enrollInCourse() async {
    if (_course == null) return;
    if (_course!.price == 0) {
      await _completeFreeEnrollment();
    } else {
      await _initiatePayment();
    }
  }

  Future<void> _initiatePayment() async {
    setState(() => _isEnrolling = true);
    try {
      final txRef =
          'EDUVOX-${const Uuid().v4().substring(0, 8).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}';
      await FirebaseFirestore.instance.collection('payments').doc(txRef).set({
        'txRef': txRef,
        'userId': _currentUserId,
        'courseId': widget.courseId,
        'courseTitle': _course!.title,
        'amount': _course!.price,
        'currency': 'ETB',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final response = await ChapaService.initializePayment(
        amount: _course!.price.toString(),
        email: _currentUserEmail ?? 'user@example.com',
        firstName: _currentUserFirstName ?? 'User',
        lastName: _currentUserLastName ?? '',
        txRef: txRef,
        courseId: widget.courseId,
        courseTitle: _course!.title,
      );

      if (!mounted) return;

      if (response.success && response.checkoutUrl != null) {
        setState(() => _isEnrolling = false);
        final result = await Navigator.push<ChapaPaymentResult>(
          context,
          MaterialPageRoute(
            builder: (context) => ChapaPaymentScreen(
              checkoutUrl: response.checkoutUrl!,
              txRef: txRef,
              courseTitle: _course!.title,
            ),
          ),
        );
        await _handlePaymentResult(result, txRef);
      } else {
        setState(() => _isEnrolling = false);
        _showErrorSnackBar(response.message);
      }
    } catch (e) {
      setState(() => _isEnrolling = false);
      _showErrorSnackBar('Payment error: $e');
    }
  }

  Future<void> _handlePaymentResult(
    ChapaPaymentResult? result,
    String txRef,
  ) async {
    if (result == null) {
      await _updatePaymentStatus(txRef, 'cancelled');
      _showErrorSnackBar('Payment was cancelled');
      return;
    }
    switch (result.status) {
      case PaymentStatus.success:
        setState(() => _isEnrolling = true);
        final verification = await ChapaService.verifyPayment(txRef);
        if (verification.isSuccessful) {
          await _updatePaymentStatus(txRef, 'success');
          await _completePaidEnrollment(txRef);
        } else {
          setState(() => _isEnrolling = false);
          await _updatePaymentStatus(txRef, 'failed');
          _showErrorSnackBar('Verification failed.');
        }
        break;
      case PaymentStatus.failed:
        await _updatePaymentStatus(txRef, 'failed');
        _showErrorSnackBar(result.message ?? 'Payment failed');
        break;
      case PaymentStatus.cancelled:
        await _updatePaymentStatus(txRef, 'cancelled');
        _showErrorSnackBar('Payment was cancelled');
        break;
      case PaymentStatus.pending:
        _showWarningSnackBar('Payment is pending.');
        break;
    }
  }

  Future<void> _updatePaymentStatus(String txRef, String status) async {
    try {
      await FirebaseFirestore.instance.collection('payments').doc(txRef).update(
        {'status': status, 'updatedAt': FieldValue.serverTimestamp()},
      );
    } catch (e) {
      debugPrint('Error updating payment status: $e');
    }
  }

  Future<void> _completeFreeEnrollment() async {
    setState(() => _isEnrolling = true);
    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .update({
            'enrolledStudents': FieldValue.arrayUnion([_currentUserId]),
          });
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
            'paidAmount': 0,
          });
      if (mounted) {
        await _showEnrollmentSuccessDialog();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const StudentDashboard()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('Enrollment failed: $e');
    } finally {
      if (mounted) setState(() => _isEnrolling = false);
    }
  }

  Future<void> _completePaidEnrollment(String txRef) async {
    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .update({
            'enrolledStudents': FieldValue.arrayUnion([_currentUserId]),
          });
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
            'paymentTxRef': txRef,
            'paidAmount': _course!.price,
          });
      if (mounted) {
        await _showEnrollmentSuccessDialog();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const StudentDashboard()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('Enrollment failed: $e');
    } finally {
      if (mounted) setState(() => _isEnrolling = false);
    }
  }

  Future<void> _showRatingDialog() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        onSubmitted: (rating) async {
          setState(() => _isLoading = true);
          try {
            await _courseService.rateCourse(
              widget.courseId,
              _currentUserId,
              rating,
            );
            final updatedCourse = await _courseService.getCourse(
              widget.courseId,
            );
            if (mounted) {
              setState(() {
                _course = updatedCourse;
                _userRating = rating;
                _isLoading = false;
              });
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
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          }
        },
      ),
    );
  }

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
        _userRating = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unenrolled successfully'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Failed: $e');
    } finally {
      setState(() => _isEnrolling = false);
    }
  }

  // --- SNACKBARS ---
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }

  void _showWarningSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.warningColor),
    );
  }

  // --- CONTENT OPENING ---
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Select Content',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.play_circle_fill,
                    color: Colors.red,
                  ),
                  title: const Text('Watch Video'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToVideo(lesson, allLessons);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.description, color: Colors.blue),
                  title: const Text('Read Document'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToDoc(lesson, allLessons);
                  },
                ),
                const SizedBox(height: 20),
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
    setState(() => _completedLessons.add(lessonId));

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

  Future<void> _showEnrollmentSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'Success!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go to My Courses'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
