import 'package:flutter/material.dart';
import 'services/auth_provider.dart';
import 'home_page/login_page.dart';
import 'home_page/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthProvider.instance.init(); // restore session from disk
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // If already logged in, go straight to HomeScreen.
    final bool loggedIn = AuthProvider.instance.isLoggedIn;

    return MaterialApp(
      title: 'NeetCommon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: loggedIn ? const HomeScreen() : const LoginPage(),
    );
  }
}
