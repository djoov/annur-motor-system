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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Left Side: Hero Image (Desktop Only)
          if (isDesktop)
            Expanded(
              flex: 1,
              child: Container(
                color: const Color(0xFFF1F5F9), // Light bg for image area
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/logo-app.png',
                        width: 300,
                        height: 300,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        "Sistem Manajemen\nBengkel Terintegrasi",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Right Side: Form
          Expanded(
            flex: 1,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isDesktop) ...[
                        Center(
                          child: Image.asset(
                            'assets/logo-app.png',
                            width: 120,
                            height: 120,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      Text(
                        "Annur Motor System",
                        style: const TextStyle(
                          fontSize: 28, // Bigger font
                          fontWeight: FontWeight.bold,
                          color: AppColors.foreground,
                        ),
                        textAlign: isDesktop
                            ? TextAlign.start
                            : TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Masuk untuk mengelola operasional bengkel.",
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.mutedForeground,
                        ),
                        textAlign: isDesktop
                            ? TextAlign.start
                            : TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      const Text(
                        "Email Address",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      CustomInput(
                        placeholder: "name@example.com",
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        "Password",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      CustomInput(
                        placeholder: "********",
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? LucideIcons.eye
                                : LucideIcons.eyeOff,
                            size: 20,
                            color: AppColors.mutedForeground,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: "Sign In",
                        isLoading: authProvider.isLoading,
                        onPressed: () async {
                          try {
                            await authProvider.login(
                              _emailController.text,
                              _passwordController.text,
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Login Gagal: $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Belum punya akun? ",
                            style: TextStyle(color: AppColors.mutedForeground),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            ),
                            child: const Text(
                              "Daftar",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (isDesktop)
                        const Center(
                          child: Text(
                            "v1.0.0 Desktop Client",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
