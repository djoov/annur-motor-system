import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import '../../ui/button.dart';

import 'items_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/export_service.dart';

class BulkImportScreen extends StatefulWidget {
  const BulkImportScreen({Key? key}) : super(key: key);

  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  bool _isRestockMode = true; // Default: Restock (Safe)

  // Updated Format to match Export Service Exact Headers
  final List<String> _headers = [
    "KODE",
    "NAMA BARANG",
    "HARGA BELI",
    "HARGA JUAL (UMUM)",
    "HARGA JUAL (BENGKEL)",
    "STOK TOKO",
    "STOK GUDANG",
    "TAGS",
    "KATEGORI",
    "LOKASI TOKO",
    "LOKASI GUDANG",
  ];

  final String _exampleData =
      "OLI001,Oli MPX 1,50000,65000,60000,10,50,\"oli,honda,matic\",Oli,A1-05,G-01\nBAN001,Ban IRC 80/90,150000,180000,175000,5,20,\"ban,irc,tubetype\",Sparepart,B2-10,G-02";

  Future<void> _downloadTemplate() async {
    try {
      setState(() => _isLoading = true);

      final List<List<dynamic>> exampleRow = [
        [
          "CONTOH001",
          "Contoh Barang",
          10000,
          15000,
          14000,
          10,
          5,
          "tag1,tag2",
          "Umum",
          "A1-01",
          "G-01",
        ],
      ];

      await ExportService.exportToCSV(
        headers: _headers,
        data: exampleRow,
        fileName: "template_import_barang.csv",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Template berhasil diproses.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal download template: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        setState(() => _isLoading = true);
        final file = File(result.files.single.path!);
        final input = await file.readAsString();

        // Parse CSV just to preview text or populate controller
        // We put raw text into controller so user can edit before processing if needed
        // Or we can parse immediately. Let's put in controller for transparency.

        // However, standard CSV parsers handle quotes/commas better than simple text split.
        // So let's convert the parsed LIST back to a clean string format for the text area?
        // Or just show raw content.

        // Better: Process directly but allow viewing.
        // For simplicity with existing logic: Fill text controller with raw content.
        // But if CSV has standard formatting (quotes etc), our manual parser below needs to be smart.
        // Let's use the CSV package to parse, then re-format it for the text controller display
        // so the user knows what we read.

        final fields = const CsvToListConverter().convert(input, eol: '\n');

        // Filter out header if present (heuristic: check if first row is header)
        int startRow = 0;
        if (fields.isNotEmpty &&
            fields[0][0].toString().toLowerCase() == 'kode') {
          startRow = 1;
        }

        StringBuffer sb = StringBuffer();
        for (int i = startRow; i < fields.length; i++) {
          // Re-construct line
          final row = fields[i];
          if (row is List) {
            sb.writeln(row.join(','));
          } else if (row != null) {
            sb.writeln(row.toString());
          }
        }

        _textController.text = sb.toString();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Berhasil memuat ${fields.length - startRow} baris data.",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal baca file: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processImport() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mohon masukkan data / upload file terlebih dahulu"),
        ),
      );
      return;
    }

    // Use CsvToListConverter for robust parsing (handles quotes in tags etc)
    // We add a dummy new line if needed? No converter handles string.
    List<List<dynamic>> rows;
    try {
      rows = const CsvToListConverter().convert(text, eol: '\n');
    } catch (e) {
      // Fallback manual split if CSV parser fails
      rows = [];
      final lines = text.split('\n');
      for (var line in lines) rows.add(line.split(','));
    }

    final List<Map<String, dynamic>> itemsToImport = [];

    for (var row in rows) {
      // Row must have at least Code, Name, Prices
      if (row.length >= 4) {
        // Mapping index based on new SRS structure
        // 0: Code, 1: Name, 2: Buy, 3: Sell, 4: Workshop, 5: StockDisplay, 6: StockWarehouse, 7: Tags, 8: Category
        // Flexible handling: If row shorter, use defaults.

        final getVal = (int index) =>
            index < row.length ? row[index].toString().trim() : '';

        // Safely parse int
        int safeInt(dynamic val) {
          if (val is int) return val;
          if (val is double) return val.toInt();
          return int.tryParse(
                val.toString().replaceAll(RegExp(r'[^0-9]'), ''),
              ) ??
              0;
        }

        final code = getVal(0);
        if (code.isEmpty) continue; // Skip empty lines

        itemsToImport.add({
          'code': code,
          'name': getVal(1),
          'buyPrice': safeInt(row.length > 2 ? row[2] : 0),
          'sellPrice': safeInt(row.length > 3 ? row[3] : 0),
          'price_workshop': safeInt(row.length > 4 ? row[4] : 0),
          'qty_display': safeInt(row.length > 5 ? row[5] : 0),
          'qty_warehouse': safeInt(row.length > 6 ? row[6] : 0),
          'tags': getVal(
            7,
          ).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          'category': getVal(8).isEmpty ? 'Umum' : getVal(8),
          'location_display': row.length > 9 ? getVal(9) : '',
          'location_warehouse': row.length > 10 ? getVal(10) : '',
        });
      }
    }

    if (itemsToImport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada data valid yang ditemukan.")),
      );
      return;
    }

    final summary = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Import"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Akan memproses ${itemsToImport.length} data."),
              const SizedBox(height: 8),
              const Text(
                "Data Sampel Pertama:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "${itemsToImport.first['name']} (${itemsToImport.first['code']})",
              ),
              Text("Harga Jual: ${itemsToImport.first['sellPrice']}"),
              Text("Stok Display: ${itemsToImport.first['qty_display']}"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Proses"),
          ),
        ],
      ),
    );

    if (summary == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final result = await Provider.of<ItemsProvider>(
          context,
          listen: false,
        ).bulkUpsertItems(itemsToImport, isRestockMode: _isRestockMode);

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Import Selesai"),
              content: Text(
                "Sukses!\n${result['created']} Barang Baru.\n${result['updated']} Barang Diupdate.",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close Alert
                    Navigator.pop(context); // Close Screen
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Import Barang Masal")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // --- Content Card ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mode Selection
                  const Text(
                    "Pilih Mode Import:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text("Tambah Stok (Restock)"),
                          subtitle: const Text(
                            "Menambahkan jumlah stok baru ke stok lama.",
                            style: TextStyle(fontSize: 11),
                          ),
                          value: true,
                          groupValue: _isRestockMode,
                          onChanged: (val) =>
                              setState(() => _isRestockMode = val!),
                          contentPadding: EdgeInsets.zero,
                          activeColor: Colors.green,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text("Update Data (Overwrite)"),
                          subtitle: const Text(
                            "Timpa data lama dengan data CSV (Stok, Harga, dll diganti).",
                            style: TextStyle(fontSize: 11),
                          ),
                          value: false,
                          groupValue: _isRestockMode,
                          onChanged: (val) =>
                              setState(() => _isRestockMode = val!),
                          contentPadding: EdgeInsets.zero,
                          activeColor: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: "Download Template",
                          icon: LucideIcons.download,
                          isOutline: true,
                          onPressed: _downloadTemplate,
                          isLoading: _isLoading,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: "Pilih File CSV",
                          icon: LucideIcons.upload,
                          onPressed: _pickFile,
                          isLoading: _isLoading,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Guide ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Panduan Format Baru (SRS)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _headers.join(", "),
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Contoh Data:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _exampleData,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Text("Preview / Edit Data (Otomatis terisi setelah upload):"),
            const SizedBox(height: 8),

            TextField(
              controller: _textController,
              maxLines: 15,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: "Data CSV akan muncul di sini...",
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),
            CustomButton(
              text: "Proses Import ke Database",
              onPressed: _processImport,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
