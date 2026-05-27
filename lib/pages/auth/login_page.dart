import 'package:chatbot_app_1/core/utils.dart';
import 'package:chatbot_app_1/pages/auth/forgot_password_page.dart';
import 'package:chatbot_app_1/pages/auth/provider/auth_provider.dart';
import 'package:chatbot_app_1/pages/auth/signup_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  static const _primary = Color(0xFF6366F1);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                    child: ClipOval(
                      child: Image.asset(
                        "assets/images/pillowtalk_logo.png",
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome Back 👋',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to your safe space',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),

            // Form card
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(v)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),
                    _fieldLabel('Password'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: GoogleFonts.inter(fontSize: 15),
                      decoration: _inputDecoration(
                        hint: 'Your password',
                        icon: Icons.lock_outlined,
                        suffix: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: const Color(0xFF9CA3AF),
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter your password';
                        if (v.length < 6) return 'Must be at least 6 characters';
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () =>
                            moveTo(context, const ForgotPasswordPage()),
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: _primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Sign In Button
                    Consumer<AuthenticationProvider>(
                        builder: (context, provider, _) {
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: provider.loading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }
                                  final res = await provider.signInWithEmail(
                                    _emailController.text.trim(),
                                    _passwordController.text,
                                  );
                                  if (context.mounted) {
                                    if (res) {
                                      // Pop back to the auth-gate StreamBuilder
                                      // in main.dart, which will render the
                                      // right screen based on auth state.
                                      // Don't pushReplacement — that removes
                                      // the gate and breaks sign-out routing.
                                      Navigator.of(context)
                                          .popUntil((r) => r.isFirst);
                                    } else {
                                      showSnackBar(context,
                                          'Sign in failed. Check your credentials.');
                                    }
                                  }
                                },
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Sign In',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      );
                    }),

                    const SizedBox(height: 28),

                    // Divider
                    Row(children: [
                      Expanded(
                          child: Divider(color: Colors.grey[300], height: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('or',
                            style: GoogleFonts.inter(
                                fontSize: 14, color: Colors.grey[500])),
                      ),
                      Expanded(
                          child: Divider(color: Colors.grey[300], height: 1)),
                    ]),

                    const SizedBox(height: 24),

                    // Sign Up Link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.inter(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                          GestureDetector(
                            onTap: () => moveTo(context, const SignUpPage()),
                            child: Text(
                              'Sign Up',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: _primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        borderSide:
            const BorderSide(color: Color(0xFFEF4444), width: 1.5),
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
