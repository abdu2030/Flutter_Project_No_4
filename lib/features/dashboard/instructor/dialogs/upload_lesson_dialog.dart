// lib/features/instructor/dialogs/upload_lesson_dialog.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:eduvox/core/models/lesson_model.dart';
import 'package:eduvox/core/services/course_service.dart';
import 'package:eduvox/core/services/storage_service.dart';

class UploadLessonDialog extends StatefulWidget {
  final String courseId;
  final int currentLessonCount;

  const UploadLessonDialog({
    super.key,
    required this.courseId,
    required this.currentLessonCount,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String courseId,
    required int currentLessonCount,
  }) {
    if (!context.mounted) return Future.value(null);

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UploadLessonDialog(
        courseId: courseId,
        currentLessonCount: currentLessonCount,
      ),
    );
  }

  @override
  State<UploadLessonDialog> createState() => _UploadLessonDialogState();
}

class _UploadLessonDialogState extends State<UploadLessonDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final CourseService _courseService;
  late final StorageService _storageService;

  File? _videoFile;
  String? _videoFileName;
  int? _videoFileSize;

  File? _documentFile;
  String? _documentFileName;
  int? _documentFileSize;

  bool _isFree = false;
  bool _isLoading = false;
  double _uploadProgress = 0;
  String _uploadStatus = '';
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _courseService = CourseService();
    _storageService = StorageService();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _pickVideo() async {
    if (_isLoading) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null &&
          result.files.isNotEmpty &&
          result.files.first.path != null) {
        final file = File(result.files.first.path!);

        if (await file.exists()) {
          _safeSetState(() {
            _videoFile = file;
            _videoFileName = result.files.first.name;
            _videoFileSize = result.files.first.size;
          });
        }
      }
    } catch (e) {
      _showError('Failed to pick video: $e');
    }
  }

  Future<void> _pickDocument() async {
    if (_isLoading) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'ppt',
          'pptx',
          'txt',
          'xls',
          'xlsx',
        ],
        allowMultiple: false,
      );

      if (result != null &&
          result.files.isNotEmpty &&
          result.files.first.path != null) {
        final file = File(result.files.first.path!);

        if (await file.exists()) {
          _safeSetState(() {
            _documentFile = file;
            _documentFileName = result.files.first.name;
            _documentFileSize = result.files.first.size;
          });
        }
      }
    } catch (e) {
      _showError('Failed to pick document: $e');
    }
  }

  void _clearVideo() {
    _safeSetState(() {
      _videoFile = null;
      _videoFileName = null;
      _videoFileSize = null;
    });
  }

  void _clearDocument() {
    _safeSetState(() {
      _documentFile = null;
      _documentFileName = null;
      _documentFileSize = null;
    });
  }

  Future<void> _uploadLesson() async {
    if (!_formKey.currentState!.validate()) return;

    if (_videoFile == null && _documentFile == null) {
      _showError('Please select at least a video or a document');
      return;
    }

    _safeSetState(() {
      _isLoading = true;
      _uploadProgress = 0;
      _uploadStatus = 'Preparing...';
    });

    try {
      String? videoUrl;
      String? documentUrl;

      if (_videoFile != null) {
        if (!await _videoFile!.exists()) {
          throw Exception('Video file no longer exists');
        }

        _safeSetState(() => _uploadStatus = 'Uploading video...');

        videoUrl = await _storageService.uploadVideo(
          file: _videoFile!,
          courseId: widget.courseId,
          onProgress: (progress) {
            _safeSetState(() {
              _uploadProgress = progress * 0.5;
              _uploadStatus = 'Uploading video... ${(progress * 100).toInt()}%';
            });
          },
        );
      }

      if (_documentFile != null) {
        if (!await _documentFile!.exists()) {
          throw Exception('Document file no longer exists');
        }

        _safeSetState(() => _uploadStatus = 'Uploading document...');

        documentUrl = await _storageService.uploadDocument(
          file: _documentFile!,
          courseId: widget.courseId,
          onProgress: (progress) {
            _safeSetState(() {
              final baseProgress = _videoFile != null ? 0.5 : 0;
              final docProgress = _videoFile != null
                  ? progress * 0.5
                  : progress;
              _uploadProgress = baseProgress + docProgress;
              _uploadStatus =
                  'Uploading document... ${(progress * 100).toInt()}%';
            });
          },
        );
      }

      LessonType lessonType;
      if (videoUrl != null && documentUrl != null) {
        lessonType = LessonType.video;
      } else if (videoUrl != null) {
        lessonType = LessonType.video;
      } else {
        lessonType = LessonType.document;
      }

      _safeSetState(() => _uploadStatus = 'Saving lesson...');

      final lesson = LessonModel(
        id: const Uuid().v4(),
        courseId: widget.courseId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        type: lessonType,
        videoUrl: videoUrl,
        documentUrl: documentUrl,
        orderIndex: widget.currentLessonCount,
        isFree: _isFree,
        createdAt: DateTime.now(),
      );

      await _courseService.addLesson(lesson);

      if (mounted && !_isDisposed) {
        Navigator.pop(context, true);
        _showSuccess('Lesson added successfully!');
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _safeSetState(() {
        _isLoading = false;
        _uploadProgress = 0;
        _uploadStatus = '';
      });
    }
  }

  void _showError(String message) {
    if (!mounted || _isDisposed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted || _isDisposed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Get theme colors
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // ✅ Theme-aware colors
    final backgroundColor = colorScheme.surface;
    final cardColor = isDark
        ? colorScheme.surfaceContainerHighest
        : Colors.grey[50];
    final borderColor = isDark ? Colors.grey[700] : Colors.grey[300];
    final textColor = colorScheme.onSurface;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final hintColor = isDark ? Colors.grey[500] : Colors.grey[400];
    final handleColor = isDark ? Colors.grey[600] : Colors.grey[300];

    // ✅ Fixed height - doesn't change with keyboard
    final sheetHeight = MediaQuery.of(context).size.height * 0.9;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: !_isLoading,
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ✅ Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ✅ Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Add New Lesson',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  if (!_isLoading)
                    IconButton(
                      icon: Icon(Icons.close, color: textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
            ),

            Divider(height: 1, color: borderColor),

            // ✅ Scrollable Content with keyboard padding
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ═══════════════════════════════════════════
                      // VIDEO PICKER
                      // ═══════════════════════════════════════════
                      _buildSectionTitle(
                        'Video',
                        Icons.videocam,
                        Colors.red,
                        optional: true,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildFilePicker(
                        file: _videoFile,
                        fileName: _videoFileName,
                        fileSize: _videoFileSize,
                        onPick: _pickVideo,
                        onClear: _clearVideo,
                        icon: Icons.video_library,
                        color: Colors.red,
                        placeholder: 'Tap to select video',
                        hint: 'MP4, MOV, AVI (max 100MB)',
                        isDark: isDark,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        hintColor: hintColor,
                      ),
                      const SizedBox(height: 20),

                      // ═══════════════════════════════════════════
                      // DOCUMENT PICKER
                      // ═══════════════════════════════════════════
                      _buildSectionTitle(
                        'Document / Notes',
                        Icons.description,
                        Colors.blue,
                        optional: true,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildFilePicker(
                        file: _documentFile,
                        fileName: _documentFileName,
                        fileSize: _documentFileSize,
                        onPick: _pickDocument,
                        onClear: _clearDocument,
                        icon: Icons.upload_file,
                        color: Colors.blue,
                        placeholder: 'Tap to select document',
                        hint: 'PDF, DOC, PPT, XLS (max 10MB)',
                        isDark: isDark,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        hintColor: hintColor,
                      ),
                      const SizedBox(height: 8),

                      // ✅ Info hint
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.amber.shade900.withOpacity(0.3)
                              : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? Colors.amber.shade700
                                : Colors.amber.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: isDark
                                  ? Colors.amber.shade300
                                  : Colors.amber.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You can upload a video, a document, or both!',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.amber.shade200
                                      : Colors.amber.shade800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ═══════════════════════════════════════════
                      // TITLE FIELD
                      // ═══════════════════════════════════════════
                      TextFormField(
                        controller: _titleController,
                        enabled: !_isLoading,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(color: textColor),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a lesson title';
                          }
                          return null;
                        },
                        decoration: _buildInputDecoration(
                          labelText: 'Lesson Title *',
                          hintText: 'e.g., Introduction to Flutter',
                          prefixIcon: Icons.title,
                          isDark: isDark,
                          colorScheme: colorScheme,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ═══════════════════════════════════════════
                      // DESCRIPTION FIELD
                      // ═══════════════════════════════════════════
                      TextFormField(
                        controller: _descriptionController,
                        enabled: !_isLoading,
                        maxLines: 2,
                        style: TextStyle(color: textColor),
                        decoration: _buildInputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Brief description of this lesson',
                          prefixIcon: Icons.notes,
                          isDark: isDark,
                          colorScheme: colorScheme,
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ═══════════════════════════════════════════
                      // FREE PREVIEW TOGGLE
                      // ═══════════════════════════════════════════
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor!),
                        ),
                        child: SwitchListTile(
                          title: Text(
                            'Free Preview',
                            style: TextStyle(color: textColor),
                          ),
                          subtitle: Text(
                            'Allow non-enrolled students to view',
                            style: TextStyle(
                              fontSize: 12,
                              color: subtitleColor,
                            ),
                          ),
                          value: _isFree,
                          onChanged: _isLoading
                              ? null
                              : (value) => _safeSetState(() => _isFree = value),
                          activeThumbColor: Colors.green,
                          activeTrackColor: Colors.green.withOpacity(0.5),
                          inactiveThumbColor: isDark ? Colors.grey[400] : null,
                          inactiveTrackColor: isDark ? Colors.grey[700] : null,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ═══════════════════════════════════════════
                      // UPLOAD PROGRESS
                      // ═══════════════════════════════════════════
                      if (_isLoading) ...[
                        Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _uploadProgress > 0
                                    ? _uploadProgress
                                    : null,
                                backgroundColor: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation(
                                  colorScheme.primary,
                                ),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _uploadStatus,
                              style: TextStyle(color: subtitleColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ═══════════════════════════════════════════
                      // UPLOAD BUTTON
                      // ═══════════════════════════════════════════
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _uploadLesson,
                          icon: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : Icon(
                                  Icons.cloud_upload,
                                  color: colorScheme.onPrimary,
                                ),
                          label: Text(
                            _isLoading ? 'Uploading...' : 'Upload Lesson',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            disabledBackgroundColor: colorScheme.primary
                                .withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPER: Input Decoration
  // ═══════════════════════════════════════════════════════════
  InputDecoration _buildInputDecoration({
    required String labelText,
    String? hintText,
    required IconData prefixIcon,
    required bool isDark,
    required ColorScheme colorScheme,
    bool alignLabelWithHint = false,
  }) {
    final borderColor = isDark ? Colors.grey[700] : Colors.grey[300];
    final fillColor = isDark
        ? colorScheme.surfaceContainerHighest
        : Colors.grey[50];

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: Padding(
        padding: alignLabelWithHint
            ? const EdgeInsets.only(bottom: 25)
            : EdgeInsets.zero,
        child: Icon(prefixIcon, color: colorScheme.primary),
      ),
      filled: true,
      fillColor: fillColor,
      labelStyle: TextStyle(
        color: isDark ? Colors.grey[400] : Colors.grey[600],
      ),
      hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPER: Section Title
  // ═══════════════════════════════════════════════════════════
  Widget _buildSectionTitle(
    String title,
    IconData icon,
    Color color, {
    bool optional = false,
    required Color textColor,
    required Color? subtitleColor,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: textColor,
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Optional',
              style: TextStyle(fontSize: 10, color: subtitleColor),
            ),
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPER: File Picker Card
  // ═══════════════════════════════════════════════════════════
  Widget _buildFilePicker({
    required File? file,
    required String? fileName,
    required int? fileSize,
    required VoidCallback onPick,
    required VoidCallback onClear,
    required IconData icon,
    required Color color,
    required String placeholder,
    required String hint,
    required bool isDark,
    required Color? cardColor,
    required Color? borderColor,
    required Color textColor,
    required Color? subtitleColor,
    required Color? hintColor,
  }) {
    final hasFile = file != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : onPick,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasFile
                ? (isDark ? color.withOpacity(0.15) : color.withOpacity(0.05))
                : cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasFile ? color : borderColor!,
              width: hasFile ? 2 : 1,
            ),
          ),
          child: hasFile
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon == Icons.video_library
                            ? Icons.videocam
                            : Icons.description,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName ?? 'Unknown file',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (fileSize != null)
                            Text(
                              _formatFileSize(fileSize),
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!_isLoading)
                      IconButton(
                        icon: Icon(Icons.close, color: subtitleColor),
                        onPressed: onClear,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            placeholder,
                            style: TextStyle(color: subtitleColor),
                          ),
                          Text(
                            hint,
                            style: TextStyle(color: hintColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.add_circle_outline,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
