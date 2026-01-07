// lib/features/auth/auth_gate.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eduvox/core/services/auth_service.dart';
import 'package:eduvox/features/home/home_page.dart'; // 👈 Public Landing Page
import 'package:eduvox/features/dashboard/student/student_dashboard.dart';
import 'package:eduvox/features/dashboard/instructor/instructor_dashboard.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // 1. Listen to Auth State changes continuously
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // A. Loading (Checking if user is logged in...)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // B. User IS Logged In -> Check Role and go to Dashboard
        if (snapshot.hasData && snapshot.data != null) {
          return RoleResolver(userId: snapshot.data!.uid);
        }

        // C. User IS NOT Logged In -> Go to Public Home Page
        return const HomePage();
      },
    );
  }
}

// Helper to check Firestore for "student" vs "instructor"
class RoleResolver extends StatelessWidget {
  final String userId;

  const RoleResolver({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return FutureBuilder<String?>(
      future: authService.getUserRole(userId),
      builder: (context, snapshot) {
        // 1. Loading Role...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Error Handling (Safety Check)
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error loading profile'),
                  TextButton(
                    onPressed: () => authService.logout(), // Option to reset
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final role = snapshot.data;

        // 3. Navigate to Correct Dashboard
        if (role == 'instructor') {
          return const InstructorDashboard();
        } else {
          // Default to Student if role is 'student' or null/missing
          return const StudentDashboard();
        }
      },
    );
  }
}
