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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.checkCircle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
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

    // Header Content
    final headerContent = SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Back Button
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
              ),
            ),
          ),
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
            "Pendaftaran Akun",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );

    // Register Form Card
    final registerForm = Container(
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Buat Akun Staff",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.mandiriBlueDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Lengkapi data diri Anda",
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const Text(
              "Nama Lengkap",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.mandiriBlueDark,
              ),
            ),
            const SizedBox(height: 8),
            CustomInput(
              placeholder: "Masukkan nama lengkap",
              controller: _nameController,
              prefixIcon: const Icon(
                LucideIcons.user,
                size: 20,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
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
              placeholder: "Buat password",
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
              text: "Daftar Sekarang",
              isLoading: authProvider.isLoading,
              onPressed: () async {
                if (_nameController.text.isEmpty ||
                    _emailController.text.isEmpty ||
                    _passwordController.text.isEmpty) {
                  _showError("Mohon lengkapi semua data");
                  return;
                }

                if (_passwordController.text.length < 6) {
                  _showError("Password minimal 6 karakter");
                  return;
                }

                try {
                  await authProvider.register(
                    _emailController.text,
                    _passwordController.text,
                    _nameController.text,
                  );
                  if (mounted) {
                    _showSuccess("Pendaftaran berhasil!");
                    Navigator.pop(context); // Back to login
                  }
                } catch (e) {
                  String errorMessage = "Registrasi Gagal: $e";

                  if (e.toString().contains("email-already-in-use")) {
                    errorMessage = "Email sudah terdaftar. Silakan login.";
                  } else if (e.toString().contains("weak-password")) {
                    errorMessage = "Password terlalu lemah.";
                  } else if (e.toString().contains("invalid-email")) {
                    errorMessage = "Format email tidak valid.";
                  } else if (e.toString().contains("network-request-failed")) {
                    errorMessage = "Gagal terhubung ke internet.";
                  }

                  _showError(errorMessage);
                }
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Sudah punya akun? ",
                  style: TextStyle(color: Colors.grey),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    "Masuk",
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
      ),
    );

    if (isDesktop) {
      return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: gradientBg),
            Center(child: registerForm),
            Positioned(
              top: 20,
              left: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background split
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.40, // Slightly shorter header for register
            child: gradientBg,
          ),
          Positioned(
            top: size.height * 0.40,
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
                child: Center(
                  child: SingleChildScrollView(child: registerForm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
