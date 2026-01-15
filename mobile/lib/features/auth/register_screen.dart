import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../ui/button.dart';
import '../../ui/input.dart';
import 'auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Daftar Akun Baru"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.foreground,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Buat Akun Staff",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Akun akan dibuat sebagai 'Staff'",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  CustomInput(
                    placeholder: "Nama Lengkap",
                    controller: _nameController,
                  ),
                  CustomInput(
                    placeholder: "Email",
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  CustomInput(
                    placeholder: "Password",
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
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
                  const SizedBox(height: 24),
                  CustomButton(
                    text: "Daftar",
                    isLoading: authProvider.isLoading,
                    onPressed: () async {
                      if (_nameController.text.isEmpty ||
                          _emailController.text.isEmpty ||
                          _passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Mohon lengkapi semua data"),
                          ),
                        );
                        return;
                      }

                      try {
                        await authProvider.register(
                          _emailController.text,
                          _passwordController.text,
                          _nameController.text,
                        );
                        if (mounted) {
                          // Navigation handled by auth listener wrapper or pop
                          Navigator.pop(
                            context,
                          ); // Go back to login or let wrapper handle
                        }
                      } catch (e) {
                        String errorMessage = "Registrasi Gagal: $e";

                        if (e.toString().contains("email-already-in-use")) {
                          errorMessage =
                              "Email sudah terdaftar. Silakan login.";
                        } else if (e.toString().contains("weak-password")) {
                          errorMessage =
                              "Password terlalu lemah (min 6 karakter).";
                        } else if (e.toString().contains("invalid-email")) {
                          errorMessage = "Format email tidak valid.";
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 100), // Push content up visually
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
