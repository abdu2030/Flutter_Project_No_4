// lib/features/dashboard/student/pages/edit_profile_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart'; // ☁️ Cloudinary Import
import 'package:eduvox/shared/theme/app_theme.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  File? _imageFile;
  bool _isLoading = false;

  // ☁️ Cloudinary Configuration
  final cloudinary = CloudinaryPublic(
    'dljqnuaep',
    'eduvox_uploads',
    cache: false,
  );

  @override
  void initState() {
    super.initState();
    _nameController.text = _currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      String? photoUrl = _currentUser.photoURL;

      // Upload Image to Cloudinary (if selected)
      if (_imageFile != null) {
        try {
          CloudinaryResponse response = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(
              _imageFile!.path,
              resourceType: CloudinaryResourceType.Image,
              folder: 'user_profiles',
            ), // Optional: organize in folder
          );
          photoUrl = response.secureUrl;
        } catch (e) {
          throw Exception('Image upload failed: $e');
        }
      }

      // 2. Update Firebase Auth (Display Name & Photo URL)
      await _currentUser.updateDisplayName(_nameController.text.trim());
      if (photoUrl != null) {
        await _currentUser.updatePhotoURL(photoUrl);
      }

      // 3. Update Firestore User Document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .update({'name': _nameController.text.trim(), 'photoUrl': photoUrl});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 🖼️ Image Avatar
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (_currentUser?.photoURL != null
                                      ? NetworkImage(_currentUser!.photoURL!)
                                      : null)
                                  as ImageProvider?,
                        child:
                            (_imageFile == null &&
                                _currentUser?.photoURL == null)
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: isDark ? AppTheme.darkSurface : Colors.white,
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: _currentUser?.email,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: isDark
                      ? AppTheme.darkSurface
                      : Colors.grey.shade100,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 💾 Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
