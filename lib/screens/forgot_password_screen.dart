import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();

  bool _isSubmitting = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _successMessage = null;
      _errorMessage = null;
    });

    final result = await _authService.sendPasswordResetEmail(
      _emailController.text,
    );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      if (result.isSuccess) {
        _successMessage = result.successMessageText;
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppTheme.ibmWhite,
      body: SafeArea(
        child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            color: AppTheme.ibmHeaderBlack,
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIBMLogo(),
                const Spacer(),
                const Text(
                  'Reset your\npassword',
                  style: TextStyle(
                    color: AppTheme.ibmWhite,
                    fontSize: 42,
                    fontWeight: FontWeight.w300,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'We\'ll email you a secure link to set a new password and get you back to learning.',
                  style: TextStyle(
                    color: Color(0xFFC6C6C6),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                const Text(
                  'IBM SkillsBuild Learning Pathway Advisor',
                  style: TextStyle(color: Color(0xFFC6C6C6), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 7,
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _buildForm(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildIBMLogo(dark: true),
          const SizedBox(height: 32),
          _buildForm(),
        ],
      ),
    );
  }

  Widget _buildIBMLogo({bool dark = false}) {
    return Row(
      children: [
        Text(
          'IBM',
          style: TextStyle(
            color: dark ? AppTheme.ibmBlack : AppTheme.ibmWhite,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 1,
          height: 22,
          color: dark ? AppTheme.ibmGray : const Color(0xFFC6C6C6),
        ),
        const SizedBox(width: 10),
        Text(
          'SkillsBuild',
          style: TextStyle(
            color: dark ? AppTheme.ibmBlack : AppTheme.ibmWhite,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 16, color: AppTheme.ibmBlue),
                  SizedBox(width: 6),
                  Text(
                    'Back to login',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.ibmBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Forgot your password?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppTheme.ibmBlack,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the email address linked to your account and we\'ll send you a secure link to reset your password.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.ibmGray,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Email field
          const Text(
            'Email address',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.ibmBlack,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'you@example.com'),
            enabled: _successMessage == null,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@') || !v.contains('.')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Success message
          if (_successMessage != null) _buildSuccessBanner(_successMessage!),

          // Error message
          if (_errorMessage != null) _buildErrorBanner(_errorMessage!),

          const SizedBox(height: 8),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_isSubmitting || _successMessage != null)
                  ? null
                  : _handleSubmit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: AppTheme.ibmWhite,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send_outlined, size: 16),
              label: Text(
                _isSubmitting
                    ? 'Sending...'
                    : _successMessage != null
                    ? 'Email Sent ✓'
                    : 'Send Reset Link',
              ),
            ),
          ),

          if (_successMessage != null) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Return to login'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.ibmGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.ibmGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.mark_email_read_outlined,
            size: 20,
            color: AppTheme.ibmGreen,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.ibmBlack,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFDA1E28).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 20, color: Color(0xFFDA1E28)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppTheme.ibmBlack),
            ),
          ),
        ],
      ),
    );
  }
}
