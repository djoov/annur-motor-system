import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

/// Cloudinary upload service for product images with automatic compression
class CloudinaryService {
  static const String cloudName = 'dnic1sjla';
  static const String uploadPreset = 'product_images';

  static const String _uploadUrl = 'https://api.cloudinary.com/v1_1';
  static const int _maxFileSize = 9 * 1024 * 1024; // 9MB to be safe
  static const int _maxWidth = 1200;
  static const int _maxHeight = 1200;

  /// Upload an image to Cloudinary with automatic compression
  static Future<String?> uploadImage(XFile imageFile) async {
    try {
      if (cloudName == 'YOUR_CLOUD_NAME' ||
          uploadPreset == 'YOUR_UPLOAD_PRESET') {
        print('Cloudinary credentials not configured!');
        return null;
      }

      // Read image bytes
      Uint8List imageBytes = await imageFile.readAsBytes();
      print(
        'Original size: ${(imageBytes.length / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      // Always compress for consistent performance
      print('Compressing image...');
      imageBytes = await _compressImage(imageBytes);
      print(
        'Compressed size: ${(imageBytes.length / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      final uri = Uri.parse('$_uploadUrl/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = 'product_images';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: imageFile.name,
        ),
      );

      print('Uploading to Cloudinary...');
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final secureUrl = data['secure_url'] as String;
        print('Cloudinary upload success: $secureUrl');
        return secureUrl;
      } else {
        print('Cloudinary upload failed: ${response.statusCode}');
        print('Response: $responseBody');
        return null;
      }
    } catch (e, stackTrace) {
      print('Cloudinary upload error: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Compress image to reduce file size
  static Future<Uint8List> _compressImage(Uint8List bytes) async {
    return await compute(_compressInIsolate, bytes);
  }

  /// Run compression in isolate to avoid UI freeze
  static Uint8List _compressInIsolate(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;

    // Resize if too large
    img.Image resized = image;
    if (image.width > _maxWidth || image.height > _maxHeight) {
      resized = img.copyResize(
        image,
        width: image.width > image.height ? _maxWidth : null,
        height: image.height >= image.width ? _maxHeight : null,
      );
    }

    // Encode as JPEG with quality reduction
    int quality = 85;
    Uint8List result = Uint8List.fromList(
      img.encodeJpg(resized, quality: quality),
    );

    // Further reduce quality if still too large
    while (result.length > _maxFileSize && quality > 30) {
      quality -= 10;
      result = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    }

    return result;
  }
}
