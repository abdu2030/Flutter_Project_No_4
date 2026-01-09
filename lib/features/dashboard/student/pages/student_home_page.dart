// lib/features/dashboard/student/pages/student_home_page.dart

import 'package:flutter/material.dart';
import 'package:eduvox/core/models/course_model.dart';
import 'package:eduvox/core/services/course_service.dart';
import 'package:eduvox/core/services/auth_service.dart';
import 'package:eduvox/features/dashboard/student/pages/student_course_details_page.dart';
import 'package:eduvox/shared/theme/app_theme.dart';
import 'package:eduvox/features/dashboard/student/pages/edit_profile_page.dart';

class StudentHomePage extends StatefulWidget {
  final Function(int) onSwitchTab;

  const StudentHomePage({super.key, required this.onSwitchTab});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  final CourseService _courseService = CourseService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    "All",
    "Programming",
    "Design",
    "Business",
    "Marketing",
    "Music",
  ];

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final firstName = user?.displayName?.split(' ').first ?? 'Student';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : const Color(0xFFF8F9FC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER + SEARCH
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              color: isDark ? AppTheme.darkSurface : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER ROW ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, $firstName 👋',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ready to learn something new?',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),

                      GestureDetector(
                        onTap: () {
                          // Navigate to Edit Profile Page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfilePage(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: AppTheme.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            backgroundImage: user?.photoURL != null
                                ? NetworkImage(user!.photoURL!)
                                : null,
                            child: user?.photoURL == null
                                ? const Icon(
                                    Icons.person,
                                    color: AppTheme.primaryColor,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search for courses...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.grey[800]
                          : const Color(0xFFF4F5F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- MOTIVATION BANNER ---
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryColor, Color(0xFF6C63FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Upgrade your Skills!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Get 30% off on all coding courses this week.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.rocket_launch_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- CATEGORY CHIPS ---
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final isSelected = _selectedCategoryIndex == index;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategoryIndex = index),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : (isDark
                                          ? Colors.grey[800]
                                          : Colors.white),
                                borderRadius: BorderRadius.circular(20),
                                border: isSelected
                                    ? null
                                    : Border.all(
                                        color: isDark
                                            ? Colors.transparent
                                            : Colors.grey.shade300,
                                      ),
                              ),
                              child: Text(
                                _categories[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                            ? Colors.white70
                                            : Colors.grey[600]),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Popular Courses',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'See All',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildCourseList(isDark),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseList(bool isDark) {
    return StreamBuilder<List<CourseModel>>(
      stream: _courseService.getPublishedCourses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final courses = snapshot.data ?? [];

        final filteredCourses = courses.where((course) {
          final matchesSearch = course.title.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

          final selectedCategory = _categories[_selectedCategoryIndex];
          bool matchesCategory = true;

          if (selectedCategory != "All") {
            matchesCategory =
                course.category.toLowerCase() == selectedCategory.toLowerCase();
          }

          return matchesSearch && matchesCategory;
        }).toList();

        if (filteredCourses.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No courses found',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filteredCourses.length,
          itemBuilder: (context, index) {
            final course = filteredCourses[index];
            return _buildCourseCard(course, isDark);
          },
        );
      },
    );
  }

  Widget _buildCourseCard(CourseModel course, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    StudentCourseDetailPage(courseId: course.id),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: course.thumbnailUrl != null
                      ? Image.network(
                          course.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (c, o, s) => const Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        )
                      : Icon(Icons.image, size: 50, color: Colors.grey[500]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            course.category.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              course.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.grey,
                          child: Icon(
                            Icons.person,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            course.instructorName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          course.price == 0 ? 'FREE' : '${course.price} ETB',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: course.price == 0
                                ? Colors.green
                                : AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
