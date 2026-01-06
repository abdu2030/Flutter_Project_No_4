// lib/features/instructor/dialogs/publish_dialog.dart

import 'package:flutter/material.dart';
import 'package:eduvox/core/models/course_model.dart';

class PublishDialog extends StatelessWidget {
  final CourseModel course;

  const PublishDialog({super.key, required this.course});

  /// Show publish/unpublish confirmation dialog
  static Future<bool?> show(BuildContext context, CourseModel course) {
    return showDialog<bool>(
      context: context,
      builder: (context) => PublishDialog(course: course),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPublishing = !course.isPublished;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPublishing
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPublishing ? Icons.public : Icons.public_off,
              color: isPublishing ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Text(isPublishing ? 'Publish Course' : 'Unpublish Course'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPublishing
                ? 'Are you sure you want to publish "${course.title}"?'
                : 'Are you sure you want to unpublish "${course.title}"?',
          ),
          const SizedBox(height: 16),
          if (isPublishing) ...[
            _buildCheckItem(
              Icons.check_circle,
              '${course.totalLessons} lessons ready',
              course.totalLessons > 0,
            ),
            _buildCheckItem(
              Icons.check_circle,
              'Course thumbnail added',
              course.thumbnailUrl != null,
            ),
            _buildCheckItem(
              Icons.check_circle,
              'Description provided',
              course.description.isNotEmpty,
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Students will no longer be able to see this course in browse.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: isPublishing ? Colors.green : Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: Text(isPublishing ? 'Publish' : 'Unpublish'),
        ),
      ],
    );
  }

  Widget _buildCheckItem(IconData icon, String text, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isComplete ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isComplete ? Colors.black87 : Colors.grey,
              decoration: isComplete ? null : TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }
}