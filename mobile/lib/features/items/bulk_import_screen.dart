import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme.dart';
import '../../core/services/export_service.dart';
import 'items_provider.dart';
import '../categories/categories_provider.dart';

class BulkImportScreen extends StatefulWidget {
  const BulkImportScreen({Key? key}) : super(key: key);

  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> {
  final TextEditingController _rawTextController = TextEditingController();
  bool _isLoading = false;
  String? _selectedFileName;
  int? _selectedFileSize;
  bool _showRawEditor = false;

  // Parsed item objects ready for import
  List<Map<String, dynamic>> _parsedItems = [];
  int _newItemsCount = 0;
  int _existingItemsCount = 0;
  List<String> _detectedWarnings = [];

  final List<String> _standardHeaders = [
    "KODE",
    "NAMA BARANG",
    "HARGA BELI",
    "HARGA JUAL",
    "STOK",
    "KATEGORI",
    "TAGS",
    "LOKASI",
    "DESKRIPSI",
  ];

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _rawTextController.dispose();
    super.dispose();
  }

  // ==========================================
  // 🧠 CONVENTIONAL AI / HEURISTIC ENGINE
  // ==========================================

  /// 1. Auto-detect CSV delimiter (comma, semicolon, tab, pipe)
  String _detectDelimiter(String text) {
    final firstLine = text.split('\n').firstWhere(
          (l) => l.trim().isNotEmpty,
          orElse: () => '',
        );
    final commas = firstLine.split(',').length;
    final semicolons = firstLine.split(';').length;
    final tabs = firstLine.split('\t').length;
    final pipes = firstLine.split('|').length;

    if (semicolons > commas && semicolons > tabs && semicolons > pipes) return ';';
    if (tabs > commas && tabs > semicolons) return '\t';
    if (pipes > commas && pipes > semicolons) return '|';
    return ',';
  }

  /// 2. Clean numeric / currency value (Rp 50.000, 50,000.00, etc.)
  int _cleanInt(dynamic val, [int defaultValue = 0]) {
    if (val == null) return defaultValue;
    if (val is int) return val;
    if (val is num) return val.toInt();

    String s = val.toString().trim();
    if (s.isEmpty) return defaultValue;

    // Remove Rp, IDR, spaces
    s = s.replaceAll(RegExp(r'[Rr][Pp]\.?|\s+|[IDR]'), '');

    // Handle Indonesian thousand separator with dots (e.g. 50.000 or 50.000,00)
    if (s.contains('.') && s.contains(',')) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else if (s.contains('.') && !s.contains(',')) {
      // Check if dot is thousand separator (e.g. 50.000 or 150.000)
      final parts = s.split('.');
      if (parts.length > 1 && parts.last.length == 3) {
        s = s.replaceAll('.', '');
      }
    } else if (s.contains(',')) {
      s = s.replaceAll(',', '.');
    }

    // Clean any remaining non-digit characters except negative sign
    final cleanDigits = s.replaceAll(RegExp(r'[^0-9\-]'), '');
    return int.tryParse(cleanDigits) ?? double.tryParse(s)?.toInt() ?? defaultValue;
  }

  /// 3. AI Heuristic Category Inferencer (NLP Rule-based)
  String _inferCategory(String name) {
    final lower = name.toLowerCase();

    if (lower.contains('oli') ||
        lower.contains('oil') ||
        lower.contains('lubricant') ||
        lower.contains('mpx') ||
        lower.contains('federal') ||
        lower.contains('castrol') ||
        lower.contains('yamalube') ||
        lower.contains('motul') ||
        lower.contains('shell') ||
        lower.contains('evalube')) {
      return 'Oli & Pelumas';
    }

    if (lower.contains('ban') ||
        lower.contains('irc') ||
        lower.contains('fdr') ||
        lower.contains('corsa') ||
        lower.contains('tubetype') ||
        lower.contains('tubeless') ||
        lower.contains('swallow') ||
        lower.contains('maxxis') ||
        lower.contains('michelin') ||
        lower.contains('tire')) {
      return 'Ban';
    }

    if (lower.contains('busi') ||
        lower.contains('spark') ||
        lower.contains('ngk') ||
        lower.contains('denso')) {
      return 'Kelistrikan';
    }

    if (lower.contains('kampas') ||
        lower.contains('rem') ||
        lower.contains('disc') ||
        lower.contains('pad') ||
        lower.contains('brake') ||
        lower.contains('tromol') ||
        lower.contains('caliper')) {
      return 'Sistem Rem';
    }

    if (lower.contains('aki') ||
        lower.contains('accu') ||
        lower.contains('battery') ||
        lower.contains('yuasa') ||
        lower.contains('gs astra')) {
      return 'Aki & Baterai';
    }

    if (lower.contains('rantai') ||
        lower.contains('gir') ||
        lower.contains('gear') ||
        lower.contains('belt') ||
        lower.contains('vanbelt') ||
        lower.contains('v-belt') ||
        lower.contains('roller') ||
        lower.contains('sprocket')) {
      return 'Transmisi';
    }

    if (lower.contains('lampu') ||
        lower.contains('bohlam') ||
        lower.contains('led') ||
        lower.contains('sein') ||
        lower.contains('headlamp') ||
        lower.contains('stoplamp')) {
      return 'Lampu & Penerangan';
    }

    if (lower.contains('filter') || lower.contains('saringan')) {
      return 'Filter';
    }

    if (lower.contains('shock') ||
        lower.contains('suspensi') ||
        lower.contains('breaker') ||
        lower.contains('per')) {
      return 'Suspensi';
    }

    if (lower.contains('baut') ||
        lower.contains('mur') ||
        lower.contains('ring') ||
        lower.contains('seal') ||
        lower.contains('klip') ||
        lower.contains('gasket')) {
      return 'Baut & Fastener';
    }

    return 'Sparepart';
  }

  /// 4. Auto-generate smart Code/SKU if blank
  String _generateSmartCode(String name, String category, int index) {
    final catCode = category.replaceAll(RegExp(r'[^A-Za-z]'), '').toUpperCase();
    final catPrefix = catCode.length >= 3 ? catCode.substring(0, 3) : "PRD";

    final words = name.trim().split(RegExp(r'\s+'));
    String nameInitials = "";
    for (var w in words.take(2)) {
      final clean = w.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
      if (clean.isNotEmpty) {
        nameInitials += clean.length >= 3 ? clean.substring(0, 3) : clean;
      }
    }
    if (nameInitials.isEmpty) nameInitials = "ITEM";

    final numStr = (index + 1).toString().padLeft(3, '0');
    final randomSuffix = (Random().nextInt(90) + 10).toString();
    return "$catPrefix-$nameInitials-$numStr$randomSuffix";
  }

  // ==========================================
  // 📥 ACTIONS & LOGIC
  // ==========================================

  // --- Download Standard Template ---
  Future<void> _downloadTemplate() async {
    try {
      setState(() => _isLoading = true);

      final List<List<dynamic>> exampleRows = [
        [
          "OLI001",
          "Oli MPX 1 0.8L Honda",
          48000,
          60000,
          55,
          "Oli & Pelumas",
          "oli,honda,matic",
          "Rak A1-05",
          "Oli motor matic Honda standar",
        ],
        [
          "BAN001",
          "Ban Luar IRC 80/90-14",
          145000,
          175000,
          28,
          "Ban",
          "ban,irc,tubetype",
          "Rak B2-01",
          "Ban standar ring 14",
        ],
        [
          "BUS001",
          "Busi NGK CPR9EA-9",
          18000,
          25000,
          70,
          "Kelistrikan",
          "busi,ngk,vario,beat",
          "Rak C1-02",
          "Busi standar matic injeksi",
        ],
      ];

      await ExportService.exportToCSV(
        headers: _standardHeaders,
        data: exampleRows,
        fileName: "Template_Import_Barang_Annur_App.csv",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Template CSV berhasil diunduh."),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mengunduh template: $e"),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Pick CSV File ---
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _isLoading = true);
        final file = result.files.single;
        _selectedFileName = file.name;
        _selectedFileSize = file.size;

        String csvString = "";
        if (file.path != null) {
          csvString = await File(file.path!).readAsString();
        } else if (file.bytes != null) {
          csvString = utf8.decode(file.bytes!);
        }

        _rawTextController.text = csvString;
        _parseCSVContent(csvString);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal membaca file: $e"),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Smart Intelligent Parser ---
  void _parseCSVContent(String text) {
    if (text.trim().isEmpty) {
      setState(() {
        _parsedItems = [];
        _newItemsCount = 0;
        _existingItemsCount = 0;
        _detectedWarnings = [];
      });
      return;
    }

    final delimiter = _detectDelimiter(text);
    List<List<dynamic>> rows = [];

    try {
      if (delimiter != ',') {
        // Manual split for non-comma delimiters
        rows = text
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .map((line) => line.split(delimiter))
            .toList();
      } else {
        rows = Csv().decode(text);
      }
    } catch (_) {
      rows = text
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .map((line) => line.split(delimiter))
          .toList();
    }

    if (rows.isEmpty) {
      setState(() => _parsedItems = []);
      return;
    }

    // Map column headers using fuzzy matching
    int startRow = 0;
    Map<String, int> colMap = {};
    final warnings = <String>[];

    final firstRow = rows[0].map((e) => e.toString().trim().toLowerCase()).toList();

    // Check if first row is header
    final headerKeywords = [
      'kode', 'code', 'kd', 'sku', 'barcode', 'part',
      'nama', 'name', 'item', 'produk', 'barang',
      'harga', 'price', 'beli', 'jual', 'stok', 'qty', 'stock',
      'kategori', 'category', 'rak', 'lokasi', 'deskripsi'
    ];

    final isHeaderRow = firstRow.any((col) =>
        headerKeywords.any((k) => col.contains(k)));

    if (isHeaderRow) {
      startRow = 1;
      for (int i = 0; i < firstRow.length; i++) {
        final col = firstRow[i];
        if (col.contains('kode') || col.contains('code') || col == 'kd' || col == 'sku' || col.contains('barcode') || col.contains('part')) {
          colMap['code'] ??= i;
        } else if (col.contains('nama') || col.contains('name') || col.contains('item') || col.contains('barang') || col.contains('produk')) {
          colMap['name'] ??= i;
        } else if (col.contains('beli') || col.contains('buy') || col.contains('modal') || col.contains('hpp')) {
          colMap['buyPrice'] ??= i;
        } else if (col.contains('jual') || col.contains('sell') || col.contains('umum') || col.contains('ecer') || col.contains('harga')) {
          colMap['sellPrice'] ??= i;
        } else if (col.contains('stok') || col.contains('qty') || col.contains('stock') || col.contains('jumlah')) {
          colMap['stock'] ??= i;
        } else if (col.contains('kategori') || col.contains('category') || col.contains('jenis')) {
          colMap['category'] ??= i;
        } else if (col.contains('rak') || col.contains('lokasi') || col.contains('posisi')) {
          colMap['location_display'] ??= i;
        } else if (col.contains('tag') || col.contains('keyword')) {
          colMap['tags'] ??= i;
        } else if (col.contains('deskripsi') || col.contains('description') || col.contains('keterangan') || col.contains('catatan')) {
          colMap['description'] ??= i;
        }
      }
    }

    final itemsProvider = Provider.of<ItemsProvider>(context, listen: false);
    final existingCodes = itemsProvider.items.map((i) => i.code.trim().toUpperCase()).toSet();

    final List<Map<String, dynamic>> parsed = [];
    final Set<String> seenCodesInFile = {};
    int newCount = 0;
    int updateCount = 0;

    for (int i = startRow; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      String getField(String key, int fallbackIndex) {
        final idx = colMap.containsKey(key) ? colMap[key]! : fallbackIndex;
        if (idx < row.length) {
          var val = row[idx]?.toString().trim() ?? '';
          // Clean Excel ="..." or ='...' wrappers
          if ((val.startsWith('="') && val.endsWith('"')) ||
              (val.startsWith("='") && val.endsWith("'"))) {
            val = val.substring(2, val.length - 1);
          }
          return val.trim();
        }
        return '';
      }

      var name = getField('name', 1);
      var code = getField('code', 0);

      // If both code and name are empty, skip line
      if (code.isEmpty && name.isEmpty) continue;

      // If name is empty but code exists, use code as name
      if (name.isEmpty && code.isNotEmpty) {
        name = "Barang $code";
        warnings.add("Baris ${i + 1}: Nama barang kosong, otomatis dinamai '$name'.");
      }

      // If category is missing, use AI Heuristic Inferencer
      var category = getField('category', 5);
      if (category.isEmpty) {
        category = _inferCategory(name);
      }

      // If code is empty, AI generate smart SKU code
      if (code.isEmpty) {
        code = _generateSmartCode(name, category, i);
        warnings.add("Baris ${i + 1}: Kode barang kosong, dibuatkan kode otomatis: '$code'.");
      }

      final cleanCode = code.toUpperCase();

      // Handle duplicate codes within the same uploaded file
      if (seenCodesInFile.contains(cleanCode)) {
        warnings.add("Baris ${i + 1}: Kode '$cleanCode' duplikat dalam file. Baris terakhir akan digunakan.");
      }
      seenCodesInFile.add(cleanCode);

      final buyPrice = _cleanInt(getField('buyPrice', 2));
      final sellPrice = _cleanInt(getField('sellPrice', 3));
      final stock = _cleanInt(getField('stock', 4));
      final tagsStr = getField('tags', 6);
      final locationDisplay = getField('location_display', 7);
      final description = getField('description', 8);

      // Final price validation: If sell price is 0, make it equal to buy price
      final finalSellPrice = sellPrice > 0 ? sellPrice : (buyPrice > 0 ? buyPrice : 0);

      if (existingCodes.contains(cleanCode)) {
        updateCount++;
      } else {
        newCount++;
      }

      parsed.add({
        'code': cleanCode,
        'name': name,
        'buyPrice': buyPrice,
        'sellPrice': finalSellPrice,
        'stock': stock,
        'qty_display': stock,
        'tags': tagsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'category': category,
        'location_display': locationDisplay,
        'description': description,
      });
    }

    setState(() {
      _parsedItems = parsed;
      _newItemsCount = newCount;
      _existingItemsCount = updateCount;
      _detectedWarnings = warnings.take(5).toList();
    });
  }

  // --- Process Smart Import ---
  Future<void> _processImport() async {
    if (_parsedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tidak ada data barang untuk diimport. Silakan pilih file CSV."),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Text("Import barang?"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${_parsedItems.length} baris siap diimpor:",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildResultRow(LucideIcons.packagePlus, "Barang baru", "$_newItemsCount item", AppColors.success),
              const SizedBox(height: 8),
              _buildResultRow(LucideIcons.refreshCw, "Barang yang sudah ada (diperbarui)", "$_existingItemsCount item", AppColors.primary),
              const SizedBox(height: 12),
              const Text(
                "Barang yang kodenya sudah ada diperbarui: harga, kategori, dan STOK DIGANTI sesuai angka di file (tidak dijumlahkan). Barang yang tidak ada di file tidak diubah.",
                style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal", style: TextStyle(color: AppColors.mutedForeground)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Mulai Import"),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        // Single Unified Smart Mode (Overwrite & sync current spreadsheet truth)
        final result = await Provider.of<ItemsProvider>(
          context,
          listen: false,
        ).bulkUpsertItems(_parsedItems, isRestockMode: false);

        // Refresh master categories list as well
        if (mounted) {
          Provider.of<CategoriesProvider>(context, listen: false).fetchCategories();
        }

        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.successSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.circleCheck, color: AppColors.success),
                  ),
                  const SizedBox(width: 12),
                  const Text("Import Berhasil!", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResultRow(LucideIcons.packagePlus, "Barang Baru Dibuat", "${result['created'] ?? 0} item", AppColors.success),
                  const SizedBox(height: 8),
                  _buildResultRow(LucideIcons.refreshCw, "Barang Diupdate", "${result['updated'] ?? 0} item", AppColors.primary),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Return to items screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Selesai & Lihat Barang"),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Terjadi kesalahan saat import: $e"),
              backgroundColor: AppColors.destructive,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildResultRow(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Import Barang Massal"),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showRawEditor ? LucideIcons.eye : LucideIcons.code),
            tooltip: _showRawEditor ? "Tampilan Rapi" : "Lihat / Edit CSV Mentah",
            onPressed: () => setState(() => _showRawEditor = !_showRawEditor),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    "Sedang menyelaraskan data barang ke database...",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Step 1: Upload File ---
                  _buildSectionCard(
                    title: "Pilih File Data Barang",
                    subtitle: "Unggah file CSV atau Excel yang berisi daftar barang toko.",
                    trailing: OutlinedButton.icon(
                      onPressed: _downloadTemplate,
                      icon: const Icon(LucideIcons.download, size: 16),
                      label: const Text("Unduh Template", style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    child: Column(
                      children: [
                        if (_selectedFileName == null)
                          InkWell(
                            onTap: _pickFile,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.accentSoft.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  style: BorderStyle.solid,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(LucideIcons.uploadCloud, size: 32, color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "Pilih file CSV barang",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "Kolom dikenali dari judulnya (nama, kode, harga, stok). Format harga seperti Rp 12.000 dibersihkan otomatis.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.successSoft,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.successBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(LucideIcons.fileSpreadsheet, color: AppColors.success, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedFileName!,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${(_selectedFileSize != null ? (_selectedFileSize! / 1024).toStringAsFixed(1) : '0')} KB • ${_parsedItems.length} barang terdeteksi",
                                        style: TextStyle(fontSize: 12, color: AppColors.successStrong),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.refreshCw, size: 18, color: AppColors.primary),
                                  tooltip: "Ganti File",
                                  onPressed: _pickFile,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Warnings / AI auto-fix notes if any
                  if (_detectedWarnings.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warningSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warningBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.info, size: 16, color: AppColors.warningStrong),
                              const SizedBox(width: 8),
                              Text(
                                "Yang disesuaikan otomatis:",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.warningStrong),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ..._detectedWarnings.map((w) => Text("• $w", style: TextStyle(fontSize: 12, color: AppColors.warningStrong))),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // --- Step 2: Intelligent Live Preview ---
                  if (_showRawEditor)
                    _buildRawEditorCard()
                  else if (_parsedItems.isNotEmpty)
                    _buildSmartPreviewCard(),

                  const SizedBox(height: 24),

                  // --- Single Action Button ---
                  ElevatedButton.icon(
                    onPressed: _parsedItems.isNotEmpty ? _processImport : null,
                    icon: const Icon(LucideIcons.fileInput, size: 20),
                    label: Text(
                      _parsedItems.isNotEmpty
                          ? "Import ${_parsedItems.length} Barang"
                          : "Pilih file dulu",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.border,
                      disabledForegroundColor: AppColors.mutedForeground,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.foreground.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildSmartPreviewCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Tinjauan Data Cerdas",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.successSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "$_newItemsCount Baru",
                      style: TextStyle(color: AppColors.successStrong, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Update",
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _parsedItems.length > 5 ? 5 : _parsedItems.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _parsedItems[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.package, size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "Kode: ${item['code']} • Kategori: ${item['category']}",
                            style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormat.format(item['sellPrice'] ?? 0),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                        ),
                        Text(
                          "Stok: ${item['stock']} Unit",
                          style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          if (_parsedItems.length > 5) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                "... dan ${_parsedItems.length - 5} barang lainnya siap diselaraskan.",
                style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRawEditorCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Edit Teks CSV Mentah", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _rawTextController,
            maxLines: 10,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            onChanged: _parseCSVContent,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              hintText: "Tempel atau edit teks CSV di sini...",
              filled: true,
              fillColor: AppColors.background,
            ),
          ),
        ],
      ),
    );
  }
}
