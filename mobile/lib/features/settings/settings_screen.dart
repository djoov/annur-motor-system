import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_pos_printer_platform/flutter_pos_printer_platform.dart';
import '../../core/theme.dart';
import '../../ui/input.dart';
import '../../ui/button.dart';
import 'settings_provider.dart';
import '../auth/auth_provider.dart';

import '../../ui/desktop_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _shopNameController;
  late TextEditingController _shopAddressController;
  late TextEditingController _shopPhoneController;
  late TextEditingController _footerController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SettingsProvider>(context, listen: false);
    _shopNameController = TextEditingController(text: provider.shopName);
    _shopAddressController = TextEditingController(text: provider.shopAddress);
    _shopPhoneController = TextEditingController(text: provider.shopPhone);
    _footerController = TextEditingController(text: provider.receiptFooter);

    // Auto-scan if list is empty (optional)
    if (provider.devices.isEmpty) {
      provider.scanDevices();
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _shopPhoneController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use DesktopScaffold for desktop layout
    final isDesktop = DesktopScaffold.isDesktop;

    // For Desktop, we need to wrap the body or return DesktopScaffold.
    // However, SettingsScreen uses a DefaultTabController and AppBar.
    // DesktopScaffold doesn't support AppBar tabs nicely in its current form if we replace Scaffold.
    // BUT we can wrap the SCAFFOLD in DesktopScaffold if we want Sidebar + Scaffold (AppBar).
    // Or we can construct custom UI.

    // Best Approach for now:
    // Return DesktopScaffold, and put the Scaffold INSIDE the body?
    // Nested Scaffolds are okay-ish.

    // OR simpler: standard approach as per other screens:

    if (isDesktop) {
      return DesktopScaffold(
        activeRoute: '/settings',
        body: DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor:
                Colors.transparent, // Let DesktopScaffold bg show? Or white.
            appBar: AppBar(
              title: const Text(
                "Pengaturan",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              bottom: const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.mutedForeground,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: "Printer", icon: Icon(LucideIcons.printer)),
                  Tab(text: "Struk", icon: Icon(LucideIcons.receipt)),
                  Tab(text: "Akun", icon: Icon(LucideIcons.user)),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildPrinterTab(),
                _buildReceiptTab(),
                _buildAccountTab(),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            "Pengaturan",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.primary,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.mutedForeground,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: "Printer", icon: Icon(LucideIcons.printer)),
              Tab(text: "Struk", icon: Icon(LucideIcons.receipt)),
              Tab(text: "Akun", icon: Icon(LucideIcons.user)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPrinterTab(),
            _buildReceiptTab(),
            _buildAccountTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterTab() {
    return Consumer<SettingsProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            24,
            24,
            100,
          ), // Added bottom padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle("Koneksi Printer Bluetooth"),
              const SizedBox(height: 16),

              // Auto-Connect Active (Legacy Mode Forced)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.zap, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Mode Auto-Connect Aktif (Legacy)",
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.input),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: provider.isLoading
                              ? const Center(
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text("Mencari Printer..."),
                                    ],
                                  ),
                                )
                              : provider.devices.isEmpty
                              ? const Text(
                                  "Tidak ada printer ditemukan.\nPastikan Bluetooth NYALA & Refresh.",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                )
                              : DropdownButtonFormField<PrinterDevice>(
                                  isExpanded: true, // Prevent overflow
                                  decoration: InputDecoration(
                                    labelText: "Pilih Perangkat",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: provider.devices
                                      .map(
                                        (d) => DropdownMenuItem(
                                          value: d,
                                          child: Text(
                                            d.name ?? "Unknown Device",
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (device) {
                                    if (device != null) {
                                      provider.connect(device);
                                    }
                                  },
                                  value: provider.selectedDevice,
                                  hint: const Text("Pilih Printer Bluetooth"),
                                ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => provider.scanDevices(),
                          icon: const Icon(LucideIcons.refreshCcw),
                          tooltip: "Segarkan",
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          provider.isConnected
                              ? LucideIcons.checkCircle2
                              : LucideIcons.xCircle,
                          color: provider.isConnected
                              ? AppColors.success
                              : AppColors.destructive,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          provider.isConnected
                              ? "Terhubung"
                              : "Tidak Terhubung",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: provider.isConnected
                                ? AppColors.success
                                : AppColors.destructive,
                          ),
                        ),
                        const Spacer(),
                        if (provider.isConnected)
                          TextButton(
                            onPressed: () => provider.disconnect(),
                            child: const Text(
                              "Putuskan",
                              style: TextStyle(color: AppColors.destructive),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              CustomButton(
                text: "Test Print",
                icon: LucideIcons.printer,
                onPressed: provider.isConnected
                    ? () async {
                        final error = await provider.testPrint();
                        if (context.mounted) {
                          if (error == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Test Print Berhasil Dikirim"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    : null,
              ),

              const SizedBox(height: 24),
              const Text(
                "Pastikan Bluetooth menyala dan printer sudah di-pairing di pengaturan Bluetooth HP Anda.",
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptTab() {
    final provider = Provider.of<SettingsProvider>(context);

    // Sync controllers if provider updates external to editing (unlikely but good practice)
    if (_shopNameController.text != provider.shopName)
      _shopNameController.text = provider.shopName;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        100,
      ), // Added bottom padding
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle("Logo Struk"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.input),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: provider.customLogoFile != null
                            ? FileImage(provider.customLogoFile!)
                                  as ImageProvider
                            : const AssetImage('assets/icon/app_icon.png'),
                        fit: BoxFit.scaleDown,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomButton(
                          text: "Ganti Logo",
                          icon: LucideIcons.image,
                          onPressed: () => provider.pickLogo(),
                        ),
                        if (provider.customLogoFile != null) ...[
                          const SizedBox(height: 8),
                          CustomButton(
                            text: "Hapus Logo",
                            icon: LucideIcons.trash2,
                            isDestructive: true,
                            isOutline: true,
                            onPressed: () => provider.removeLogo(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle("Header Struk"),
            const SizedBox(height: 16),
            CustomInput(
              placeholder: "Nama Toko",
              controller: _shopNameController,
              suffixIcon: const Icon(LucideIcons.store, size: 18),
            ),
            const SizedBox(height: 12),
            CustomInput(
              placeholder: "Alamat Toko",
              controller: _shopAddressController,
              keyboardType: TextInputType.multiline,
              suffixIcon: const Icon(LucideIcons.mapPin, size: 18),
            ),
            const SizedBox(height: 12),
            CustomInput(
              placeholder: "Nomor Telepon",
              controller: _shopPhoneController,
              keyboardType: TextInputType.phone,
              suffixIcon: const Icon(LucideIcons.phone, size: 18),
            ),

            const SizedBox(height: 32),
            _buildSectionTitle("Footer Struk"),
            const SizedBox(height: 16),
            CustomInput(
              placeholder: "Pesan Bawah (Footer)",
              controller: _footerController,
              keyboardType: TextInputType.multiline,
              suffixIcon: const Icon(LucideIcons.messageSquare, size: 18),
            ),

            const SizedBox(height: 48),
            CustomButton(
              text: "Simpan Pengaturan",
              icon: LucideIcons.save,
              onPressed: () async {
                final adminName = provider.adminName;
                await provider.saveSettings(
                  _shopNameController.text,
                  _shopAddressController.text,
                  _shopPhoneController.text,
                  _footerController.text,
                  adminName,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Pengaturan Disimpan!")),
                  );
                }
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.userModel;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            24,
            24,
            100,
          ), // Added bottom padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle("Informasi Akun"),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.input),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        (user?.name ?? "U").substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? "Pengguna",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? "-",
                            style: const TextStyle(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              (user?.role ?? "Staff").toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: "Keluar Aplikasi",
                icon: LucideIcons.logOut,
                isDestructive: true,
                onPressed: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
              ),
              const SizedBox(height: 32),
              _buildSectionTitle("Zona Bahaya"),
              const SizedBox(height: 16),
              Consumer<SettingsProvider>(
                builder: (context, settingsProvider, child) {
                  return CustomButton(
                    text: "Reset Data Aplikasi",
                    icon: LucideIcons.trash2,
                    isDestructive: true,
                    isOutline: true,
                    onPressed: () =>
                        _showResetConfirmation(context, settingsProvider),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Data?"),
        content: const Text(
          "Ini akan menghapus SEMUA riwayat transaksi, laporan, hutang, dan notifikasi.\n\nData stok barang dan pelanggan TIDAK akan dihapus.\n\nTindakan ini tidak dapat dibatalkan.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await provider.resetData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Data berhasil di-reset."),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal reset data: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Hapus Semua",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
