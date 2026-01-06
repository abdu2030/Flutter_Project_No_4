import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eduvox/shared/theme/app_theme.dart';
import 'package:eduvox/features/dashboard/student/student_provider.dart';
import 'package:eduvox/features/settings/settings_page.dart';
import 'package:eduvox/features/auth/login_page.dart';
import 'package:eduvox/features/dashboard/student/pages/edit_profile_page.dart';

class StudentProfilePage extends ConsumerWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(studentStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      // 👇 ADDED RefreshIndicator
      body: RefreshIndicator(
        onRefresh: () async {
          // 1. Force Firebase to fetch latest data from server
          await FirebaseAuth.instance.currentUser?.reload();
          // 2. Refresh the provider to update UI
          ref.invalidate(currentUserProvider);
        },
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // Required for RefreshIndicator
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 1. Profile Card
              userAsync.when(
                data: (user) {
                  // 👇 DEBUG: Check your console to see if URL exists
                  print("Current Photo URL: ${user?.photoURL}");
                  return _buildProfileHeader(user, isDark);
                },
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
              _buildMenuItem(
                icon: Icons.logout_rounded,
                title: 'Logout',
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  }
                },
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
                // Check if URL is valid
                child: (user?.photoURL != null && user!.photoURL!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: user.photoURL!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) {
                          print("❌ Image Load Error: $error"); // Debug print
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
