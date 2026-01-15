import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../main.dart'; // import for AuthWrapper

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  Future<void> _startTimer() async {
    await Future.delayed(const Duration(seconds: 2)); // 2 seconds delay
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AuthWrapper(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Logo
            Image.asset(
              'assets/icon/app_icon.png',
              width: 300, // Even Bigger logo
              height: 300,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 32),
            // Loading indicator
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const Spacer(),
            // Version Info
            Text(
              "Annur Motor System v1.0.0",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
