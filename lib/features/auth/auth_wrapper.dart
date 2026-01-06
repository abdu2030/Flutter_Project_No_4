// lib/features/auth/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/auth_service.dart';
import 'package:eduvox/features/dashboard/student/student_dashboard.dart';
import 'package:eduvox/features/dashboard/instructor/instructor_dashboard.dart';
import 'login_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        // User not logged in
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginPage();
        }

        // User is logged in - navigate to RoleRouter
        return RoleRouter(userId: snapshot.data!.uid);
      },
    );
  }
}

// ✅ Separate widget to handle role-based routing
class RoleRouter extends StatefulWidget {
  final String userId;

  const RoleRouter({super.key, required this.userId});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  final AuthService _authService = AuthService();
  String? _role;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final role = await _authService.getUserRole(widget.userId);
      if (mounted) {
        setState(() {
          _role = role;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _role = 'student'; // Default to student on error
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingScreen();
    }

    if (_role == 'instructor') {
      return const InstructorDashboard();
    }

    return const StudentDashboard();
  }
}

// ✅ Simple loading screen
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }
}
