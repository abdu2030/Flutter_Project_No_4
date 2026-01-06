// lib/features/settings/settings_page.dart
import 'package:eduvox/main.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    // 🔍 Get theme notifier from ThemeProvider
    final themeNotifier = ThemeProvider.of(context)!.themeNotifier;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🎨 Theme Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // 🌙 Dark Mode Switch
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (context, themeMode, child) {
                      final isDark = themeMode == ThemeMode.dark;
                      final isSystem = themeMode == ThemeMode.system;
                      
                      return Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Dark Mode'),
                            subtitle: const Text('Enable dark theme'),
                            value: isDark,
                            onChanged: (value) {
                              themeNotifier.value = value 
                                ? ThemeMode.dark 
                                : ThemeMode.light;
                            },
                            secondary: Icon(
                              isDark ? Icons.dark_mode : Icons.light_mode,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          
                          // 📱 Follow System Switch
                          SwitchListTile(
                            title: const Text('Follow System'),
                            subtitle: const Text('Use device theme setting'),
                            value: isSystem,
                            onChanged: (value) {
                              themeNotifier.value = value 
                                ? ThemeMode.system 
                                : ThemeMode.light;
                            },
                            secondary: const Icon(Icons.phone_android),
                          ),
                          
                          // 💡 Current Theme Indicator
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  themeMode == ThemeMode.dark 
                                    ? Icons.dark_mode 
                                    : themeMode == ThemeMode.light
                                      ? Icons.light_mode 
                                      : Icons.brightness_auto,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Current: ${themeMode == ThemeMode.dark ? "Dark" : themeMode == ThemeMode.light ? "Light" : "System"} Mode',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // ⚙️ Other Settings
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Profile'),
              subtitle: const Text('Manage your account'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to profile
              },
            ),
          ),
          
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              subtitle: const Text('Sign out of your account'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Handle logout
              },
            ),
          ),
        ],
      ),
    );
  }
}