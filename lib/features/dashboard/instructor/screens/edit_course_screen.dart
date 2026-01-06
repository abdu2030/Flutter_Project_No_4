// lib/features/instructor/screens/edit_course_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eduvox/core/models/course_model.dart';
import 'package:eduvox/core/services/course_service.dart';
import 'package:eduvox/core/services/storage_service.dart';

class EditCourseScreen extends StatefulWidget {
  final CourseModel course;

  const EditCourseScreen({super.key, required this.course});

  @override
  State<EditCourseScreen> createState() => _EditCourseScreenState();
}

class _EditCourseScreenState extends State<EditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;

  final CourseService _courseService = CourseService();
  final StorageService _storageService = StorageService();

  late String _selectedCategory;
  File? _newThumbnailFile;
  bool _isLoading = false;

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
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.course.title);
    _descriptionController = TextEditingController(
      text: widget.course.description,
    );
    _priceController = TextEditingController(
      text: widget.course.price.toString(),
    );
    _selectedCategory = widget.course.category;
  }

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
          _newThumbnailFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? thumbnailUrl = widget.course.thumbnailUrl;

      // Upload new thumbnail if selected
      if (_newThumbnailFile != null) {
        // Delete old thumbnail
        if (widget.course.thumbnailUrl != null) {
          await _storageService.deleteFile(widget.course.thumbnailUrl!);
        }

        // Upload new one
        thumbnailUrl = await _storageService.uploadThumbnail(
          file: _newThumbnailFile!,
          courseId: widget.course.id,
        );
      }

      final updatedCourse = widget.course.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        price: double.tryParse(_priceController.text) ?? 0,
        thumbnailUrl: thumbnailUrl,
      );

      await _courseService.updateCourse(updatedCourse);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, updatedCourse);
      }
    } catch (e) {
      _showError('Failed to update: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Course'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              const Text(
                'Course Thumbnail',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _isLoading ? null : _pickThumbnail,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _newThumbnailFile != null
                        ? Image.file(_newThumbnailFile!, fit: BoxFit.cover)
                        : widget.course.thumbnailUrl != null
                        ? CachedNetworkImage(
                            imageUrl: widget.course.thumbnailUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to change thumbnail',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              if (_newThumbnailFile != null ||
                  widget.course.thumbnailUrl != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() => _newThumbnailFile = null);
                    },
                    child: const Text('Reset'),
                  ),
                ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                enabled: !_isLoading,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a course title';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Course Title',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                enabled: !_isLoading,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.description),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() => _selectedCategory = value!);
                      },
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                enabled: !_isLoading,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price (0 for free)',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
