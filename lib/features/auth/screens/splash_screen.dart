import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<void> _decideNext() async {
    // Tunda singkat untuk menampilkan splash
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    // 1) Jika sudah login (ada sesi Supabase) langsung ke beranda
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }

    // 2) Jika sudah pernah menyelesaikan onboarding, langsung ke login
    final prefs = await SharedPreferences.getInstance();
    final doneOnboarding = prefs.getBool('onboarding_done') ?? false;
    if (doneOnboarding) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    // 3) Default: tampilkan onboarding
    Navigator.of(context).pushReplacementNamed('/onboarding');
  }

  @override
  void initState() {
    super.initState();
    _decideNext();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white, // White background
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Placeholder logo from assets
              Image.asset(
                'assets/images/logo_nawakita.jpg',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => Icon(
                  Icons.image_not_supported_outlined,
                  size: 64,
                  color: cs.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}