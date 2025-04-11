import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
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
                        'Settings',
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

            Expanded(
              child: ListView(
                children: [
                  // const Padding(
                  //   padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  //   child: Text(
                  //     'General Settings',
                  //     style: TextStyle(color: Colors.grey, fontSize: 16),
                  //   ),
                  // ),
                  // Container(
                  //   margin: const EdgeInsets.symmetric(
                  //     horizontal: 16,
                  //     vertical: 8,
                  //   ),
                  //   decoration: BoxDecoration(
                  //     color: Color(0xFFFFFFFF),
                  //     borderRadius: BorderRadius.circular(12),
                  //     boxShadow: [
                  //       BoxShadow(
                  //         color: Colors.grey.withValues(alpha: .2),
                  //         spreadRadius: 1,
                  //         blurRadius: 3,
                  //         offset: const Offset(0, 2),
                  //       ),
                  //     ],
                  //   ),
                  //   child: Column(
                  //     children: [
                  //       ListTile(
                  //         leading: const Icon(
                  //           Icons.lock_outline,
                  //           color: Colors.grey,
                  //         ),
                  //         title: const Text('Change Password'),
                  //         trailing: const Icon(Icons.chevron_right),
                  //         onTap: () {
                  //           // Handle password change
                  //         },
                  //       ),
                  //       const Divider(height: 1),
                  //       ListTile(
                  //         leading: const Icon(
                  //           Icons.notifications_none,
                  //           color: Colors.grey,
                  //         ),
                  //         title: const Text('Notification Preferences'),
                  //         trailing: const Icon(Icons.chevron_right),
                  //         onTap: () {
                  //           // Handle notification preferences
                  //         },
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                    child: Text(
                      'Help & Support',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFFFFF),
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
                            Icons.email_outlined,
                            color: Colors.grey,
                          ),
                          title: const Text('Contact Support'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Handle contact support
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.help_outline,
                            color: Colors.grey,
                          ),
                          title: const Text('FAQs & Tutorials'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Handle FAQs & tutorials
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.info_outline,
                            color: Colors.grey,
                          ),
                          title: const Text('About the App'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Handle about the app
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.description_outlined,
                            color: Colors.grey,
                          ),
                          title: const Text('Terms & Conditions'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Handle terms & conditions
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
