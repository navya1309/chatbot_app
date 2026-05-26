import 'package:chatbot_app_1/firebase_options.dart';
import 'package:chatbot_app_1/pages/auth/provider/auth_provider.dart';
import 'package:chatbot_app_1/pages/auth/verify_email_page.dart';
import 'package:chatbot_app_1/pages/bottom_navigation/bottom_navigation.dart';
import 'package:chatbot_app_1/pages/chatbot/provider/chat_provider.dart';
import 'package:chatbot_app_1/pages/journaling/provider/journaling_provider.dart';
import 'package:chatbot_app_1/pages/profile/provider/profile_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'pages/onboarding/onboarding_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }
  runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider(
        create: (_) => AuthenticationProvider(),
      ),
      ChangeNotifierProvider(
        create: (_) => GeminiApi(),
      ),
      ChangeNotifierProvider(
        create: (_) => JournalingProvider(),
      ),
      ChangeNotifierProvider(
        create: (_) => ProfileProvider(),
      ),
    ], child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6366F1);
    const accentColor = Color(0xFFF472B6);

    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return MaterialApp(
      title: 'PillowTalk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
          primary: primaryColor,
          secondary: accentColor,
          surface: Colors.white,
          surfaceContainerHighest: const Color(0xFFF8F7FF),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F7FF),
        textTheme: baseTextTheme.copyWith(
          displayLarge: baseTextTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E1B4B),
          ),
          displayMedium: baseTextTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B4B),
          ),
          headlineLarge: baseTextTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B4B),
          ),
          headlineMedium: baseTextTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B4B),
          ),
          titleLarge: baseTextTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B4B),
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFF374151),
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          shadowColor: Colors.black.withOpacity(0.08),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E1B4B),
          titleTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B4B),
          ),
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primaryColor, width: 2),
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
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFF9CA3AF),
            fontSize: 15,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            side: const BorderSide(color: primaryColor, width: 1.5),
            foregroundColor: primaryColor,
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return primaryColor;
            return null;
          }),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: primaryColor,
          unselectedLabelColor: const Color(0xFF9CA3AF),
          indicatorColor: primaryColor,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          indicatorSize: TabBarIndicatorSize.label,
        ),
      ),
      home: StreamBuilder<User?>(
          // userChanges() fires not just on sign-in/out but also when the
          // user object updates (e.g. after reload() flips emailVerified
          // to true). authStateChanges() would not re-fire and the gate
          // would stay stuck on the verify screen.
          stream: FirebaseAuth.instance.userChanges(),
          builder: (context, asyncSnapshot) {
            final user = asyncSnapshot.data;
            if (asyncSnapshot.hasData && user != null) {
              // Gate the app behind email verification.
              return user.emailVerified
                  ? BottomNavigation()
                  : const VerifyEmailPage();
            }
            return const OnboardingPage();
          }),
      routes: {
        '/onboarding': (_) => const OnboardingPage(),
      },
    );
  }
}
