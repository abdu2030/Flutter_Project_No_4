import 'package:flutter/material.dart';
import 'package:eduvox/core/services/auth_service.dart';
import 'package:eduvox/shared/theme/app_theme.dart';
import 'package:eduvox/features/dashboard/instructor/pages/profile_page.dart'; // 👈 IMPORT THIS

class DashboardHeader extends StatelessWidget {
  final String roleText;
  final IconData icon;

  const DashboardHeader({
    super.key,
    required this.roleText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;
    final name = user?.displayName?.split(' ').first ?? 'Instructor';
    final photoUrl = user?.photoURL;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Side: Greeting
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $name 👋',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Text(
                  roleText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),

        // 👉 RIGHT SIDE: CLICKABLE PROFILE PICTURE
        GestureDetector(
          onTap: () {
            // ✅ This is where the navigation happens
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const InstructorProfilePage(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? const Icon(Icons.person, color: AppTheme.primaryColor)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
