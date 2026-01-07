// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eduvox/shared/theme/app_theme.dart';

// ✅ IMPORT AUTH GATE (This handles the redirect logic)
import 'package:eduvox/features/auth/auth_gate.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🎨 Theme Controller
    final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(
      ThemeMode.system,
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, ThemeMode currentTheme, child) {
        return MaterialApp(
          title: 'EduVox',
          debugShowCheckedModeBanner: false,

          // 🎨 Themes
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentTheme,

          // 🔧 Theme Provider Injection
          builder: (context, child) {
            return ThemeProvider(themeNotifier: themeNotifier, child: child!);
          },

          // 🛑 CRITICAL FIX: Use AuthGate instead of HomePage
          // This checks authentication on startup and redirects accordingly.
          home: const AuthGate(),
        );
      },
    );
  }
}

// 🛠️ Theme Provider
class ThemeProvider extends InheritedWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const ThemeProvider({
    super.key,
    required this.themeNotifier,
    required super.child,
  });

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return oldWidget.themeNotifier != themeNotifier;
  }

  static ThemeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
  }
}
