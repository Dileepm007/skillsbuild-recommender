import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'profile_input_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still checking auth state - show loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.ibmWhite,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.ibmBlue),
            ),
          );
        }

        // User is logged in → go to Profile (they'll get to Dashboard via the flow)
        if (snapshot.hasData && snapshot.data != null) {
          return const ProfileInputScreen();
        }

        // Not logged in → show Login screen, I just need to test.
        return const LoginScreen();
      },
    );
  }
}
