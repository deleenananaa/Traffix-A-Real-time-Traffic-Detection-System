import 'package:flutter/material.dart';
import 'package:traffix/pages/home_page.dart';
import 'package:traffix/pages/auth_pages/login_or_signup_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sign out when page loads
    FirebaseAuth.instance.signOut();
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          //user is logged in
          if (snapshot.hasData) {
            return HomePage();
          }
          //user is not logged in
          else {
            return LoginOrSignupPage();
          }
        },
      ),
    );
  }
}
