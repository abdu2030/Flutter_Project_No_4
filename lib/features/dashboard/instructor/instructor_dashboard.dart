// lib/features/instructor/instructor_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'navigation/bottom_nav.dart';
import 'pages/home_page.dart';
import 'pages/my_courses_page.dart';
import 'pages/students_page.dart';
import 'pages/profile_page.dart';
import 'dialogs/create_course_dialog.dart';

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  // ✅ Initialize controller and animation as nullable
  AnimationController? _fabAnimationController;
  Animation<double>? _fabScaleAnimation;

  // ✅ List of pages for each tab
  final List<Widget> _pages = [
    const InstructorHomePage(),
    const MyCoursesPage(),
    const StudentsPage(),
    const InstructorProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScaleAnimation = CurvedAnimation(
      parent: _fabAnimationController!,
      curve: Curves.easeOutBack,
    );
    _fabAnimationController!.forward();
  }

  @override
  void dispose() {
    _fabAnimationController?.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    HapticFeedback.lightImpact();

    // Animate FAB when switching tabs
    if ((index == 0 || index == 1) &&
        (_currentIndex != 0 && _currentIndex != 1)) {
      _fabAnimationController?.forward(from: 0);
    }

    setState(() => _currentIndex = index);
  }

  void _openCreateCourse() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCourseDialog(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showFab = _currentIndex == 0 || _currentIndex == 1;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,

      // ✅ Body with IndexedStack
      body: IndexedStack(index: _currentIndex, children: _pages),

      // ✅ Enhanced Bottom Navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: InstructorBottomNav(
            currentIndex: _currentIndex,
            onTap: _onTabChanged,
          ),
        ),
      ),

      // ✅ Beautiful animated FAB with null check
      floatingActionButton: showFab ? _buildFab() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFab() {
    // ✅ Safe null check for animation
    if (_fabScaleAnimation == null) {
      return _buildFabContent();
    }

    return ScaleTransition(
      scale: _fabScaleAnimation!,
      child: _buildFabContent(),
    );
  }

  Widget _buildFabContent() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openCreateCourse,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withOpacity(0.2),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
