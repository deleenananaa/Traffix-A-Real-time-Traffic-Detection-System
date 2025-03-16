import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';

class LoginOrSignupPage extends StatefulWidget {
  const LoginOrSignupPage({super.key});

  @override
  State<LoginOrSignupPage> createState() => _LoginOrSignupPageState();
}

class _LoginOrSignupPageState extends State<LoginOrSignupPage> {
  //initial login page
  bool isLoginPage = true;

  //toggle between login and signup pages
  void togglePage() {
    setState(() {
      isLoginPage = !isLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoginPage) {
      return LoginPage(onTap: togglePage);
    } else {
      return SignupPage(onTap: togglePage);
    }
  }
}
