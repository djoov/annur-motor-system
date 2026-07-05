import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme.dart';

import 'user_provider.dart';
import 'user_model.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({Key? key}) : super(key: key);

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
    });
  }

  void _showRoleDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Ubah Role: ${user.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Admin"),
              leading: Radio<String>(
                value: "admin",
                groupValue: user.role,
                onChanged: (val) {
                  Navigator.pop(context);
                  _updateRole(user, val!);
                },
              ),
            ),
            ListTile(
              title: const Text("Staff"),
              leading: Radio<String>(
                value: "staff",
                groupValue: user.role,
                onChanged: (val) {
                  Navigator.pop(context);
                  _updateRole(user, val!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateRole(UserModel user, String newRole) async {
    final success = await Provider.of<UserProvider>(
      context,
      listen: false,
    ).updateUserRole(user.id, newRole);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Role ${user.name} diubah menjadi $newRole")),
      );
    }
  }

  void _confirmDelete(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus User?"),
        content: Text(
          "Yakin ingin menghapus akses ${user.name}? User tidak akan bisa login lagi.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await Provider.of<UserProvider>(
                context,
                listen: false,
              ).deleteUser(user.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("User berhasil dihapus")),
                );
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showUserDetail(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // User header
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: user.role == 'admin'
                          ? AppColors.primary
                          : Colors.grey[300],
                      foregroundColor: user.role == 'admin'
                          ? Colors.white
                          : Colors.black,
                      child: Icon(
                        user.role == 'admin'
                            ? LucideIcons.shield
                            : LucideIcons.user,
                        size: 28,
                      ),
                    ),
                    if (user.isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: user.role == 'admin'
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: TextStyle(
                            color: user.role == 'admin'
                                ? AppColors.primary
                                : Colors.grey[700],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Activity info
            const Text(
              "Informasi Aktivitas",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildInfoRow(
              icon: user.isOnline ? LucideIcons.wifi : LucideIcons.wifiOff,
              label: "Status",
              value: user.isOnline ? "Online Sekarang" : "Offline",
              valueColor: user.isOnline ? Colors.green : Colors.grey,
            ),

            _buildInfoRow(
              icon: LucideIcons.clock,
              label: "Terakhir Aktif",
              value: user.lastSeenText,
            ),

            if (user.isOnline)
              _buildInfoRow(
                icon: LucideIcons.timer,
                label: "Durasi Sesi",
                value: user.sessionDurationText,
              ),

            _buildInfoRow(
              icon: LucideIcons.smartphone,
              label: "Perangkat",
              value: user.deviceInfo ?? "Tidak diketahui",
            ),

            _buildInfoRow(
              icon: LucideIcons.laptop,
              label: "Platform",
              value: user.devicePlatform ?? "Tidak diketahui",
            ),

            _buildInfoRow(
              icon: LucideIcons.mapPin,
              label: "Lokasi",
              value: user.lastLocation ?? "Tidak diketahui",
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Pengguna"), elevation: 0),
      backgroundColor: AppColors.background,
      body: userProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: userProvider.users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final user = userProvider.users[index];
                final isAdmin = user.role == 'admin';

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    onTap: () => _showUserDetail(user),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: isAdmin
                              ? AppColors.primary
                              : Colors.grey[300],
                          foregroundColor: isAdmin
                              ? Colors.white
                              : Colors.black,
                          child: Icon(
                            isAdmin ? LucideIcons.shield : LucideIcons.user,
                          ),
                        ),
                        // Online indicator
                        if (user.isOnline)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (user.isOnline) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "Online",
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text("${user.email}\nRole: ${user.role}"),
                    isThreeLine: true,
                    trailing: PopupMenuButton(
                      icon: const Icon(LucideIcons.moreVertical),
                      onSelected: (value) {
                        if (value == 'role') {
                          _showRoleDialog(user);
                        } else if (value == 'delete') {
                          _confirmDelete(user);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'role',
                          child: Row(
                            children: [
                              Icon(LucideIcons.shield, size: 18),
                              SizedBox(width: 8),
                              Text("Ubah Role"),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.trash2,
                                size: 18,
                                color: Colors.red,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Hapus User",
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Untuk menambah user, minta user Register di halaman Login.",
              ),
            ),
          );
        },
        label: const Text("Tambah User"),
        icon: const Icon(LucideIcons.plus),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
