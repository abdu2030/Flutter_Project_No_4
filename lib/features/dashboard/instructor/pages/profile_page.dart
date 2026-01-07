// lib/features/instructor/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:eduvox/core/models/user_model.dart';
import 'package:eduvox/core/models/course_model.dart';
import 'package:eduvox/core/services/auth_service.dart';
import 'package:eduvox/core/services/course_service.dart';
import 'package:eduvox/features/auth/login_page.dart';
import 'package:eduvox/shared/theme/app_theme.dart';
import 'package:eduvox/features/dashboard/instructor/pages/instructor_analytics_page.dart';
import 'package:eduvox/features/settings/settings_page.dart'; // ✅ Using existing General Settings
import 'package:eduvox/features/dashboard/instructor/pages/instructor_edit_profile_page.dart'; // ✅ Import new page

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
        if (mounted) {
          setState(() {
            _user = user;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userId = _authService.currentUser?.uid ?? '';

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              // Navigate to Edit Profile and reload data on return
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => InstructorEditProfilePage(user: _user)),
              );
              if (result == true) _loadUserData();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    backgroundImage: _user?.profileImage != null
                        ? NetworkImage(_user!.profileImage!)
                        : null,
                    child: _user?.profileImage == null
                        ? Text(
                            (_user?.name ?? _user?.email ?? 'I')[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 36,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: AppTheme.spacingM),

                  // Name
                  Text(
                    _user?.name ?? 'Instructor',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),

                  // Email
                  Text(
                    _user?.email ?? '',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingM),

                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Instructor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- STATS ROW ---
            StreamBuilder<List<CourseModel>>(
              stream: _courseService.getInstructorCourses(userId),
              builder: (context, snapshot) {
                final courses = snapshot.data ?? [];
                final totalStudents = courses.fold<int>(
                  0,
                  (sum, course) => sum + course.enrolledStudents.length,
                );
                final publishedCount = courses.where((c) => c.isPublished).length;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingL),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn(context, '${courses.length}', 'Courses'),
                      _buildVerticalDivider(isDark),
                      _buildStatColumn(context, '$totalStudents', 'Students'),
                      _buildVerticalDivider(isDark),
                      _buildStatColumn(context, '$publishedCount', 'Published'),
                    ],
                  ),
                );
              },
            ),

            Divider(thickness: 8, color: isDark ? const Color(0xFF121212) : Colors.grey.shade100),

            // --- MENU ITEMS ---
            
            // 1. Edit Profile (Explicit Button in List)
            _buildMenuItem(
              context,
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => InstructorEditProfilePage(user: _user)),
                );
                if (result == true) _loadUserData();
              },
            ),

            // 2. Analytics
            _buildMenuItem(
              context,
              icon: Icons.analytics_outlined,
              title: 'Analytics',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InstructorAnalyticsPage()),
                );
              },
            ),
            
            // 3. Settings (Linked to Main Settings Page)
            _buildMenuItem(
              context,
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),

            // 4. Help (Placeholder)
            _buildMenuItem(
              context,
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help & Support page coming soon')),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
              child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),

            // 5. Logout
            _buildMenuItem(
              context,
              icon: Icons.logout,
              title: 'Logout',
              color: AppTheme.errorColor,
              onTap: _logout,
            ),

            const SizedBox(height: AppTheme.spacingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      height: 40,
      width: 1,
      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final itemColor = color ?? (isDark ? Colors.white : AppTheme.textPrimary);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL, 
        vertical: 4
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.primaryColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color ?? AppTheme.primaryColor, size: 22),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: itemColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }
}