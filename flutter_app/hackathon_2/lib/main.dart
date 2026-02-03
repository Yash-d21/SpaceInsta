import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hackathon_2/pages/home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Ensure this path matches your file structure
import 'package:hackathon_2/pages/login.dart';

Future<void> main() async {
  // 1. Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Supabase
  await Supabase.initialize(
    url: 'https://bquzjtqlljkgehawwli.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJxdXpqdHFsbGprZ2hnZWF3d2xpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAwOTM1MTIsImV4cCI6MjA4NTY2OTUxMn0.3Vo0uYOlc0XzPw72J-vVE5Cp1xbxOWmI9iSEo3Bdt2s',
  );

  runApp(const MyApp());
}

// 3. Simple getter to access Supabase anywhere in your app
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Galaxy App',
      // Since you mentioned themeMode: ThemeData.dark() earlier:
      theme: ThemeData.dark(useMaterial3: true),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Wait for 3 seconds for the splash effect
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // 4. SMART REDIRECT: Check if user is already logged in
    final session = supabase.auth.currentSession;
    if (session != null) {
      // User is logged in, go to Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      // No session, go to Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rocket_launch_rounded, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'GALAXY APP',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Explore the universe from your pocket',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
