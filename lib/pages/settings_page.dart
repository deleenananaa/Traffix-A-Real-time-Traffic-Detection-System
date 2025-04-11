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
                        'Settings',
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
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      top: 16,
                      bottom: 8,
                    ),
                    child: Text(
                      'Help & Support',
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
                            Icons.email_outlined,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: .6),
                          ),
                          title: Text(
                            'Contact Support',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: .6),
                          ),
                          onTap: () {
                            // Handle contact support
                          },
                        ),
                        Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.help_outline,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: .6),
                          ),
                          title: Text(
                            'FAQs & Tutorials',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: .6),
                          ),
                          onTap: () {
                            // Handle FAQs & tutorials
                          },
                        ),
                        Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.info_outline,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: .6),
                          ),
                          title: Text(
                            'About the App',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: .6),
                          ),
                          onTap: () {
                            // Handle about the app
                          },
                        ),
                        Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.description_outlined,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: .6),
                          ),
                          title: Text(
                            'Terms & Conditions',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: .6),
                          ),
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
