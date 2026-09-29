import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme.dart';
import '../../ui/app_list.dart';
import '../../ui/app_form.dart';
import 'auth_provider.dart';
import 'user_provider.dart';
import 'user_model.dart';

/// Owner-only: approve new accounts, change roles, remove access.
class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });
  }

  static String _roleLabel(String role) => switch (role) {
        'admin' => "Admin",
        'staff' => "Staff",
        _ => "Nonaktif",
      };

  Future<void> _setRole(UserModel user, String role) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<UserProvider>().updateUserRole(user.id, role);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (role == 'pending'
                  ? "Akses ${user.name} dinonaktifkan"
                  : "${user.name} sekarang ${_roleLabel(role)}")
              : "Gagal mengubah akses ${user.name}",
        ),
        backgroundColor: ok ? null : AppColors.destructiveStrong,
      ),
    );
  }

  Future<void> _delete(UserModel user) async {
    final ok = await confirmDestructive(
      context,
      title: "Hapus pengguna?",
      message:
          "${user.name} tidak bisa lagi memakai aplikasi. Kalau login lagi, akunnya kembali menunggu persetujuan.",
    );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final success = await context.read<UserProvider>().deleteUser(user.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(success ? "${user.name} dihapus" : "Gagal menghapus"),
      ),
    );
  }

  void _showRoleSheet(UserModel user) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                "Akses ${user.name}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            for (final (role, desc) in const [
              ('admin', "Semua fitur, termasuk harga modal, laba, dan pengguna"),
              ('staff', "Kasir, produk, stok. Tanpa harga modal dan laba"),
              ('pending', "Tidak bisa memakai aplikasi"),
            ])
              ListTile(
                leading: Icon(
                  user.role == role
                      ? LucideIcons.circleCheck
                      : LucideIcons.circle,
                  color: user.role == role
                      ? AppColors.primary
                      : AppColors.mutedForeground,
                ),
                title: Text(_roleLabel(role)),
                subtitle: Text(desc),
                onTap: () {
                  Navigator.pop(ctx);
                  if (user.role != role) _setRole(user, role);
                },
              ),
            const Divider(indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(LucideIcons.trash2,
                  color: AppColors.destructiveStrong),
              title: const Text(
                "Hapus pengguna",
                style: TextStyle(color: AppColors.destructiveStrong),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _delete(user);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showActivity(UserModel user) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              Text(
                "${user.email} · ${_roleLabel(user.role)}",
                style: const TextStyle(fontSize: 14, color: AppColors.mutedForeground),
              ),
              const SizedBox(height: 16),
              _InfoRow("Status", user.isOnline ? "Sedang online" : "Offline"),
              _InfoRow("Terakhir aktif", user.lastSeenText),
              if (user.isOnline) _InfoRow("Lama sesi", user.sessionDurationText),
              _InfoRow("Perangkat", user.deviceInfo ?? "Tidak diketahui"),
              _InfoRow("Lokasi terakhir", user.lastLocation ?? "Tidak diketahui"),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final myId = context.watch<AuthProvider>().user?.uid;
    final users = provider.users;

    final pending =
        users.where((u) => u.role != 'admin' && u.role != 'staff').toList();
    final active =
        users.where((u) => u.role == 'admin' || u.role == 'staff').toList()
          ..sort((a, b) {
            if (a.role != b.role) return a.role == 'admin' ? -1 : 1;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Pengguna")),
      body: provider.isLoading && users.isEmpty
          ? const Center(child: CircularProgressIndicator.adaptive())
          : RefreshIndicator(
              onRefresh: provider.fetchUsers,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  if (pending.isNotEmpty) ...[
                    Text(
                      "Menunggu persetujuan (${pending.length})",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final u in pending)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _PendingCard(
                          user: u,
                          onApprove: () => _setRole(u, 'staff'),
                          onReject: () => _delete(u),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    "Pengguna aktif (${active.length})",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: AppColors.surface,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < active.length; i++) ...[
                          if (i > 0) const Divider(indent: 72, endIndent: 16),
                          _UserRow(
                            user: active[i],
                            isMe: active[i].id == myId,
                            roleLabel: _roleLabel(active[i].role),
                            onTap: () => _showActivity(active[i]),
                            // You can't lock yourself out
                            onManage: active[i].id == myId
                                ? null
                                : () => _showRoleSheet(active[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.info,
                          size: 18, color: AppColors.mutedForeground),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Karyawan baru mendaftar sendiri lewat \"Daftar akun\" di halaman masuk, lalu muncul di sini untuk disetujui.",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedForeground,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingCard({
    required this.user,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InitialAvatar(user.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.destructiveStrong,
                  ),
                  child: const Text("Tolak"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onApprove,
                  child: const Text("Setujui sebagai Staff"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final UserModel user;
  final bool isMe;
  final String roleLabel;
  final VoidCallback onTap;
  final VoidCallback? onManage;

  const _UserRow({
    required this.user,
    required this.isMe,
    required this.roleLabel,
    required this.onTap,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 16, right: 4, top: 4, bottom: 4),
      onTap: onTap,
      leading: Stack(
        children: [
          InitialAvatar(user.name),
          if (user.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        isMe ? "${user.name} (Anda)" : user.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text("$roleLabel · ${user.lastSeenText}"),
      trailing: onManage == null
          ? null
          : IconButton(
              tooltip: "Ubah akses",
              icon: const Icon(LucideIcons.ellipsisVertical),
              onPressed: onManage,
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.mutedForeground),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
