// lib/main.dart

import 'package:eduvox/features/home/home_page.dart';
import 'package:eduvox/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 👈 1. Import Riverpod

// Ensure this path matches your file structure (core/theme vs shared/theme)

// If you generated firebase_options.dart via flutterfire, import it here:
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // It is recommended to use DefaultFirebaseOptions if generated
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    // Fallback if options aren't generated yet
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  }

  // 👈 2. Wrap the app in ProviderScope
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🎨 Theme Controller - Manages light/dark mode
    final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(
      ThemeMode.system,
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, ThemeMode currentTheme, child) {
        return MaterialApp(
          title: 'EduVox',
          debugShowCheckedModeBanner: false,

          // 🎨 Apply your custom themes
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentTheme,

          // 🔧 Pass themeNotifier to AuthWrapper so it can be accessed throughout the app
          builder: (context, child) {
            return ThemeProvider(themeNotifier: themeNotifier, child: child!);
          },

          home: const HomePage(),
        );
      },
    );
  }
}

// 🛠️ Theme Provider - Makes themeNotifier available throughout the app
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
