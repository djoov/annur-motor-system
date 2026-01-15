import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../ui/app_drawer.dart';
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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Pengguna"), elevation: 0),
      drawer: const AppDrawer(),
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
                    leading: CircleAvatar(
                      backgroundColor: isAdmin
                          ? AppColors.primary
                          : Colors.grey[300],
                      foregroundColor: isAdmin ? Colors.white : Colors.black,
                      child: Icon(
                        isAdmin ? LucideIcons.shield : LucideIcons.user,
                      ),
                    ),
                    title: Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
