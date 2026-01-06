// lib/features/dashboard/instructor/pages/course_detail_screen.dart
import 'package:eduvox/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eduvox/core/models/course_model.dart';
import 'package:eduvox/core/models/lesson_model.dart';
import 'package:eduvox/core/services/course_service.dart';
import 'package:eduvox/core/services/storage_service.dart';
import 'package:eduvox/shared/screens/document_viewer_screen.dart';
import 'package:eduvox/shared/screens/video_player_screen.dart';
import '../dialogs/upload_lesson_dialog.dart';
import '../dialogs/delete_confirm_dialog.dart';
import '../dialogs/publish_dialog.dart';
import 'edit_course_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final CourseModel course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final CourseService _courseService = CourseService();
  final StorageService _storageService = StorageService();

  late CourseModel _course;
  List<LessonModel> _lessons = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _refreshCourse();
  }

  Future<void> _refreshCourse() async {
    final updated = await _courseService.getCourse(_course.id);
    if (updated != null && mounted) {
      setState(() => _course = updated);
    }
  }

  Future<void> _togglePublish() async {
    final confirm = await PublishDialog.show(context, _course);

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        await _courseService.togglePublish(_course.id, !_course.isPublished);
        await _refreshCourse();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    _course.isPublished ? Icons.public : Icons.public_off,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _course.isPublished
                        ? 'Course published successfully!'
                        : 'Course unpublished',
                  ),
                ],
              ),
              backgroundColor: _course.isPublished
                  ? AppTheme.success
                  : Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        _showError('Failed to update: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addLesson() async {
    final result = await UploadLessonDialog.show(
      context,
      courseId: _course.id,
      currentLessonCount: _course.totalLessons,
    );

    if (result == true) {
      await _refreshCourse();
    }
  }

  Future<void> _deleteLesson(LessonModel lesson) async {
    final confirm = await DeleteConfirmDialog.show(
      context,
      title: 'Delete Lesson',
      message:
          'Are you sure you want to delete "${lesson.title}"?\n\nThis will also delete the uploaded file and cannot be undone.',
      deleteButtonText: 'Delete Lesson',
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        if (lesson.videoUrl != null) {
          await _storageService.deleteFile(lesson.videoUrl!);
        }
        if (lesson.documentUrl != null) {
          await _storageService.deleteFile(lesson.documentUrl!);
        }

        await _courseService.deleteLesson(_course.id, lesson.id);
        await _refreshCourse();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Lesson deleted'),
                ],
              ),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        _showError('Failed to delete: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteCourse() async {
    final confirm = await DeleteConfirmDialog.show(
      context,
      title: 'Delete Course',
      message:
          'Are you sure you want to delete "${_course.title}"?\n\nThis will delete all lessons and files. This action cannot be undone.',
      deleteButtonText: 'Delete Course',
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        final lessons = await _courseService.getCourseLessonsOnce(_course.id);

        for (var lesson in lessons) {
          if (lesson.videoUrl != null) {
            await _storageService.deleteFile(lesson.videoUrl!);
          }
          if (lesson.documentUrl != null) {
            await _storageService.deleteFile(lesson.documentUrl!);
          }
        }

        if (_course.thumbnailUrl != null) {
          await _storageService.deleteFile(_course.thumbnailUrl!);
        }

        await _courseService.deleteCourse(_course.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Course deleted'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        _showError('Failed to delete: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _editCourse() async {
    final updatedCourse = await Navigator.push<CourseModel>(
      context,
      MaterialPageRoute(
        builder: (context) => EditCourseScreen(course: _course),
      ),
    );

    if (updatedCourse != null) {
      setState(() => _course = updatedCourse);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : AppTheme.lightBackground,
      resizeToAvoidBottomInset: true,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.secondary),
                  const SizedBox(height: 16),
                  Text(
                    'Please wait...',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(isDark),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Publish Status Card
                      _buildPublishStatusCard(isDark),
                      const SizedBox(height: 20),

                      // Quick Stats (Earnings)
                      _buildQuickStats(isDark),
                      const SizedBox(height: 20),

                      // Course Stats Row
                      _buildStatsSection(isDark),
                      const SizedBox(height: 24),

                      // Description Section
                      _buildDescriptionSection(isDark),
                      const SizedBox(height: 24),

                      // Enrolled Students
                      _buildEnrolledStudentsSection(isDark),
                      const SizedBox(height: 24),

                      // Action Buttons
                      _buildActionButtons(isDark),
                      const SizedBox(height: 24),

                      // Lessons Header
                      _buildLessonsHeader(isDark),
                      const SizedBox(height: 12),
                    ]),
                  ),
                ),

                // Lessons List
                _buildLessonsList(isDark),

                // Bottom Padding
                SliverToBoxAdapter(
                  child: SizedBox(height: 100 + bottomPadding),
                ),
              ],
            ),
      floatingActionButton: _buildFAB(),
      bottomSheet: _buildBottomBar(isDark),
    );
  }

  // ==================== APP BAR ====================
  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppTheme.secondary,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black26,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Edit Button
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: _editCourse,
          tooltip: 'Edit Course',
        ),
        // More Options
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            switch (value) {
              case 'delete':
                _deleteCourse();
                break;
              case 'share':
                // TODO: Share course
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share_rounded),
                  SizedBox(width: 12),
                  Text('Share'),
                ],
              ),
            ),

            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, color: AppTheme.error),
                  const SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: AppTheme.error)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _course.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            if (_course.thumbnailUrl != null)
              CachedNetworkImage(
                imageUrl: _course.thumbnailUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.secondary.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                errorWidget: (context, url, error) =>
                    _buildThumbnailPlaceholder(),
              )
            else
              _buildThumbnailPlaceholder(),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),

            // Status Badge
            Positioned(
              top: 90,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _course.isPublished ? AppTheme.success : Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_course.isPublished
                                  ? AppTheme.success
                                  : Colors.orange)
                              .withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _course.isPublished
                          ? Icons.public
                          : Icons.edit_note_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _course.isPublished ? 'Published' : 'Draft',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Price Badge
            Positioned(
              top: 90,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _course.price > 0
                      ? '\$${_course.price.toStringAsFixed(0)}'
                      : 'FREE',
                  style: TextStyle(
                    color: _course.price > 0
                        ? AppTheme.secondary
                        : AppTheme.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.secondary,
            AppTheme.secondary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.school_rounded, size: 64, color: Colors.white38),
      ),
    );
  }

  // ==================== PUBLISH STATUS CARD ====================
  Widget _buildPublishStatusCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _course.isPublished
              ? [AppTheme.success, AppTheme.success.withValues(alpha: 0.7)]
              : [Colors.orange, Colors.orange.shade300],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (_course.isPublished ? AppTheme.success : Colors.orange)
                .withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _course.isPublished ? Icons.public : Icons.visibility_off,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _course.isPublished ? 'Live & Published' : 'Draft Mode',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _course.isPublished
                      ? 'Students can discover and enroll in your course'
                      : 'Your course is not visible to students yet',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _course.isPublished,
            onChanged: (_) => _togglePublish(),
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.white.withValues(alpha: 0.4),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  // ==================== QUICK STATS (EARNINGS) ====================
  Widget _buildQuickStats(bool isDark) {
    final earnings = _course.enrolledStudents.length * _course.price;

    return Row(
      children: [
        _buildQuickStatCard(
          'Total Earnings',
          '\$${earnings.toStringAsFixed(0)}',
          Icons.attach_money_rounded,
          Colors.green,
          isDark,
        ),
        const SizedBox(width: 12),
        _buildQuickStatCard(
          'This Month',
          '+\$${(earnings * 0.3).toStringAsFixed(0)}',
          Icons.trending_up_rounded,
          Colors.blue,
          isDark,
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== STATS SECTION ====================
  Widget _buildStatsSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.play_lesson_rounded,
            '${_course.totalLessons}',
            'Lessons',
            AppTheme.secondary,
          ),
          _buildDivider(isDark),
          _buildStatItem(
            Icons.access_time_rounded,
            '${_course.totalDuration}',
            'Minutes',
            Colors.blue,
          ),
          _buildDivider(isDark),
          _buildStatItem(
            Icons.people_rounded,
            '${_course.enrolledStudents.length}',
            'Students',
            Colors.green,
          ),
          _buildDivider(isDark),
          _buildStatItem(Icons.star_rounded, '4.8', 'Rating', AppTheme.warning),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 45,
      width: 1,
      color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
    );
  }

  // ==================== DESCRIPTION SECTION ====================
  Widget _buildDescriptionSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About This Course',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _course.category,
                  style: TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _course.description,
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== ENROLLED STUDENTS SECTION ====================
  Widget _buildEnrolledStudentsSection(bool isDark) {
    final studentCount = _course.enrolledStudents.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Enrolled Students',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (studentCount > 0)
              TextButton(
                onPressed: () {
                  // Navigate to students list
                },
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
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
          child: studentCount == 0
              ? Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No students enrolled yet',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white54
                              : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Publish your course to start getting students',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    // Stacked avatars
                    SizedBox(
                      width: 90,
                      height: 40,
                      child: Stack(
                        children: List.generate(
                          studentCount.clamp(0, 4),
                          (index) => Positioned(
                            left: index * 20.0,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? AppTheme.darkSurface
                                      : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: [
                                  Colors.blue,
                                  Colors.green,
                                  Colors.orange,
                                  Colors.purple,
                                ][index % 4],
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (studentCount > 4)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+${studentCount - 4}',
                          style: TextStyle(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$studentCount students enrolled',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'View student progress and analytics',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white54
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: isDark ? Colors.white38 : Colors.grey,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ==================== ACTION BUTTONS ====================
  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: _course.isPublished ? Icons.public_off : Icons.public,
            label: _course.isPublished ? 'Unpublish' : 'Publish',
            color: _course.isPublished ? Colors.orange : AppTheme.success,
            onTap: _togglePublish,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.visibility_rounded,
            label: 'Preview',
            color: Colors.blue,
            onTap: () {
              // Preview as student
            },
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.analytics_rounded,
            label: 'Analytics',
            color: AppTheme.secondary,
            onTap: () {
              // View analytics
            },
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== LESSONS HEADER ====================
  Widget _buildLessonsHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Course Content',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_lessons.length} lessons • ${_course.totalDuration} min total',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        if (_course.totalLessons > 1)
          TextButton.icon(
            onPressed: () {
              // TODO: Reorder lessons
            },
            icon: const Icon(Icons.reorder_rounded, size: 18),
            label: const Text('Reorder'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.secondary),
          ),
      ],
    );
  }

  // ==================== LESSONS LIST ====================
  Widget _buildLessonsList(bool isDark) {
    return StreamBuilder<List<LessonModel>>(
      stream: _courseService.getCourseLessons(_course.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppTheme.secondary),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyLessons(isDark));
        }

        _lessons = snapshot.data!;

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _buildLessonTile(_lessons[index], index, isDark),
              childCount: _lessons.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyLessons(bool isDark) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.video_library_outlined,
              size: 48,
              color: AppTheme.secondary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No lessons yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first lesson to start building your course',
            style: TextStyle(
              color: isDark ? Colors.white54 : AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addLesson,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add First Lesson'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonTile(LessonModel lesson, int index, bool isDark) {
    final hasVideo = lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty;
    final hasDoc = lesson.documentUrl != null && lesson.documentUrl!.isNotEmpty;
    final hasBoth = hasVideo && hasDoc;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            gradient: LinearGradient(
              colors: hasVideo
                  ? [Colors.red, Colors.red.shade300]
                  : [Colors.blue, Colors.blue.shade300],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                hasVideo ? Icons.play_arrow_rounded : Icons.description_rounded,
                color: Colors.white,
                size: 26,
              ),
              if (hasBoth)
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
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          maxLines: 1,
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
                'Lesson ${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              if (hasVideo) _buildContentBadge('Video', Colors.red),
              if (hasDoc) ...[
                const SizedBox(width: 6),
                _buildContentBadge('Doc', Colors.blue),
              ],
              if (lesson.isFree) ...[
                const SizedBox(width: 6),
                _buildContentBadge('Free', AppTheme.success),
              ],
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert_rounded,
            color: isDark ? Colors.white54 : Colors.grey,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            switch (value) {
              case 'preview':
                _openLesson(lesson);
                break;
              case 'toggle_free':
                _toggleLessonFree(lesson);
                break;
              case 'delete':
                _deleteLesson(lesson);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'preview',
              child: Row(
                children: [
                  Icon(Icons.visibility_rounded),
                  SizedBox(width: 12),
                  Text('Preview'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_free',
              child: Row(
                children: [
                  Icon(
                    lesson.isFree
                        ? Icons.lock_rounded
                        : Icons.lock_open_rounded,
                  ),
                  const SizedBox(width: 12),
                  Text(lesson.isFree ? 'Make Paid' : 'Make Free'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, color: AppTheme.error),
                  const SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: AppTheme.error)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _openLesson(lesson),
      ),
    );
  }

  Widget _buildContentBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
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

  // ==================== FAB ====================
  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _addLesson,
      backgroundColor: AppTheme.secondary,
      elevation: 4,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text(
        'Add Lesson',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ==================== BOTTOM BAR ====================
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
            // Edit Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _editCourse,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit Details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.secondary,
                  side: BorderSide(color: AppTheme.secondary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Publish Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _togglePublish,
                icon: Icon(
                  _course.isPublished ? Icons.public_off : Icons.public,
                ),
                label: Text(_course.isPublished ? 'Unpublish' : 'Publish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _course.isPublished
                      ? Colors.orange
                      : AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPER METHODS ====================
  void _showContentOptions(LessonModel lesson) {
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
                    'Select Content to Preview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.play_circle_fill,
                      color: Colors.red,
                    ),
                  ),
                  title: const Text('Watch Video'),
                  subtitle: const Text('Play the video lesson'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToVideo(lesson);
                  },
                ),
                const Divider(height: 1, indent: 70),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.description, color: Colors.blue),
                  ),
                  title: const Text('Read Document'),
                  subtitle: const Text('View attached materials'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToDoc(lesson);
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

  void _openLesson(LessonModel lesson) {
    final hasVideo = lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty;
    final hasDoc = lesson.documentUrl != null && lesson.documentUrl!.isNotEmpty;

    if (hasVideo && hasDoc) {
      _showContentOptions(lesson);
    } else if (hasVideo) {
      _navigateToVideo(lesson);
    } else if (hasDoc) {
      _navigateToDoc(lesson);
    }
  }

  void _navigateToVideo(LessonModel lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(videoUrl: lesson.videoUrl!),
      ),
    );
  }

  void _navigateToDoc(LessonModel lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentViewerScreen(
          documentUrl: lesson.documentUrl!,
          title: lesson.title,
        ),
      ),
    );
  }

  Future<void> _toggleLessonFree(LessonModel lesson) async {
    try {
      final updatedLesson = LessonModel(
        id: lesson.id,
        courseId: lesson.courseId,
        title: lesson.title,
        description: lesson.description,
        type: lesson.type,
        videoUrl: lesson.videoUrl,
        documentUrl: lesson.documentUrl,
        thumbnailUrl: lesson.thumbnailUrl,
        duration: lesson.duration,
        orderIndex: lesson.orderIndex,
        isFree: !lesson.isFree,
        createdAt: lesson.createdAt,
      );

      await _courseService.updateLesson(updatedLesson);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  updatedLesson.isFree ? Icons.lock_open : Icons.lock,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  updatedLesson.isFree
                      ? 'Lesson is now free to preview'
                      : 'Lesson is now paid only',
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to update: $e');
    }
  }
}
