import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../constants/api_config.dart';

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
  static const int _maxBytes = 1024 * 1024; // 1 MB

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

  /// Decodes the picked file, re-encodes as JPEG, and shrinks quality / dimensions
  /// until the output is at most [_maxBytes].
  Future<Uint8List> _compressToUnder1Mb(String filePath) async {
    final raw = await File(filePath).readAsBytes();
    final decoded = img.decodeImage(raw);
    if (decoded == null) {
      throw Exception('Could not read image. Try a JPG, PNG, or WebP photo.');
    }

    var work = decoded;
    var quality = 88;

    List<int> encode() =>
        img.encodeJpg(work, quality: quality.clamp(5, 100));

    void shrink() {
      final w = work.width;
      final h = work.height;
      if (w <= 320 && h <= 320) return;
      final nw = (w * 0.82).round().clamp(1, w);
      final nh = (h * 0.82).round().clamp(1, h);
      work = img.copyResize(work, width: nw, height: nh);
    }

    var out = encode();
    for (var pass = 0; pass < 48 && out.length > _maxBytes; pass++) {
      if (quality > 24) {
        quality -= 6;
        out = encode();
        continue;
      }
      final w0 = work.width;
      final h0 = work.height;
      shrink();
      if (work.width == w0 && work.height == h0) {
        quality -= 4;
        if (quality < 8) {
          throw Exception(
            'Image could not be compressed under 1 MB. Try a smaller photo.',
          );
        }
        out = encode();
        continue;
      }
      quality = 82;
      out = encode();
    }

    if (out.length > _maxBytes) {
      throw Exception(
        'Image could not be compressed under 1 MB. Try a smaller photo.',
      );
    }
    return Uint8List.fromList(out);
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

    final compressed = await _compressToUnder1Mb(imageFile.path);
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
