import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme.dart';
import 'auth_provider.dart';
import 'widgets/auth_shell.dart';

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
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isSubmitting = true);
    try {
      await context.read<AuthProvider>().register(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
          );
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Akun dibuat. Minta pemilik toko untuk menyetujuinya."),
        ),
      );
      navigator.pop(); // Back to the auth gate, which shows the waiting screen
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(authErrorMessage(e, fallback: "Pendaftaran gagal.")),
          backgroundColor: AppColors.destructiveStrong,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      showBack: true,
      title: "Daftar akun karyawan",
      subtitle: "Akun bisa dipakai setelah disetujui pemilik toko.",
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(
                    labelText: "Nama lengkap",
                    prefixIcon: Icon(LucideIcons.user, size: 20),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Nama wajib diisi" : null,
                ),
                const SizedBox(height: 16),
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
                  autofillHints: const [AutofillHints.newPassword],
                  onFieldSubmitted: (_) => _register(),
                  decoration: InputDecoration(
                    labelText: "Password",
                    helperText: "Minimal 6 karakter",
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
                  validator: (v) => v == null || v.length < 6
                      ? "Password minimal 6 karakter"
                      : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _isSubmitting ? null : _register,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Daftar"),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Sudah punya akun?",
              style: TextStyle(fontSize: 14, color: AppColors.onNavyMuted),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Masuk"),
            ),
          ],
        ),
      ],
    );
  }
}
