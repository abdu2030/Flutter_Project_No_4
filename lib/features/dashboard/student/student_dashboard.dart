import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eduvox/features/dashboard/student/nav/bottom_nav.dart';
import 'package:eduvox/features/dashboard/student/pages/student_home_page.dart'; // 👇 Your custom UI is here
import 'package:eduvox/features/dashboard/student/pages/my_courses_page.dart';
import 'package:eduvox/features/dashboard/student/pages/student_profile_page.dart';
// If you have a separate Marketplace/Explore page, import it here:

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // These are the pages for the bottom nav
    final List<Widget> pages = [
      // 0. Home (The UI you requested)
      StudentHomePage(
        onSwitchTab: (index) => setState(() => _currentIndex = index),
      ),
      // 1. My Learning
      const MyCoursesPage(),
      // 2. Profile
      const StudentProfilePage(),
    ];

    return Scaffold(
      // IndexedStack keeps the state of pages alive when switching
      body: IndexedStack(index: _currentIndex, children: pages),
      // ✅ STUDENT BOTTOM NAV
      bottomNavigationBar: StudentBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
