import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:traffix/theme/theme_provider.dart';
import 'pdf_viewer_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the theme provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Get the current user
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App bar with back button and title
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  // Extra space to balance the back button
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).dividerColor,
            ),

            // Profile information
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Profile image with camera icon
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                              image: const DecorationImage(
                                image: NetworkImage(
                                  'https://img.freepik.com/premium-vector/profile-picture-placeholder-avatar-silhouette-gray-tones-icon-colored-shapes-gradient_1076610-40164.jpg?semt=ais_hybrid&w=740',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Name
                    Text(
                      user?.displayName ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Email
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: .6),
                      ),
                    ),

                    // const SizedBox(height: 10),

                    // User Preferences section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            top: 16,
                            bottom: 8,
                          ),
                          child: Text(
                            'User Preferences',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: .6),
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).shadowColor.withValues(alpha: .2),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: Icon(
                                  Icons.download,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withValues(alpha: .6),
                                ),
                                title: const Text('Traffic Analysis'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const PDFViewerPage(
                                            filePath:
                                                'assets/pdf/TrafficAnalysis.pdf',
                                          ),
                                    ),
                                  );
                                },
                              ),
                              Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor,
                              ),
                              ListTile(
                                leading: Icon(
                                  Icons.nightlight_round,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withValues(alpha: .6),
                                ),
                                title: const Text('Dark Mode'),
                                trailing: Switch.adaptive(
                                  value: themeProvider.isDarkMode,
                                  onChanged: (value) {
                                    // Toggle theme using the provider
                                    themeProvider.toggleTheme();
                                  },
                                ),
                              ),
                              Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor,
                              ),
                              ListTile(
                                leading: Icon(
                                  Icons.shield,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withValues(alpha: .6),
                                ),
                                title: const Text('Settings'),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withValues(alpha: .6),
                                ),
                                onTap: () {
                                  // Handle settings
                                },
                              ),
                              Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor,
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.logout,
                                  color: Colors.red,
                                ),
                                title: const Text(
                                  'Logout',
                                  style: TextStyle(color: Colors.red),
                                ),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withValues(alpha: .6),
                                ),
                                onTap: () async {
                                  try {
                                    await FirebaseAuth.instance.signOut();
                                    if (context.mounted) {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/login',
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error signing out: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
