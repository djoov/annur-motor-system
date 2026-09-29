import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_pos_printer_platform/flutter_pos_printer_platform.dart';
import 'package:intl/intl.dart';

import 'settings_provider.dart';
import '../auth/auth_provider.dart';
import '../../ui/desktop_scaffold.dart';
import '../../ui/bottom_nav_metrics.dart';

import '../../core/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late TextEditingController _shopNameController;
  late TextEditingController _adminNameController;
  late TextEditingController _shopAddressController;
  late TextEditingController _shopPhoneController;
  late TextEditingController _footerController;

  /// Fill the text fields from the provider once its async load finishes,
  /// then leave them alone so typing isn't overwritten on rebuild.
  bool _syncedFromProvider = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final provider = Provider.of<SettingsProvider>(context, listen: false);
    _shopNameController = TextEditingController(text: provider.shopName);
    _adminNameController = TextEditingController(text: provider.adminName);
    _shopAddressController = TextEditingController(text: provider.shopAddress);
    _shopPhoneController = TextEditingController(text: provider.shopPhone);
    _footerController = TextEditingController(text: provider.receiptFooter);
    _syncedFromProvider = provider.shopName.isNotEmpty;

    // Live receipt preview
    for (final c in [
      _shopNameController,
      _shopAddressController,
      _shopPhoneController,
      _footerController,
    ]) {
      c.addListener(_onTextChanged);
    }

    if (provider.devices.isEmpty) {
      provider.scanDevices();
    }
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _tabController.dispose();
    _shopNameController.dispose();
    _adminNameController.dispose();
    _shopAddressController.dispose();
    _shopPhoneController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  double _bottomSpace(BuildContext context) => DesktopScaffold.isDesktop
      ? 32
      : BottomNavMetrics.top(context) + 16;

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      appBar: AppBar(
        title: const Text("Setelan"),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Printer"),
            Tab(text: "Toko & Struk"),
            Tab(text: "Akun"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPrinterTab(),
          _buildReceiptTab(),
          _buildAccountTab(),
        ],
      ),
    );

    if (DesktopScaffold.isDesktop) {
      return DesktopScaffold(activeRoute: '/settings', body: content);
    }
    return content;
  }

  // =========================================================================
  // TAB 1: PRINTER
  // =========================================================================
  Widget _buildPrinterTab() {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        final connected = provider.isConnected;

        return _TabBody(
          bottomSpace: _bottomSpace(context),
          children: [
            // Status
            _Panel(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: connected
                          ? AppColors.successSoft
                          : AppColors.muted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      connected ? LucideIcons.printerCheck : LucideIcons.printer,
                      color: connected
                          ? AppColors.successStrong
                          : AppColors.mutedForeground,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          connected ? "Printer terhubung" : "Belum terhubung",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: connected
                                ? AppColors.successStrong
                                : AppColors.foreground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          connected
                              ? (provider.selectedDevice?.name ??
                                  "Printer Bluetooth")
                              : "Pilih printer di bawah.",
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (connected)
                    TextButton(
                      onPressed: provider.disconnect,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.destructiveStrong,
                      ),
                      child: const Text("Putuskan"),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle("Pilih printer"),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: provider.isLoading
                      ? const _Panel(
                          child: Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text(
                                "Mencari printer Bluetooth...",
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : provider.devices.isEmpty
                          ? const _Panel(
                              child: Text(
                                "Tidak ada printer ditemukan. Nyalakan Bluetooth dan pasangkan printer di pengaturan Bluetooth HP, lalu tekan Cari ulang.",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.mutedForeground,
                                  height: 1.4,
                                ),
                              ),
                            )
                          : DropdownButtonFormField<PrinterDevice>(
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: "Printer kasir",
                                prefixIcon: Icon(LucideIcons.printer, size: 20),
                              ),
                              items: [
                                for (final d in provider.devices)
                                  DropdownMenuItem(
                                    value: d,
                                    child: Text(
                                      d.name?.isNotEmpty == true
                                          ? d.name!
                                          : "Perangkat ${d.address}",
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (device) {
                                if (device != null) provider.connect(device);
                              },
                              initialValue: provider.selectedDevice,
                              hint: const Text("Pilih printer"),
                            ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56,
                  height: 56,
                  child: IconButton.outlined(
                    onPressed: provider.isLoading ? null : provider.scanDevices,
                    tooltip: "Cari ulang",
                    style: IconButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(LucideIcons.refreshCw, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: connected
                    ? () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final error = await provider.testPrint();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              error == null
                                  ? "Tes cetak terkirim ke printer"
                                  : "Gagal cetak: $error",
                            ),
                            backgroundColor: error == null
                                ? null
                                : AppColors.destructiveStrong,
                          ),
                        );
                      }
                    : null,
                icon: const Icon(LucideIcons.printer, size: 20),
                label: const Text("Tes Cetak"),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle("Tips"),
            const _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Tip("Pasangkan (pairing) printer dulu di pengaturan Bluetooth HP. PIN biasanya 0000 atau 1234."),
                  _Tip("Mendukung printer thermal Bluetooth 58 mm dan 80 mm."),
                  _Tip("Logo dan catatan kaki dari tab Toko & Struk ikut tercetak."),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // TAB 2: TOKO & STRUK
  // =========================================================================
  Widget _buildReceiptTab() {
    final provider = Provider.of<SettingsProvider>(context);

    if (!_syncedFromProvider && provider.shopName.isNotEmpty) {
      _syncedFromProvider = true;
      _shopNameController.text = provider.shopName;
      _adminNameController.text = provider.adminName;
      _shopAddressController.text = provider.shopAddress;
      _shopPhoneController.text = provider.shopPhone;
      _footerController.text = provider.receiptFooter;
    }

    return _TabBody(
      bottomSpace: _bottomSpace(context),
      children: [
        const _SectionTitle("Logo di struk"),
        _Panel(
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: provider.customLogoFile != null
                        ? FileImage(provider.customLogoFile!) as ImageProvider
                        : const AssetImage('assets/icon/app_icon.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "PNG atau JPG. Otomatis diubah hitam-putih untuk printer.",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: provider.pickLogo,
                          child: const Text("Ganti logo"),
                        ),
                        if (provider.customLogoFile != null)
                          TextButton(
                            onPressed: provider.removeLogo,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.destructiveStrong,
                            ),
                            child: const Text("Hapus"),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle("Data toko"),
        _field(
          label: "Nama toko",
          controller: _shopNameController,
          icon: LucideIcons.store,
        ),
        _field(
          label: "Nama pemilik / penanggung jawab",
          controller: _adminNameController,
          icon: LucideIcons.user,
        ),
        _field(
          label: "Alamat",
          controller: _shopAddressController,
          icon: LucideIcons.mapPin,
          maxLines: 2,
        ),
        _field(
          label: "Telepon / WhatsApp",
          controller: _shopPhoneController,
          icon: LucideIcons.phone,
          keyboardType: TextInputType.phone,
        ),
        _field(
          label: "Catatan kaki struk",
          controller: _footerController,
          icon: LucideIcons.receipt,
          maxLines: 2,
          helperText: "Contoh: Barang yang sudah dibeli tidak dapat ditukar",
        ),
        const SizedBox(height: 8),
        const _SectionTitle("Contoh struk"),
        _ReceiptPreview(
          shopName: _shopNameController.text,
          shopAddress: _shopAddressController.text,
          shopPhone: _shopPhoneController.text,
          footer: _footerController.text,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _isSaving ? null : () => _saveShop(provider),
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.save, size: 20),
            label: Text(_isSaving ? "Menyimpan..." : "Simpan Data Toko"),
          ),
        ),
      ],
    );
  }

  Future<void> _saveShop(SettingsProvider provider) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);
    try {
      await provider.saveSettings(
        _shopNameController.text.trim(),
        _shopAddressController.text.trim(),
        _shopPhoneController.text.trim(),
        _footerController.text.trim(),
        _adminNameController.text.trim(),
      );
      messenger.showSnackBar(
        const SnackBar(content: Text("Data toko tersimpan")),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text("Gagal menyimpan: $e"),
          backgroundColor: AppColors.destructiveStrong,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textInputAction:
            maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          helperText: helperText,
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 3: AKUN
  // =========================================================================
  Widget _buildAccountTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.userModel;
        final name = user?.name ?? "Pengguna";
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
        final roleLabel = switch (user?.role) {
          'admin' => "Admin",
          'staff' => "Staff",
          _ => "Belum disetujui",
        };

        return _TabBody(
          bottomSpace: _bottomSpace(context),
          children: [
            _Panel(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.brandNavy,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandYellow,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (user?.email != null)
                          Text(
                            user!.email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            roleLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context, authProvider),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.destructiveStrong,
                  side: const BorderSide(color: AppColors.destructiveBorder),
                ),
                icon: const Icon(LucideIcons.logOut, size: 20),
                label: const Text("Keluar"),
              ),
            ),
            if (authProvider.isAdmin) ...[
              const SizedBox(height: 32),
              const _SectionTitle("Zona bahaya"),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.destructiveSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.destructiveBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Reset riwayat transaksi",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.destructiveStrong,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Menghapus semua transaksi, hutang, dan retur secara permanen. Data barang dan pelanggan tetap aman.",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.destructiveStrong,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<SettingsProvider>(
                      builder: (context, settingsProvider, _) => FilledButton.icon(
                        onPressed: () =>
                            _showResetConfirmation(context, settingsProvider),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.destructive,
                        ),
                        icon: const Icon(LucideIcons.trash2, size: 18),
                        label: const Text("Reset Data Transaksi"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            const Center(
              child: Text(
                "Annur App · versi 1.0.0",
                style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Keluar dari akun?"),
        content: const Text("Anda perlu login lagi untuk memakai aplikasi."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
            child: const Text("Keluar"),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, SettingsProvider provider) {
    final textCtrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final confirmed = textCtrl.text.trim().toUpperCase() == "RESET";
          return AlertDialog(
            title: const Text("Reset data transaksi?"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Semua riwayat penjualan, hutang, dan retur akan dihapus permanen. Barang dan pelanggan tidak dihapus.\n\nKetik RESET untuk melanjutkan:",
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(hintText: "RESET"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Batal"),
              ),
              FilledButton(
                onPressed: confirmed
                    ? () async {
                        Navigator.pop(ctx);
                        try {
                          await provider.resetData();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text("Data transaksi sudah direset"),
                            ),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text("Reset gagal: $e"),
                              backgroundColor: AppColors.destructiveStrong,
                            ),
                          );
                        }
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.destructive,
                ),
                child: const Text("Hapus Permanen"),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ===========================================================================
// Building blocks
// ===========================================================================

class _TabBody extends StatelessWidget {
  final List<Widget> children;
  final double bottomSpace;

  const _TabBody({required this.children, required this.bottomSpace});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 20, 16, bottomSpace),
          children: children,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _Tip extends StatelessWidget {
  final String text;

  const _Tip(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(LucideIcons.check, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paper-like sample receipt that updates as the shop fields are typed.
class _ReceiptPreview extends StatelessWidget {
  final String shopName;
  final String shopAddress;
  final String shopPhone;
  final String footer;

  const _ReceiptPreview({
    required this.shopName,
    required this.shopAddress,
    required this.shopPhone,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    const mono = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      color: Colors.black87,
    );
    const line = Text("--------------------------------",
        style: TextStyle(fontFamily: 'monospace', color: Colors.black45));
    final now = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    Widget row(String l, String r, {bool bold = false}) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l, style: bold ? mono.copyWith(fontWeight: FontWeight.bold) : mono),
            Text(r, style: bold ? mono.copyWith(fontWeight: FontWeight.bold) : mono),
          ],
        );

    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              shopName.isNotEmpty ? shopName.toUpperCase() : "NAMA TOKO",
              style: mono.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (shopAddress.isNotEmpty)
              Text(shopAddress, style: mono, textAlign: TextAlign.center),
            if (shopPhone.isNotEmpty)
              Text("Telp: $shopPhone", style: mono, textAlign: TextAlign.center),
            line,
            row("No. 1A2B3C4D", now),
            line,
            row("1x Oli MPX2 0.8L", "Rp 55.000"),
            row("1x Kampas Rem Depan", "Rp 35.000"),
            line,
            row("TOTAL", "Rp 90.000", bold: true),
            line,
            Text(
              footer.isNotEmpty ? footer : "Terima kasih!",
              style: mono,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
