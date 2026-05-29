import 'dart:async';

import 'package:chatbot_app_1/pages/auth/provider/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  static const _primary = Color(0xFF6366F1);

  Timer? _pollTimer;
  bool _checking = false;
  bool _resending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Poll Firebase every 5s so the user lands automatically once they
    // click the link in their inbox.
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _check());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking || !mounted) return;
    setState(() => _checking = true);
    final verified = await context.read<AuthenticationProvider>().reloadUser();
    if (mounted && verified) {
      // Send the user back to the auth gate so it can route them into the
      // app now that emailVerified is true.
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/auth-gate', (_) => false);
    }
    if (!mounted) return;
    setState(() => _checking = false);
    if (verified) {
      _pollTimer?.cancel();
    }
  }

  Future<void> _resend() async {
    if (_resending || _resendCooldown > 0) return;
    setState(() => _resending = true);
    final ok =
        await context.read<AuthenticationProvider>().resendVerificationEmail();
    if (!mounted) return;
    setState(() {
      _resending = false;
      _resendCooldown = ok ? 30 : 0;
    });
    if (ok) {
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        setState(() => _resendCooldown--);
        if (_resendCooldown <= 0) t.cancel();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not resend. Try again shortly.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'your email';
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    await context.read<AuthenticationProvider>().signOut();
                    if (context.mounted) {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/onboarding', (_) => false);
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign out'),
                ),
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.3),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Verify your email',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'We sent a confirmation link to\n$email.\n\nTap the link to activate your account.\n\nIf you don\'t see the email, check your spam folder.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.55,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _checking ? null : _check,
                  icon: _checking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: const Text("I've verified — refresh"),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed:
                      (_resending || _resendCooldown > 0) ? null : _resend,
                  icon: const Icon(Icons.send_rounded),
                  label: Text(
                    _resendCooldown > 0
                        ? 'Resend in ${_resendCooldown}s'
                        : 'Resend email',
                  ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
