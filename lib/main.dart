import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:traffix/pages/alerts_page.dart';
import 'package:traffix/pages/auth_pages/auth_page.dart';
import 'package:traffix/pages/emergency_page.dart';
import 'package:traffix/pages/home_page.dart';
import 'package:traffix/pages/profile_page.dart';
import 'package:traffix/pages/routes_page.dart';
import 'package:traffix/pages/settings_page.dart';
import 'package:traffix/theme/app_theme.dart';
import 'package:traffix/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current theme from the provider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: const AuthPage(),
      routes: {
        '/login': (context) => const AuthPage(),
        '/homepage': (context) => const HomePage(),
        '/routespage': (context) => const RoutesPage(),
        '/alertspage': (context) => const AlertsPage(),
        '/emergencypage': (context) => const EmergencyPage(),
        '/profilepage': (context) => const ProfilePage(),
        '/settingspage': (context) => const SettingsPage(),
      },
    );
  }
}
