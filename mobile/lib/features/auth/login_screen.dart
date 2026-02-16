import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../ui/button.dart';
import '../../ui/input.dart';
import 'auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.alertCircle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    // Gradient Background
    final gradientBg = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.mandiriBlueDark, AppColors.mandiriBlueLight],
        ),
      ),
    );

    // Header Content (Logo + Title)
    final headerContent = SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 60,
                height: 60,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Annur Motor System",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            "Sistem Manajemen Bengkel Terintegrasi",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );

    // Login Form Card
    final loginForm = Container(
      width: isDesktop ? 400 : double.infinity,
      margin: EdgeInsets.all(isDesktop ? 0 : 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Selamat Datang!",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.mandiriBlueDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "Silakan masuk ke akun Anda",
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Text(
            "Email Address",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.mandiriBlueDark,
            ),
          ),
          const SizedBox(height: 8),
          CustomInput(
            placeholder: "Masukkan email",
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(
              LucideIcons.mail,
              size: 20,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Password",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.mandiriBlueDark,
            ),
          ),
          const SizedBox(height: 8),
          CustomInput(
            placeholder: "Masukkan password",
            controller: _passwordController,
            obscureText: _obscurePassword,
            prefixIcon: const Icon(
              LucideIcons.lock,
              size: 20,
              color: Colors.grey,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                size: 20,
                color: Colors.grey,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: "Masuk",
            isLoading: authProvider.isLoading,
            onPressed: () async {
              if (_emailController.text.isEmpty ||
                  _passwordController.text.isEmpty) {
                _showError("Harap isi email dan password");
                return;
              }

              try {
                await authProvider.login(
                  _emailController.text,
                  _passwordController.text,
                );
              } catch (e) {
                String errorMsg = "Login Gagal: $e";
                // Handle specific Firebase errors
                if (e.toString().contains("user-not-found") ||
                    e.toString().contains("invalid-credential")) {
                  errorMsg = "Email atau Password salah.";
                } else if (e.toString().contains("wrong-password")) {
                  errorMsg = "Password salah.";
                } else if (e.toString().contains("invalid-email")) {
                  errorMsg = "Format email tidak valid.";
                } else if (e.toString().contains("network-request-failed")) {
                  errorMsg = "Gagal terhubung ke internet.";
                }

                _showError(errorMsg);
              }
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Belum punya akun? ",
                style: TextStyle(color: Colors.grey),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text(
                  "Daftar",
                  style: TextStyle(
                    color: AppColors.mandiriBlueDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (isDesktop) {
      return Scaffold(
        body: Stack(
          children: [
            // Full gradient background
            Positioned.fill(child: gradientBg),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Section (Left)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            'assets/icon/app_icon.png',
                            width: 100,
                            height: 100,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Annur Motor System",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Form Section (Right)
                  Expanded(child: Center(child: loginForm)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile Layout
    return Scaffold(
      body: Stack(
        children: [
          // Background split: Top 40% Gradient, Bottom White
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.45,
            child: gradientBg,
          ),
          Positioned(
            top: size.height * 0.45,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(color: AppColors.background),
          ),

          // Content
          Column(
            children: [
              headerContent,
              Expanded(
                child: Center(child: SingleChildScrollView(child: loginForm)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
