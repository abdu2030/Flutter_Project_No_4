// lib/features/home/home_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:eduvox/shared/theme/app_theme.dart';
import 'package:eduvox/core/services/auth_service.dart'; // ✅ Added for Logout logic
import 'package:eduvox/features/auth/auth_gate.dart'; // ✅ Added for Navigation logic
import 'package:eduvox/features/auth/login_page.dart';
import 'package:eduvox/features/auth/register_page.dart';
import 'package:eduvox/features/settings/settings_page.dart';
import 'package:eduvox/features/dashboard/student/pages/student_course_details_page.dart';
import 'package:eduvox/features/dashboard/student/student_dashboard.dart';
import 'package:eduvox/features/dashboard/instructor/instructor_dashboard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final NumberFormat _currencyFormatter = NumberFormat.simpleCurrency();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 Theme Data
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        return Scaffold(
          appBar: _buildAppBar(context, user, theme, isDark),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroSection(user),
                const SizedBox(height: 24),
                _buildSearchBar(isDark),
                const SizedBox(height: 24),

                // Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Featured Courses',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to 'All Courses'
                        },
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                _buildCourseGrid(theme, isDark),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ APP BAR
  AppBar _buildAppBar(
    BuildContext context,
    User? user,
    ThemeData theme,
    bool isDark,
  ) {
    return AppBar(
      title: const Text(
        'EduVox',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
        ),
        if (user == null) ...[
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            ),
            child: const Text('Login'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterPage()),
            ),
            child: const Text('Sign Up'),
          ),
          const SizedBox(width: 12),
        ] else ...[
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              child: Text(
                user.email != null ? user.email![0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onSelected: (value) async {
              if (value == 'logout') {
                // ✅ UPDATED LOGOUT LOGIC
                // 1. Sign out from Firebase & Google
                await AuthService().logout();

                if (context.mounted) {
                  // 2. Navigate to AuthGate (which redirects to Home)
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthGate()),
                    (route) => false,
                  );
                }
              } else if (value == 'profile') {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (c) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  final doc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get();

                  if (context.mounted) Navigator.pop(context);

                  if (doc.exists && context.mounted) {
                    final role = doc.data()?['role'] ?? 'student';
                    if (role == 'instructor') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InstructorDashboard(),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StudentDashboard(),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 8),
                    Text('Dashboard'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppTheme.errorColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ],
    );
  }

  // ✅ HERO SECTION
  Widget _buildHeroSection(User? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user == null
                ? 'Upgrade Your Skills'
                : 'Welcome back, ${user.displayName ?? 'Student'}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Learn from expert instructors anytime, anywhere.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Browse Courses'),
          ),
        ],
      ),
    );
  }

  // ✅ SEARCH BAR
  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) =>
            setState(() => _searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'What do you want to learn?',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        ),
      ),
    );
  }

  // ✅ GRID - STRICT FILTERING
  Widget _buildCourseGrid(ThemeData theme, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      // 1. Query Firestore for published courses
      stream: FirebaseFirestore.instance
          .collection('courses')
          .where('isPublished', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading courses"));
        }

        final docs = snapshot.data?.docs ?? [];

        // 2. Client-Side Double Check
        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // ✅ STRICT CHECK: Ensure isPublished is strictly true
          final bool isPublished = data['isPublished'] == true;

          final title = (data['title'] ?? '').toString().toLowerCase();
          final matchesSearch = title.contains(_searchQuery);

          return isPublished && matchesSearch;
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No courses found"),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _courseCard(data, doc.id, theme, isDark);
          },
        );
      },
    );
  }

  // ✅ CARD
  Widget _courseCard(
    Map<String, dynamic> data,
    String courseId,
    ThemeData theme,
    bool isDark,
  ) {
    final String title = data['title'] ?? 'Untitled Course';
    final String instructor = data['instructorName'] ?? 'Unknown Instructor';
    final String thumbnailUrl = data['thumbnailUrl'] ?? '';
    final double price = (data['price'] ?? 0).toDouble();
    final double rating = (data['rating'] ?? 0.0).toDouble();

    return GestureDetector(
      onTap: () {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to view details'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentCourseDetailPage(courseId: courseId),
            ),
          );
        }
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 3,
              child: thumbnailUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (c, u) => Container(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (c, u, e) => Container(
                        color: Colors.grey.withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: const Center(
                        child: Icon(
                          Icons.school_rounded,
                          size: 40,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
            ),
            // Details Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      'By $instructor',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: AppTheme.warningColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: price == 0
                                ? AppTheme.successColor.withValues(alpha: 0.1)
                                : AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            price == 0
                                ? 'Free'
                                : _currencyFormatter.format(price),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: price == 0
                                  ? AppTheme.successColor
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
