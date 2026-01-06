// lib/features/instructor/dialogs/create_course_dialog.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:eduvox/core/models/course_model.dart';
import 'package:eduvox/core/services/course_service.dart';
import 'package:eduvox/core/services/storage_service.dart';
import 'package:eduvox/core/services/auth_service.dart';

class CreateCourseDialog extends StatefulWidget {
  const CreateCourseDialog({super.key});

  static Future<CourseModel?> show(BuildContext context) {
    return showModalBottomSheet<CourseModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateCourseDialog(),
    );
  }

  @override
  State<CreateCourseDialog> createState() => _CreateCourseDialogState();
}

class _CreateCourseDialogState extends State<CreateCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '0');

  final CourseService _courseService = CourseService();
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();

  String _selectedCategory = 'Programming';
  File? _thumbnailFile;
  bool _isLoading = false;
  String _loadingStatus = '';

  final List<String> _categories = [
    'Programming',
    'Design',
    'Business',
    'Marketing',
    'Music',
    'Photography',
    'Health & Fitness',
    'Language',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _thumbnailFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _createCourse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _loadingStatus = 'Preparing...';
    });

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('Not logged in');

      final courseId = const Uuid().v4();
      String? thumbnailUrl;

      if (_thumbnailFile != null) {
        setState(() => _loadingStatus = 'Uploading thumbnail...');
        thumbnailUrl = await _storageService.uploadThumbnail(
          file: _thumbnailFile!,
          courseId: courseId,
        );
      }

      setState(() => _loadingStatus = 'Creating course...');

      final userData = await _authService.getUserData(user.uid);

      final course = CourseModel(
        id: courseId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        instructorId: user.uid,
        instructorName: userData?.name ?? user.email ?? 'Instructor',
        thumbnailUrl: thumbnailUrl,
        category: _selectedCategory,
        price: double.tryParse(_priceController.text) ?? 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPublished: false,
      );

      await _courseService.createCourse(course);

      if (mounted) {
        Navigator.pop(context, course);
        _showSuccess('Course created successfully!');
      }
    } catch (e) {
      _showError('Failed to create course: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingStatus = '';
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final sheetHeight = MediaQuery.of(context).size.height * 0.9;

    // ✅ Get theme colors for consistent dark/light mode
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // ✅ Define consistent colors based on theme
    final backgroundColor = colorScheme.surface;
    final cardColor = isDark ? colorScheme.surfaceContainerHighest : Colors.grey[100];
    final borderColor = isDark ? Colors.grey[700] : Colors.grey[300];
    final textColor = colorScheme.onSurface;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final hintColor = isDark ? Colors.grey[500] : Colors.grey[400];
    final iconColor = isDark ? Colors.grey[400] : Colors.grey[400];
    final handleColor = isDark ? Colors.grey[600] : Colors.grey[300];

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: backgroundColor, // ✅ Theme-aware background
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'Create New Course',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor, // ✅ Theme-aware text
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

            Divider(
              height: 1,
              color: borderColor, // ✅ Theme-aware divider
            ),

            // ✅ Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Thumbnail Picker
                      InkWell(
                        onTap: _isLoading ? null : _pickThumbnail,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: cardColor, // ✅ Theme-aware card
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor!),
                            image: _thumbnailFile != null
                                ? DecorationImage(
                                    image: FileImage(_thumbnailFile!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _thumbnailFile == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 40,
                                      color: iconColor,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add Thumbnail',
                                      style: TextStyle(color: subtitleColor),
                                    ),
                                    Text(
                                      '(Optional)',
                                      style: TextStyle(
                                        color: hintColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                              : Align(
                                  alignment: Alignment.topRight,
                                  child: Container(
                                    margin: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: backgroundColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        size: 20,
                                        color: textColor,
                                      ),
                                      onPressed: () {
                                        setState(() => _thumbnailFile = null);
                                      },
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ✅ Title Field
                      TextFormField(
                        controller: _titleController,
                        enabled: !_isLoading,
                        style: TextStyle(color: textColor),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a course title';
                          }
                          if (value.length < 5) {
                            return 'Title must be at least 5 characters';
                          }
                          return null;
                        },
                        decoration: _buildInputDecoration(
                          labelText: 'Course Title *',
                          hintText: 'e.g., Complete Flutter Development',
                          prefixIcon: Icons.title,
                          isDark: isDark,
                          colorScheme: colorScheme,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ✅ Description Field
                      TextFormField(
                        controller: _descriptionController,
                        enabled: !_isLoading,
                        maxLines: 3,
                        style: TextStyle(color: textColor),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          if (value.length < 20) {
                            return 'Description must be at least 20 characters';
                          }
                          return null;
                        },
                        decoration: _buildInputDecoration(
                          labelText: 'Description *',
                          hintText: 'What will students learn in this course?',
                          prefixIcon: Icons.description,
                          isDark: isDark,
                          colorScheme: colorScheme,
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ✅ Category & Price Row
                      Row(
                        children: [
                          // Category Dropdown
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedCategory,
                              dropdownColor: backgroundColor,
                              style: TextStyle(color: textColor),
                              decoration: _buildInputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icons.category,
                                isDark: isDark,
                                colorScheme: colorScheme,
                              ),
                              items: _categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(
                                    category,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: textColor),
                                  ),
                                );
                              }).toList(),
                              onChanged: _isLoading
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(
                                          () => _selectedCategory = value,
                                        );
                                      }
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Price Field
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              enabled: !_isLoading,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: textColor),
                              decoration: _buildInputDecoration(
                                labelText: 'Price',
                                prefixIcon: Icons.attach_money,
                                isDark: isDark,
                                colorScheme: colorScheme,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Set price to 0 for a free course',
                        style: TextStyle(color: hintColor, fontSize: 12),
                      ),
                      const SizedBox(height: 24),

                      // ✅ Create Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createCourse,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            disabledBackgroundColor: colorScheme.primary
                                .withOpacity(0.6),
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _loadingStatus,
                                      style: TextStyle(
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Create Course',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
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

  // ✅ Helper method for consistent input decoration
  InputDecoration _buildInputDecoration({
    required String labelText,
    String? hintText,
    required IconData prefixIcon,
    required bool isDark,
    required ColorScheme colorScheme,
    bool alignLabelWithHint = false,
  }) {
    final borderColor = isDark ? Colors.grey[700] : Colors.grey[300];
    final fillColor = isDark ? colorScheme.surfaceContainerHighest : Colors.grey[50];

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: Padding(
        padding: alignLabelWithHint
            ? const EdgeInsets.only(bottom: 50)
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
}
