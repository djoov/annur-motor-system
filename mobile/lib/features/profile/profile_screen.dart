import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme.dart';
import '../auth/auth_provider.dart';

/// The signed-in user's own profile. Shop data lives in Setelan → Toko & Struk.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: context.read<AuthProvider>().userModel?.name ?? '',
    );
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);
    try {
      await context.read<AuthProvider>().updateName(_nameController.text);
      messenger.showSnackBar(const SnackBar(content: Text("Nama disimpan")));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text("Gagal menyimpan nama: $e"),
          backgroundColor: AppColors.destructiveStrong,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _sendPasswordReset(String email) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AuthProvider>().resetPassword(email);
      messenger.showSnackBar(
        SnackBar(content: Text("Link ganti password dikirim ke $email")),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text("Gagal mengirim email: $e"),
          backgroundColor: AppColors.destructiveStrong,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Keluar dari akun?"),
        content: const Text("Anda perlu login lagi untuk memakai aplikasi."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.destructive),
            child: const Text("Keluar"),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final navigator = Navigator.of(context);
    await context.read<AuthProvider>().logout();
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userModel;
    final name = user?.name ?? '';
    final email = user?.email ?? auth.user?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final roleLabel = switch (user?.role) {
      'admin' => "Admin (pemilik)",
      'staff' => "Staff",
      _ => "Belum disetujui",
    };
    final nameChanged =
        _nameController.text.trim().isNotEmpty && _nameController.text.trim() != name;

    return Scaffold(
      appBar: AppBar(title: const Text("Profil Saya")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.brandNavy,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandYellow,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name.isNotEmpty ? name : "Tanpa nama",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                "$email · $roleLabel",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.mutedForeground),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: "Nama yang tampil di aplikasi",
                  prefixIcon: Icon(LucideIcons.user, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: nameChanged && !_isSaving ? _saveName : null,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Simpan Nama"),
                ),
              ),
              const SizedBox(height: 32),
              Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(LucideIcons.lock),
                      title: const Text("Ganti password"),
                      subtitle: const Text("Link dikirim ke email Anda"),
                      trailing: const Icon(LucideIcons.chevronRight, size: 18),
                      onTap: email.isEmpty ? null : () => _sendPasswordReset(email),
                    ),
                    const Divider(indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(LucideIcons.logOut,
                          color: AppColors.destructiveStrong),
                      title: const Text(
                        "Keluar",
                        style: TextStyle(color: AppColors.destructiveStrong),
                      ),
                      onTap: _logout,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Nama toko, alamat, dan logo struk diatur di Setelan → Toko & Struk.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.mutedForeground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
