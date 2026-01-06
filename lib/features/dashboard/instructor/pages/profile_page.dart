// lib/features/instructor/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:eduvox/core/models/user_model.dart';
import 'package:eduvox/core/models/course_model.dart';
import 'package:eduvox/core/services/auth_service.dart';
import 'package:eduvox/core/services/course_service.dart';
import 'package:eduvox/features/auth/login_page.dart';

class InstructorProfilePage extends StatefulWidget {
  const InstructorProfilePage({super.key});

  @override
  State<InstructorProfilePage> createState() => _InstructorProfilePageState();
}

class _InstructorProfilePageState extends State<InstructorProfilePage> {
  final AuthService _authService = AuthService();
  final CourseService _courseService = CourseService();

  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        final user = await _authService.getUserData(userId);
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userId = _authService.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit profile
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.deepPurple.shade50),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.deepPurple.shade200,
                    backgroundImage: _user?.profileImage != null
                        ? NetworkImage(_user!.profileImage!)
                        : null,
                    child: _user?.profileImage == null
                        ? Text(
                            (_user?.name ?? _user?.email ?? 'I')[0]
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 36,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Name
                  Text(
                    _user?.name ?? 'Instructor',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Email
                  Text(
                    _user?.email ?? '',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),

                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Instructor',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            // Stats
            StreamBuilder<List<CourseModel>>(
              stream: _courseService.getInstructorCourses(userId),
              builder: (context, snapshot) {
                final courses = snapshot.data ?? [];
                final totalStudents = courses.fold<int>(
                  0,
                  (sum, course) => sum + course.enrolledStudents.length,
                );
                final publishedCount = courses
                    .where((c) => c.isPublished)
                    .length;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('${courses.length}', 'Courses'),
                      _buildDivider(),
                      _buildStatColumn('$totalStudents', 'Students'),
                      _buildDivider(),
                      _buildStatColumn('$publishedCount', 'Published'),
                    ],
                  ),
                );
              },
            ),

            const Divider(),

            // Menu Items
            _buildMenuItem(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () {
                // TODO: Navigate to edit profile
              },
            ),
            _buildMenuItem(
              icon: Icons.analytics_outlined,
              title: 'Analytics',
              onTap: () {
                // TODO: Navigate to analytics
              },
            ),
            _buildMenuItem(
              icon: Icons.payment_outlined,
              title: 'Earnings',
              onTap: () {
                // TODO: Navigate to earnings
              },
            ),
            _buildMenuItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                // TODO: Navigate to settings
              },
            ),
            _buildMenuItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                // TODO: Navigate to help
              },
            ),

            const Divider(),

            // Logout
            _buildMenuItem(
              icon: Icons.logout,
              title: 'Logout',
              color: Colors.red,
              onTap: _logout,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 40, width: 1, color: Colors.grey[300]);
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey[700]),
      title: Text(title, style: TextStyle(color: color)),
      trailing: Icon(Icons.chevron_right, color: color ?? Colors.grey[400]),
      onTap: onTap,
    );
  }
}
