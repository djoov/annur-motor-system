import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme.dart';
import 'auth_provider.dart';
import 'register_screen.dart';
import 'widgets/auth_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.destructiveStrong : null,
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await context.read<AuthProvider>().login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    } catch (e) {
      if (mounted) {
        _showMessage(authErrorMessage(e, fallback: "Gagal masuk. Coba lagi."),
            error: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _forgotPassword() async {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Lupa password?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Kami kirim link untuk membuat password baru ke email Anda."),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(LucideIcons.mail, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, emailCtrl.text.trim()),
            child: const Text("Kirim"),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty || !mounted) return;

    try {
      await context.read<AuthProvider>().resetPassword(email);
      if (mounted) _showMessage("Link reset password dikirim ke $email");
    } catch (e) {
      if (mounted) {
        _showMessage(authErrorMessage(e, fallback: "Gagal mengirim email."),
            error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: "Selamat datang kembali",
      subtitle: "Masuk dengan akun dari pemilik toko.",
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(LucideIcons.mail, size: 20),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Email wajib diisi" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(LucideIcons.lock, size: 20),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? "Tampilkan password"
                          : "Sembunyikan password",
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Password wajib diisi" : null,
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _forgotPassword,
            child: const Text("Lupa password?"),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _isSubmitting ? null : _login,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Masuk"),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Karyawan baru?",
              style: TextStyle(fontSize: 14, color: AppColors.onNavyMuted),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              child: const Text("Daftar akun"),
            ),
          ],
        ),
      ],
    );
  }
}
