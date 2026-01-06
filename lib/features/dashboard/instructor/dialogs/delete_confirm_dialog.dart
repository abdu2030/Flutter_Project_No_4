// lib/features/instructor/dialogs/delete_confirm_dialog.dart

import 'package:flutter/material.dart';

class DeleteConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String deleteButtonText;
  final VoidCallback? onDelete;

  const DeleteConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.deleteButtonText = 'Delete',
    this.onDelete,
  });

  /// Show delete confirmation dialog
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String deleteButtonText = 'Delete',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmDialog(
        title: title,
        message: message,
        deleteButtonText: deleteButtonText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete_outline, color: Colors.red),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(deleteButtonText),
        ),
      ],
    );
  }
}
