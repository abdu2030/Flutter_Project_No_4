// lib/features/dashboard/student/pages/student_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eduvox/core/services/auth_service.dart'; // To handle Google Logout
import 'package:eduvox/features/auth/auth_gate.dart'; // To redirect to Home Page
import 'package:eduvox/shared/theme/app_theme.dart';
import 'package:eduvox/features/dashboard/student/student_provider.dart';
import 'package:eduvox/features/settings/settings_page.dart';
import 'package:eduvox/features/dashboard/student/pages/edit_profile_page.dart';

class StudentProfilePage extends ConsumerWidget {
  const StudentProfilePage({super.key});

  // ✅ Logout Function
  Future<void> _handleLogout(BuildContext context) async {
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
      // 1. Use AuthService to sign out (Clears Firebase AND Google)
      await AuthService().logout();

      if (context.mounted) {
        // 2. Navigate to AuthGate (Which detects null user and shows HomePage)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(studentStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: () async {
          await FirebaseAuth.instance.currentUser?.reload();
          ref.invalidate(currentUserProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 1. Profile Card
              userAsync.when(
                data: (user) => _buildProfileHeader(user, isDark),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Error loading profile'),
              ),
              const SizedBox(height: 24),

              // 2. Statistics
              statsAsync.when(
                data: (stats) => _buildStatsCard(stats, isDark),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 24),

              // 3. Menu Items
              _buildMenuItem(
                icon: Icons.person_outline_rounded,
                title: 'Edit Profile',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfilePage()),
                  );
                },
                isDark: isDark,
              ),
              _buildMenuItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
                isDark: isDark,
              ),
              _buildMenuItem(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                onTap: () {},
                isDark: isDark,
              ),

              // ✅ Updated Logout Item
              _buildMenuItem(
                icon: Icons.logout_rounded,
                title: 'Logout',
                onTap: () => _handleLogout(context), // Call helper function
                isDark: isDark,
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User? user, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.primaryGradient,
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            child: ClipOval(
              child: SizedBox(
                width: 100,
                height: 100,
                child: (user?.photoURL != null && user!.photoURL!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: user.photoURL!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) {
                          return _buildFallbackAvatar(user);
                        },
                      )
                    : _buildFallbackAvatar(user),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user?.displayName ?? 'Student',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          user?.email ?? '',
          style: TextStyle(
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackAvatar(User? user) {
    return Center(
      child: Text(
        (user?.email != null && user!.email!.isNotEmpty)
            ? user.email![0].toUpperCase()
            : 'S',
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildStatsCard(StudentStats stats, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('${stats.enrolled}', 'Enrolled', isDark),
          Container(height: 40, width: 1, color: Colors.grey.withOpacity(0.2)),
          _buildStatItem('${stats.completed}', 'Completed', isDark),
          Container(height: 40, width: 1, color: Colors.grey.withOpacity(0.2)),
          _buildStatItem('${stats.inProgress}', 'Active', isDark),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? AppTheme.errorColor.withOpacity(0.1)
                : AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? AppTheme.errorColor : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isDark ? Colors.white38 : Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
    );
  }
}
