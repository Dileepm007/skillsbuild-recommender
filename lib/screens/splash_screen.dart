import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ibmWhite,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/ibm_skillsbuild_logo.png',
              width: 320,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const Text(
              'Your personalized learning pathway',
              style: TextStyle(fontSize: 16, color: AppTheme.ibmGray),
            ),
            const SizedBox(height: 56),
            const CircularProgressIndicator(
              color: AppTheme.ibmBlue,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
