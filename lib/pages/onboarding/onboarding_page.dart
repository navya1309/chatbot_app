import 'package:chatbot_app_1/core/utils.dart';
import 'package:chatbot_app_1/pages/auth/login_page.dart';
import 'package:chatbot_app_1/pages/auth/signup_page.dart';
import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<_OnboardingStep> _steps = const [
    _OnboardingStep(
      title: 'Chat with care',
      description:
          'Start gentle, private conversations with your AI companion to process emotions and get support.',
      icon: Icons.chat_bubble_outline,
      accentColor: Color(0xFF6366F1),
    ),
    _OnboardingStep(
      title: 'Journal your days',
      description:
          'Capture thoughts, track moods, and reflect on patterns that help you grow.',
      icon: Icons.book_outlined,
      accentColor: Color(0xFF10B981),
    ),
    _OnboardingStep(
      title: 'Learn and track wellness',
      description:
          'Explore myth-busting facts and keep a cycle log to stay in sync with your body.',
      icon: Icons.calendar_today_outlined,
      accentColor: Color(0xFFF59E0B),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    moveTo(context, const LoginPage());
  }

  void _goToSignUp() {
    moveTo(context, const SignUpPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              'PillowTalk',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.grey[900],
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your daily space for calm, clarity, and care',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildStep(_steps[index]);
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _steps.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _currentIndex == index ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? const Color(0xFF6366F1)
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _goToLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Continue to Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _goToSignUp,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6366F1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Create an Account',
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(_OnboardingStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  step.accentColor.withOpacity(0.15),
                  step.accentColor.withOpacity(0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              step.icon,
              size: 64,
              color: step.accentColor,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingStep {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;

  const _OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
  });
}
