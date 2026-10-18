import 'dart:typed_data';
import 'dart:io'; // added

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart'; // added

import '../../core/theme.dart';
import '../../ui/button.dart';
import '../settings/settings_provider.dart';
import 'pos_provider.dart';
import 'widgets/pos_widgets.dart' show posRupiah;

class ReceiptPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> transactionData;
  final bool isDraft; // New Parameter

  const ReceiptPreviewScreen({
    super.key,
    required this.transactionData,
    this.isDraft = false, // Default to false (History Mode)
  });

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSaving = false;

  /// True while the transaction is being written — locks all buttons so a
  /// double tap can't record the sale twice.
  bool _isFinalizing = false;

  static String _paymentLabel(String? method) {
    switch (method) {
      case 'cash':
        return 'Tunai';
      case 'transfer':
        return 'Transfer';
      case 'debt':
        return 'Hutang';
      default:
        return method ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    // Extract Data
    final items = widget.transactionData['items'] as List<dynamic>;
    final totalAmount = widget.transactionData['totalAmount'] as int;
    final customerName = widget.transactionData['customerName'] as String;
    final transactionId = widget.transactionData['id'] as String;
    final date = DateTime.now(); // or parse timestamp if available

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isDraft ? "Konfirmasi Transaksi" : "Struk Transaksi"),
        automaticallyImplyLeading: !widget.isDraft,
        actions: [
          if (!widget.isDraft)
            IconButton(
              icon: const Icon(LucideIcons.download),
              tooltip: 'Simpan ke Galeri',
              onPressed: () => _saveToGallery(context),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Receipt Card (Wrapped in Screenshot)
                Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Shop Logo
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            height: 100, // Increased size
                            width: 100, // Increased size
                            child: settings.customLogoFile != null
                                ? Image.file(
                                    settings.customLogoFile!,
                                    fit: BoxFit.contain,
                                  )
                                : Image.asset(
                                    'assets/icon/app_icon.png',
                                    fit: BoxFit.contain,
                                  ),
                          ),
                        ),

                        // Shop Header
                        Text(
                          settings.shopName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors
                                .black, // Explicit color for image capture
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          settings.shopAddress,
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          settings.shopPhone,
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Info
                        _buildInfoRow("Tanggal", dateFormat.format(date)),
                        const SizedBox(height: 8),
                        _buildInfoRow("Pelanggan", customerName),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          "Pembayaran",
                          _paymentLabel(
                            widget.transactionData['paymentMethod'] as String?,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          "No. Transaksi",
                          transactionId.substring(0, 8),
                        ),

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Items
                        ...items.map((item) {
                          final int qty = item['quantity'];
                          final int price = item['sellPrice'];
                          final int total = qty * price;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['itemName'] ?? item['name'] ?? '-',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        "$qty x ${currencyFormat.format(price)}",
                                        style: const TextStyle(
                                          color: AppColors.mutedForeground,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(total),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "TOTAL",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              currencyFormat.format(totalAmount),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        Text(
                          settings.receiptFooter,
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Actions
                if (widget.isDraft) ...[
                  // DRAFT MODE (CONFIRMATION) — nothing is saved until one of
                  // the first two buttons is pressed.
                  CustomButton(
                    text: "Simpan & Cetak Struk",
                    icon: LucideIcons.printer,
                    isLoading: _isFinalizing || settings.isLoading,
                    onPressed: () =>
                        _finalizeAndAction(context, settings, print: true),
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: "Simpan tanpa Cetak",
                    icon: LucideIcons.circleCheck,
                    isOutline: true,
                    onPressed: _isFinalizing || settings.isLoading
                        ? null
                        : () => _finalizeAndAction(
                              context,
                              settings,
                              print: false,
                            ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isFinalizing
                        ? null
                        : () => Navigator.of(context).pop(), // cart is intact
                    child: const Text("Kembali ke Keranjang"),
                  ),
                ] else ...[
                  // HISTORY / COMPLETED MODE
                  CustomButton(
                    text: "Cetak Struk",
                    icon: LucideIcons.printer,
                    isLoading: settings.isLoading,
                    onPressed: () async {
                      await settings.printTransaction(
                        transactionId,
                        customerName,
                        items,
                        totalAmount,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: "Simpan Gambar Struk",
                    icon: LucideIcons.image,
                    isOutline: true,
                    isLoading: _isSaving,
                    onPressed: () => _saveToGallery(context),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Tutup"),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.mutedForeground)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Future<void> _finalizeAndAction(
    BuildContext context,
    SettingsProvider settings, {
    required bool print,
  }) async {
    if (_isFinalizing) return;
    setState(() => _isFinalizing = true);

    final posProvider = Provider.of<PosProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // 1. Finalize (Write DB)
      await posProvider.finalizeTransaction(widget.transactionData);
    } catch (e) {
      if (mounted) {
        setState(() => _isFinalizing = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              "Transaksi gagal disimpan: ${e.toString().replaceFirst('Exception: ', '')}",
            ),
            backgroundColor: AppColors.destructiveStrong,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // 2. A debt sale's debt is recorded inside finalizeTransaction.

    // 3. Print (If requested)
    if (print && mounted) {
      await settings.printTransaction(
        widget.transactionData['id'],
        widget.transactionData['customerName'],
        widget.transactionData['items'],
        widget.transactionData['totalAmount'],
      );
    }

    // 4. Finish — the messenger outlives this route, so the message stays
    // visible on the POS screen after we close the preview.
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          "Transaksi ${posRupiah.format(widget.transactionData['totalAmount'] as int)} tersimpan",
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    if (mounted) {
      Navigator.of(context).pop(); // Close Preview
    }
  }

  Future<void> _saveToGallery(BuildContext context) async {
    setState(() => _isSaving = true);

    try {
      // Capture Image
      final Uint8List? image = await _screenshotController.capture(
        delay: const Duration(milliseconds: 10),
        pixelRatio: 2.0, // High quality
      );

      if (image == null) return;

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop Saving Logic
        final String fileName =
            "Struk_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.png";

        final String? outputFile = await FilePicker.saveFile(
          dialogTitle: 'Simpan Struk ke...',
          fileName: fileName,
          type: FileType.image,
        );

        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsBytes(image);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Struk disimpan di: $outputFile"),
                backgroundColor: AppColors.success,
                action: SnackBarAction(
                  label: 'Buka',
                  textColor: Colors.white,
                  onPressed: () {
                    // Open file if possible, or folder
                    // For now just nice feedback
                  },
                ),
              ),
            );
          }
        }
      } else {
        // Mobile Saving Logic (Gallery)
        // 1. Check Permissions
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          // Android 13+ usually doesn't need this for add-only, but good practice for older
          if (await Permission.storage.request().isDenied) {
            // Try generic photos if denied or specific versions?
            // Just proceed for now, Gal handles some internally
          }
        }

        // 3. Save to Gallery using Gal
        await Gal.putImageBytes(
          image,
          name: "Struk_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}",
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Berhasil disimpan ke Galeri"),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      print("Error saving image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: $e"), backgroundColor: AppColors.destructive),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
