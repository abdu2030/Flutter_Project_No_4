// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 👈 Import this
import 'package:eduvox/shared/theme/app_theme.dart';
import 'package:eduvox/features/auth/auth_gate.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  }

  // Load the saved theme from storage BEFORE the app starts
  final prefs = await SharedPreferences.getInstance();
  final String? savedThemeString = prefs.getString('theme_mode');

  // Convert string to ThemeMode
  ThemeMode initialTheme = ThemeMode.system;
  if (savedThemeString == 'ThemeMode.dark') initialTheme = ThemeMode.dark;
  if (savedThemeString == 'ThemeMode.light') initialTheme = ThemeMode.light;

  runApp(ProviderScope(child: MyApp(initialTheme: initialTheme)));
}

class MyApp extends StatefulWidget {
  final ThemeMode initialTheme;
  const MyApp({super.key, required this.initialTheme});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ValueNotifier<ThemeMode> themeNotifier;

  @override
  void initState() {
    super.initState();
    // Initialize the notifier with the saved value
    themeNotifier = ValueNotifier(widget.initialTheme);

    // Listen for changes and save them
    themeNotifier.addListener(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', themeNotifier.value.toString());
    });
  }

  @override
  void dispose() {
    themeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, ThemeMode currentTheme, child) {
        return MaterialApp(
          title: 'EduVox',
          debugShowCheckedModeBanner: false,

          // Themes
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentTheme,

          // Theme Provider Injection
          builder: (context, child) {
            return ThemeProvider(themeNotifier: themeNotifier, child: child!);
          },

          home: const AuthGate(),
        );
      },
    );
  }
}

// Theme Provider
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
