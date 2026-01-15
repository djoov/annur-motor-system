import 'dart:typed_data';
import 'dart:io'; // added

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart'; // added

import '../../core/theme.dart';
import '../../ui/button.dart';
import '../settings/settings_provider.dart';
import 'pos_provider.dart';
import '../debts/debt_provider.dart';

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
        title: const Text("Struk Transaksi"),
        centerTitle: true,
        automaticallyImplyLeading: false, // Prevent back button
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.download, color: Colors.black),
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
                          color: Colors.black.withOpacity(0.05),
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
                                color: AppColors.primary,
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
                  // DRAFT MODE (CONFIRMATION)
                  // 1. Process & Print
                  CustomButton(
                    text: "Proses & Cetak",
                    icon: LucideIcons.printer,
                    isLoading: settings.isLoading,
                    onPressed: () async {
                      await _finalizeAndAction(context, settings, print: true);
                    },
                  ),
                  const SizedBox(height: 12),
                  // 2. Process Only
                  CustomButton(
                    text: "Selesai (Tanpa Cetak)",
                    icon: LucideIcons.checkCircle,
                    color: Colors.green,
                    isLoading: settings.isLoading,
                    onPressed: () async {
                      await _finalizeAndAction(context, settings, print: false);
                    },
                  ),
                  const SizedBox(height: 12),
                  // 3. Cancel
                  CustomButton(
                    text: "Batal / Kembali",
                    isOutline: true,
                    color: Colors.red,
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pop(); // Just go back, cart is intact
                    },
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
                    text: "Simpan Gambar",
                    icon: LucideIcons.image,
                    color: Colors.green,
                    isLoading: _isSaving,
                    onPressed: () => _saveToGallery(context),
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: "Tutup",
                    isOutline: true,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
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
    final posProvider = Provider.of<PosProvider>(context, listen: false);

    try {
      // 1. Finalize (Write DB)
      await posProvider.finalizeTransaction(widget.transactionData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // 2. Handle Debt (If applicable)
    // We check the draft data's payment method
    final paymentMethod = widget.transactionData['paymentMethod'];
    if (paymentMethod == 'debt' && mounted) {
      try {
        await Provider.of<DebtProvider>(context, listen: false).createDebt(
          customerId: widget.transactionData['customerId'],
          customerName: widget.transactionData['customerName'],
          transactionId: widget.transactionData['id'],
          amount: widget.transactionData['totalAmount'],
        );
      } catch (e) {
        // Just show error, transaction itself is already saved
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Hutang Gagal Dicatat: $e")));
        }
      }
    }

    // 3. Print (If requested)
    if (print && mounted) {
      await settings.printTransaction(
        widget.transactionData['id'],
        widget.transactionData['customerName'],
        widget.transactionData['items'],
        widget.transactionData['totalAmount'],
      );
    }

    // 4. Finish
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

        final String? outputFile = await FilePicker.platform.saveFile(
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
                backgroundColor: Colors.green,
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
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print("Error saving image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
