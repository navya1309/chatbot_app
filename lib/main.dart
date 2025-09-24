import 'package:chatbot_app_1/firebase_options.dart';
import 'package:chatbot_app_1/pages/auth/provider/auth_provider.dart';
import 'package:chatbot_app_1/pages/home/provider/chat_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/auth/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider(
        create: (_) => AuthenticationProvider(),
      ),
      ChangeNotifierProvider(
        create: (_) => GeminiApi(),
      )
    ], child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PillowTalk',
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.hasData && asyncSnapshot.data != null) {
              return const LoginPage();
            }
            return LoginPage();
          }),
    );
  }
}
