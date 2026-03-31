import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute, kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../constants/api_config.dart';
import 'image_compression.dart';

/// Picks images and uploads them to the backend with Bearer auth.
class ImageUploadService {
  ImageUploadService({
    FlutterSecureStorage? storage,
    ImagePicker? picker,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _picker = picker ?? ImagePicker();

  final FlutterSecureStorage _storage;
  final ImagePicker _picker;

  static const String _kAccessToken = 'access_token';

  Future<XFile?> pickImage({bool fromCamera = false}) async {
    return _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );
  }

  Future<String> uploadProfileImage(XFile imageFile) {
    return _upload(
      path: '/auth/profile/image',
      fieldName: 'profileImage',
      imageFile: imageFile,
      resultKey: 'profileImage',
    );
  }

  Future<String> uploadCoverImage(XFile imageFile) {
    return _upload(
      path: '/auth/profile/cover',
      fieldName: 'coverImage',
      imageFile: imageFile,
      resultKey: 'coverImage',
    );
  }

  Future<Uint8List> _compressPickToUnder1Mb(XFile imageFile) async {
    final raw = await imageFile.readAsBytes();
    try {
      if (kIsWeb) {
        return compressRawJpegUnder1Mb(raw);
      }
      return await compute(compressRawJpegUnder1Mb, raw).timeout(
        const Duration(seconds: 90),
        onTimeout: () => throw Exception(
          'Compressing the photo took too long. Try another image.',
        ),
      );
    } on StateError catch (e) {
      if (e.message == 'decode_failed') {
        throw Exception('Could not read image. Try a JPG, PNG, or WebP photo.');
      }
      if (e.message == 'too_large') {
        throw Exception(
          'Image could not be compressed under 1 MB. Try a smaller photo.',
        );
      }
      rethrow;
    }
  }

  Future<String> _upload({
    required String path,
    required String fieldName,
    required XFile imageFile,
    required String resultKey,
  }) async {
    final token = await _storage.read(key: _kAccessToken);
    if (token == null || token.isEmpty) {
      throw Exception('Not signed in. Please log in again.');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';

    final compressed = await _compressPickToUnder1Mb(imageFile);
    final baseName = p.basenameWithoutExtension(imageFile.path);
    final filename = '${baseName.isEmpty ? 'photo' : baseName}.jpg';

    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        compressed,
        filename: filename,
      ),
    );

    http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Upload timed out. Try again.'),
      );
    } on SocketException {
      throw Exception('No network connection. Check your internet and try again.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Upload failed: $e');
    }

    final body = await streamed.stream
        .bytesToString()
        .timeout(const Duration(seconds: 60), onTimeout: () {
      throw Exception('Upload timed out. Try again.');
    });

    Map<String, dynamic>? json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>?;
    } catch (_) {
      json = null;
    }

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      final message = json != null && json['message'] != null
          ? json['message'].toString()
          : 'Upload failed (${streamed.statusCode})';
      throw Exception(message);
    }

    final user = json?['user'];
    if (user is! Map<String, dynamic>) {
      throw Exception('Invalid response from server.');
    }

    final url = user[resultKey];
    if (url is! String || url.isEmpty) {
      throw Exception('Server did not return $resultKey URL.');
    }

    return url;
  }
}
