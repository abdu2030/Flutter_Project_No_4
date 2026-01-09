// lib/features/instructor/pages/instructor_edit_profile_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduvox/core/models/user_model.dart';
import 'package:eduvox/core/services/auth_service.dart';
import 'package:eduvox/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

class InstructorEditProfilePage extends StatefulWidget {
  final UserModel? user;
  const InstructorEditProfilePage({super.key, this.user});

  @override
  State<InstructorEditProfilePage> createState() =>
      _InstructorEditProfilePageState();
}

class _InstructorEditProfilePageState extends State<InstructorEditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  // Social Controllers
  late TextEditingController _websiteController;
  late TextEditingController _linkedinController;
  late TextEditingController _twitterController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');

    _phoneController = TextEditingController(text: widget.user?.phone ?? '');

    final socials = widget.user?.socials ?? {};
    _websiteController = TextEditingController(text: socials['website'] ?? '');
    _linkedinController = TextEditingController(
      text: socials['linkedin'] ?? '',
    );
    _twitterController = TextEditingController(text: socials['twitter'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _linkedinController.dispose();
    _twitterController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final uid = AuthService().currentUser?.uid;
      if (uid != null) {
        // Update Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'socials': {
            'website': _websiteController.text.trim(),
            'linkedin': _linkedinController.text.trim(),
            'twitter': _twitterController.text.trim(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(
            context,
            true,
          ); // Return true to trigger refresh in parent
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Image upload coming soon'),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        backgroundImage: widget.user?.profileImage != null
                            ? NetworkImage(widget.user!.profileImage!)
                            : null,
                        child: widget.user?.profileImage == null
                            ? const Icon(
                                Icons.camera_alt,
                                size: 30,
                                color: AppTheme.primaryColor,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to change photo',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              Text(
                'Personal Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) => val!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),

              const SizedBox(height: 30),

              Text(
                'Social Links',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _websiteController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Website / Portfolio',
                  prefixIcon: Icon(Icons.language),
                  hintText: 'https://yourwebsite.com',
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _linkedinController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'LinkedIn Profile',
                  prefixIcon: Icon(
                    Icons.link,
                  ), // Or use a custom LinkedIn icon asset
                  hintText: 'https://linkedin.com/in/username',
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _twitterController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Twitter / X Profile',
                  prefixIcon: Icon(Icons.alternate_email),
                  hintText: 'https://x.com/username',
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
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
    );
  }
}
