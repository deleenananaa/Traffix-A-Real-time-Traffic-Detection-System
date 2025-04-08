import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
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
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Extra space to balance the back button
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1),

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
                              color: Colors.grey[200],
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
                    const Text(
                      'User',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Email
                    Text(
                      'user@gmail.com',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),

                    // const SizedBox(height: 10),

                    // User Preferences section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(
                            left: 16,
                            top: 16,
                            bottom: 8,
                          ),
                          child: Text(
                            'User Preferences',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: .2),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(
                                  Icons.download,
                                  color: Colors.grey,
                                ),
                                title: const Text('Traffic Analysis'),
                                onTap: () {
                                  // Handle traffic analysis
                                },
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(
                                  Icons.nightlight_round,
                                  color: Colors.grey,
                                ),
                                title: const Text('Dark Mode'),
                                trailing: Switch(
                                  value: false,
                                  onChanged: (value) {
                                    // Handle dark mode toggle
                                  },
                                ),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(
                                  Icons.shield,
                                  color: Colors.grey,
                                ),
                                title: const Text('Settings'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  // Handle settings
                                },
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(
                                  Icons.logout,
                                  color: Colors.red,
                                ),
                                title: const Text(
                                  'Logout',
                                  style: TextStyle(color: Colors.red),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  // Handle logout
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
