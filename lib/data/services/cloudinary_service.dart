import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class CloudinaryService {
  static const String _cloudName = 'du3bakf6h';
  static const String _uploadPreset = 'ipila_uploads';

  /// Uploads a file to Cloudinary and returns the secure URL.
  /// [folder] organizes uploads e.g. 'id_photos' or 'report_photos'
  static Future<String?> uploadImage(
    File file, {
    String folder = 'ipila',
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = folder
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(body);
        return json['secure_url'] as String?;
      } else {
        debugPrint('Cloudinary upload failed [${response.statusCode}]: $body');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary upload exception: $e');
      return null;
    }
  }

  /// Uploads an XFile (for web) to Cloudinary and returns the secure URL.
  static Future<String?> uploadImageWeb(
    XFile file, {
    String folder = 'ipila',
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final bytes = await file.readAsBytes();
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = folder
        ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: file.name),
        );

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(body);
        return json['secure_url'] as String?;
      } else {
        debugPrint('Cloudinary upload failed [${response.statusCode}]: $body');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary upload exception: $e');
      return null;
    }
  }
}
