import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream that emits the current user whenever auth state changes
  // (used to auto-redirect when user logs in/out)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get the currently logged-in user (or null if not logged in)
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Set display name on the user profile
      await credential.user?.updateDisplayName(displayName.trim());
      await credential.user?.reload();

      return AuthResult.success(credential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getSignUpErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('Something went wrong. Please try again.');
    }
  }

  // Log in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.success(credential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getSignInErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('Something went wrong. Please try again.');
    }
  }

  // Log out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send a password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.successMessage(
        'Password reset link sent to $email. Check your inbox (and spam folder).',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getResetPasswordErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  // Helper to convert Firebase error codes into friendly messages
  String _getSignUpErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email sign-up is disabled. Contact support.';
      default:
        return 'Sign up failed. Please try again.';
    }
  }

  String _getSignInErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  String _getResetPasswordErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return 'Failed to send reset email. Please try again.';
    }
  }
}

// Result wrapper so UI can cleanly handle success/failure
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? errorMessage;
  final String? successMessageText;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
    this.successMessageText,
  });

  factory AuthResult.success(User user) =>
      AuthResult._(isSuccess: true, user: user);

  factory AuthResult.successMessage(String message) =>
      AuthResult._(isSuccess: true, successMessageText: message);

  factory AuthResult.failure(String error) =>
      AuthResult._(isSuccess: false, errorMessage: error);
}
