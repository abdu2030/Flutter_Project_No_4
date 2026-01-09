// lib/features/settings/settings_page.dart

import 'package:flutter/material.dart';
import 'package:eduvox/main.dart'; // For ThemeProvider
import 'package:eduvox/core/services/auth_service.dart';
import 'package:eduvox/features/auth/auth_gate.dart';
import 'package:eduvox/shared/theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // LOGOUT LOGIC
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Sign out from Firebase & Google
      await AuthService().logout();

      if (mounted) {
        // Navigate to AuthGate (Redirects to Public Home Page)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeNotifier = ThemeProvider.of(context)!.themeNotifier;
    

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        children: [
          
          _buildSectionHeader('Appearance', theme),
          Card(
            elevation: 0,
            color: theme.cardTheme.color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (context, themeMode, child) {
                  final isDarkMode = themeMode == ThemeMode.dark;
                  final isSystem = themeMode == ThemeMode.system;

                  return Column(
                    children: [
                      // Dark Mode Switch
                      SwitchListTile(
                        title: const Text('Dark Mode'),
                        subtitle: const Text('Enable dark theme'),
                        value: isDarkMode,
                        activeThumbColor: AppTheme.primaryColor,
                        onChanged: (value) {
                          themeNotifier.value = value
                              ? ThemeMode.dark
                              : ThemeMode.light;
                        },
                        secondary: Icon(
                          isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          color: AppTheme.primaryColor,
                        ),
                      ),

                      const Divider(indent: 16, endIndent: 16, height: 1),

                      // System Theme Switch
                      SwitchListTile(
                        title: const Text('Follow System'),
                        subtitle: const Text('Match device appearance'),
                        value: isSystem,
                        activeThumbColor: AppTheme.primaryColor,
                        onChanged: (value) {
                          themeNotifier.value = value
                              ? ThemeMode.system
                              : ThemeMode.light;
                        },
                        secondary: const Icon(Icons.phone_android),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // GENERAL
          _buildSectionHeader('General', theme),
          Card(
            elevation: 0,
            color: theme.cardTheme.color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  trailing: Switch(
                    value: true,
                    onChanged: (val) {}, // Todo: Implement Notifications(for future versions)
                    activeThumbColor: AppTheme.primaryColor,
                  ),
                ),
                const Divider(indent: 16, endIndent: 16, height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('About EduVox'),
                  subtitle: const Text('Version 1.0.0'),
                  onTap: () {
                    // Show About Dialog
                    showAboutDialog(
                      context: context,
                      applicationName: 'EduVox',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(
                        Icons.school,
                        size: 40,
                        color: AppTheme.primaryColor,
                      ),
                      children: [
                        const Text('An online learning platform for everyone.'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ACCOUNT
          _buildSectionHeader('Account', theme),
          Card(
            elevation: 0,
            color: theme.cardTheme.color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.errorColor),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: _handleLogout, 
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
