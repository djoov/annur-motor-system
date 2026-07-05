import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;

class ExportService {
  /// Exports data to a CSV file.
  ///
  /// [headers] is optional. If provided, it will be the first row.
  /// [data] is the list of rows. Use simple types (String, num).
  /// [fileName] should ideally end in .csv, but logic will append if needed.
  static Future<void> exportToCSV({
    required List<List<dynamic>> data,
    required String fileName,
    List<String>? headers,
  }) async {
    // 1. Prepare Data
    List<List<dynamic>> allRows = [];
    if (headers != null) {
      final updatedHeaders = List<String>.from(headers);
      if (!updatedHeaders.contains('description')) {
        updatedHeaders.add('description');
      }
      allRows.add(updatedHeaders);
    }
    allRows.addAll(data);

    // 2. Convert to CSV String
    String csvData = Csv().encode(allRows);

    // 3. Save/Download Logic
    if (kIsWeb) {
      final bytes = utf8.encode(csvData);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Desktop Save Dialog
      String? outputFile = await FilePicker.saveFile(
        dialogTitle: 'Simpan file CSV',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputFile != null) {
        // Ensure extension
        if (!outputFile.toLowerCase().endsWith('.csv')) {
          outputFile = '$outputFile.csv';
        }
        final file = File(outputFile);
        await file.writeAsString(csvData);
      }
    } else {
      // Mobile Share Logic
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/$fileName";
      final file = File(path);
      await file.writeAsString(csvData);

      // Verify file exists
      if (await file.exists()) {
        await Share.shareXFiles([XFile(path)], text: 'Export Data: $fileName');
      }
    }
  }
}
