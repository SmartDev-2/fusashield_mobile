import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  /// Endpoint Vercel Serverless Function dengan prefix `/api`.
  /// Konsep: 1 Petani = 1 APK = 1 Dedicated Cloud (Tanpa Autentikasi / Token).
  static const String baseUrl = 'https://fusashield.vercel.app/api';

  Future<void> restore() async {}

  // ═══════════════════════════════════════════════
  // STATUS  —  GET /api/mobile/status
  // ═══════════════════════════════════════════════
  Future<Map<String, dynamic>> getStatus() async {
    final res = await http
        .get(Uri.parse('$baseUrl/mobile/status'))
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) throw _error(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> status() => getStatus();

  // ═══════════════════════════════════════════════
  // HISTORY  —  GET /api/mobile/history?limit=N
  // ═══════════════════════════════════════════════
  Future<Map<String, dynamic>> history({int limit = 30}) async {
    final res = await http
        .get(Uri.parse('$baseUrl/mobile/history?limit=$limit'))
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) throw _error(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getHistory({int limit = 30}) async {
    final raw = await history(limit: limit);
    final items = raw['items'] as List? ?? [];
    return List<Map<String, dynamic>>.from(items);
  }

  // ═══════════════════════════════════════════════
  // UPLOAD FOTO  —  POST /api/mobile/upload
  // Catatan: Vercel upload handler menerima raw image bytes
  // dan multipart/form-data fallback.
  // ═══════════════════════════════════════════════
  Future<Map<String, dynamic>> uploadPhoto(dynamic imageFile) async {
    Uint8List bytes;

    if (imageFile is Uint8List) {
      bytes = imageFile;
    } else if (imageFile is XFile) {
      bytes = await imageFile.readAsBytes();
    } else if (imageFile is File) {
      bytes = await imageFile.readAsBytes();
    } else {
      try {
        bytes = await (imageFile as dynamic).readAsBytes() as Uint8List;
      } catch (_) {
        throw ApiException('Format gambar tidak didukung.');
      }
    }

    // Mengirim raw image bytes ke POST /api/mobile/upload
    final res = await http
        .post(
          Uri.parse('$baseUrl/mobile/upload'),
          headers: {'Content-Type': 'image/jpeg'},
          body: bytes,
        )
        .timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) throw _error(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ═══════════════════════════════════════════════
  // HEALTH  —  GET /api/health
  // ═══════════════════════════════════════════════
  Future<Map<String, dynamic>> health() async {
    final res = await http
        .get(Uri.parse('$baseUrl/health'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw _error(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ═══════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════
  ApiException _error(http.Response res) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final msg = body['detail'] ?? body['message'] ?? body['error'];
      return ApiException((msg ?? 'Error ${res.statusCode}').toString());
    } catch (_) {
      return ApiException('Error ${res.statusCode}');
    }
  }
}
