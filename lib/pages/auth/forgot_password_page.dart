import 'package:chatbot_app_1/core/utils.dart';
import 'package:chatbot_app_1/pages/auth/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  static const _primary = Color(0xFF6366F1);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthenticationProvider provider) async {
    if (!_formKey.currentState!.validate()) return;
    final res =
        await provider.sendPasswordResetEmail(_emailController.text.trim());
    if (!mounted) return;
    if (res) {
      setState(() => _emailSent = true);
    } else {
      showSnackBar(
          context, 'Couldn\'t send reset email. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gradient header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 72, 24, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Forgot Password?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ll email you a reset link',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(24),
              child: _emailSent ? _buildSuccess() : _buildForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter the email associated with your account and we\'ll send you a link to reset your password.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _fieldLabel('Email'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(fontSize: 15),
            decoration: _inputDecoration(
              hint: 'you@example.com',
              icon: Icons.email_outlined,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter your email';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          Consumer<AuthenticationProvider>(builder: (context, provider, _) {
            return SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: provider.loading ? null : () => _submit(provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: provider.loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Send Reset Link',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            );
          }),
          const SizedBox(height: 20),
          _backToSignIn(),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFFEDE9FE),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            color: _primary,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Check your inbox',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E1B4B),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We\'ve sent a password reset link to ${_emailController.text.trim()}. Follow the link to set a new password.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            child: Text(
              'Back to Sign In',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Consumer<AuthenticationProvider>(builder: (context, provider, _) {
          return TextButton(
            onPressed: provider.loading ? null : () => _submit(provider),
            child: Text(
              'Resend email',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: _primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _backToSignIn() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Remember your password? ',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Text(
              'Sign In',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: _primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1E1B4B),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }
}
