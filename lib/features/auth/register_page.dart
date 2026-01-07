// lib/features/auth/register_page.dart

import 'package:eduvox/features/auth/login_page.dart';
import 'package:eduvox/features/dashboard/instructor/instructor_dashboard.dart';
import 'package:eduvox/features/dashboard/student/student_dashboard.dart';
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/validators.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // ✅ ROLE SELECTION
  String _selectedRole = 'student';

  // ✅ EMAIL/PASSWORD REGISTER
  void register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.register(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        role: _selectedRole,
        name: nameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account created as ${_selectedRole.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );

        _navigateToDashboard();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ GOOGLE REGISTER (WITH STRICT ROLE CHECK)
  void registerWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      // 1. Authenticate with Google
      final user = await _authService.signInWithGoogle(role: _selectedRole);

      if (user != null && mounted) {
        // 2. 🛑 STRICT CHECK: Get the ACTUAL role from Firestore
        final String? storedRole = await _authService.getUserRole(user.uid);

        // 3. Compare: If DB says 'instructor' but user selected 'student' (or vice versa)
        if (storedRole != null && storedRole != _selectedRole) {
          // 🛑 Mismatch detected! Sign them out immediately.
          await _authService.logout();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Access Denied',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This email is already registered as an ${storedRole.toUpperCase()}.\n'
                      'You cannot sign in as a ${_selectedRole.toUpperCase()}.',
                    ),
                  ],
                ),
                backgroundColor: Colors.red.shade700,
                duration: const Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return; // ⛔ Stop execution here. Do not navigate.
        }

        // 4. ✅ Success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Signed up with Google as ${_selectedRole.toUpperCase()}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        _navigateToDashboard();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ HELPER: Navigate to correct dashboard
  void _navigateToDashboard() {
    if (_selectedRole == 'instructor') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const InstructorDashboard()),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const StudentDashboard()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon
                  Icon(
                    Icons.person_add_outlined,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Create Account',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign up to get started',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),

                  // ✅ ROLE SELECTION CARD
                  _buildRoleSelector(),
                  const SizedBox(height: 24),

                  // Name Field
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    validator: Validators.password,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: _obscureConfirm,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirm your password';
                      }
                      if (value != passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedRole == 'instructor'
                            ? Colors.deepPurple
                            : Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Create ${_selectedRole == 'instructor' ? 'Instructor' : 'Student'} Account',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // OR divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: Colors.grey.shade300, height: 1),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('OR'),
                      ),
                      Expanded(
                        child: Divider(color: Colors.grey.shade300, height: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ✅ GOOGLE REGISTER BUTTON (Updated with Asset Image)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : registerWithGoogle,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 🖼️ The Google Logo
                          Image.asset(
                            'assets/images/google.png',
                            height: 24,
                            width: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Sign up with Google',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Login Link
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    ),
                    child: const Text('Already have an account? Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ ROLE SELECTOR WIDGET
  Widget _buildRoleSelector() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Student Option
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = 'student'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _selectedRole == 'student'
                      ? Colors.blue.shade50
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    bottomLeft: Radius.circular(11),
                  ),
                  border: _selectedRole == 'student'
                      ? Border.all(color: Colors.blue, width: 2)
                      : null,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 32,
                      color: _selectedRole == 'student'
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Student',
                      style: TextStyle(
                        fontWeight: _selectedRole == 'student'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedRole == 'student'
                            ? Colors.blue
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Learn courses',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Instructor Option
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = 'instructor'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _selectedRole == 'instructor'
                      ? Colors.deepPurple.shade50
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(11),
                    bottomRight: Radius.circular(11),
                  ),
                  border: _selectedRole == 'instructor'
                      ? Border.all(color: Colors.deepPurple, width: 2)
                      : null,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cast_for_education_outlined,
                      size: 32,
                      color: _selectedRole == 'instructor'
                          ? Colors.deepPurple
                          : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Instructor',
                      style: TextStyle(
                        fontWeight: _selectedRole == 'instructor'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedRole == 'instructor'
                            ? Colors.deepPurple
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create courses',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
