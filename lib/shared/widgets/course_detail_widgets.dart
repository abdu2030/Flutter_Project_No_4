// lib/shared/widgets/course_detail_widgets.dart
import 'package:eduvox/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Shared App Bar
class CourseDetailAppBar extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final Color accentColor;
  final List<Widget>? actions;

  const CourseDetailAppBar({
    super.key,
    required this.title,
    this.imageUrl,
    this.accentColor = AppTheme.primaryColor,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: accentColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.black26,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: accentColor.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                errorWidget: (_, __, ___) => _buildPlaceholder(accentColor),
              )
            else
              _buildPlaceholder(accentColor),
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
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.play_circle_outline, color: Colors.white38, size: 80),
      ),
    );
  }
}

// Course Stats Row
class CourseStatsRow extends StatelessWidget {
  final double rating;
  final int studentCount;
  final int lessonCount;
  final String duration;
  final bool isDark;

  const CourseStatsRow({
    super.key,
    required this.rating,
    required this.studentCount,
    required this.lessonCount,
    required this.duration,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          _buildStat(Icons.star_rounded, '$rating', 'Rating', AppTheme.warning),
          _buildDivider(),
          _buildStat(
            Icons.people_rounded,
            '$studentCount',
            'Students',
            Colors.blue,
          ),
          _buildDivider(),
          _buildStat(
            Icons.play_lesson_rounded,
            '$lessonCount',
            'Lessons',
            Colors.green,
          ),
          _buildDivider(),
          _buildStat(
            Icons.access_time_rounded,
            duration,
            'Duration',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,

          style: TextStyle(
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
    );
  }
}

// Instructor Info Card
class InstructorInfoCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final String? subtitle;
  final bool isDark;
  final VoidCallback? onTap;

  const InstructorInfoCard({
    super.key,
    required this.name,
    this.imageUrl,
    this.subtitle,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
                backgroundImage: imageUrl != null
                    ? NetworkImage(imageUrl!)
                    : null,
                child: imageUrl == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructor',
                    style: TextStyle(
                      fontSize: 12,

                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

// Section Header
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (actionText != null)
            TextButton(onPressed: onAction, child: Text(actionText!)),
        ],
      ),
    );
  }
}

// Lesson Tile
class LessonTile extends StatelessWidget {
  final int index;
  final String title;
  final String duration;
  final bool isLocked;
  final bool isFree;
  final bool isCompleted;
  final bool showPreviewBadge;
  final VoidCallback onTap;
  final bool isDark;
  final Widget? trailing;

  const LessonTile({
    super.key,
    required this.index,
    required this.title,
    required this.duration,
    this.isLocked = false,
    this.isFree = false,
    this.isCompleted = false,
    this.showPreviewBadge = false,
    required this.onTap,
    required this.isDark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isCompleted
            ? Border.all(
                color: AppTheme.success.withValues(alpha: 0.5),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isLocked
                ? Colors.grey.shade200
                : isCompleted
                ? AppTheme.success.withValues(alpha: 0.1)
                : AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: isLocked
                ? Icon(
                    Icons.lock_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  )
                : isCompleted
                ? const Icon(
                    Icons.check_rounded,
                    color: AppTheme.successColor,
                    size: 22,
                  )
                : Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isLocked ? Colors.grey : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 14,

              color: isLocked
                  ? Colors.grey.shade400
                  : (isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textSecondary),
            ),
            const SizedBox(width: 4),
            Text(
              isLocked ? 'Locked' : '$duration min',
              style: TextStyle(
                fontSize: 12,

                color: isLocked
                    ? Colors.grey.shade400
                    : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary),
              ),
            ),
            if (showPreviewBadge && isFree) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Preview',
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing:
            trailing ??
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isLocked
                    ? Colors.grey.shade100
                    : AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLocked ? Icons.lock_rounded : Icons.play_arrow_rounded,
                color: isLocked ? Colors.grey : AppTheme.primary,
                size: 20,
              ),
            ),
        onTap: onTap,
      ),
    );
  }
}
