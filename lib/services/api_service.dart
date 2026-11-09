import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const String _defaultUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kIsWeb ? 'http://localhost:5000' : 'http://10.0.2.2:5000',
  );
  static String baseUrl = _defaultUrl;

  // ============ PERSISTENCE ============
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString('base_url') ?? _defaultUrl;
  }

  /// Alias init
  Future<void> restore() => init();

  Future<void> setBaseUrl(String url) async {
    String cleaned = url.trim().replaceAll(RegExp(r'^[=\s]+'), '').replaceAll(RegExp(r'/+$'), '');
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'http://$cleaned';
    }
    baseUrl = cleaned;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('base_url', baseUrl);
  }

  // ============ STATUS / MONITORING ============
  Future<Map<String, dynamic>> getStatus() async {
    final res = await http
        .get(Uri.parse('$baseUrl/mobile/status'))
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) throw _error(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Alias untuk getStatus
  Future<Map<String, dynamic>> status() => getStatus();

  // ============ HISTORY ============
  Future<List<Map<String, dynamic>>> getHistory({int limit = 30}) async {
    final res = await http
        .get(Uri.parse('$baseUrl/mobile/history?limit=$limit'))
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) throw _error(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = data['items'] as List? ?? [];
    return List<Map<String, dynamic>>.from(items);
  }

  /// Format respons mentah history
  Future<Map<String, dynamic>> history({int limit = 30}) async {
    final res = await http
        .get(Uri.parse('$baseUrl/mobile/history?limit=$limit'))
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) throw _error(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ============ UPLOAD FOTO ============
  Future<Map<String, dynamic>> uploadPhoto(dynamic imageFile) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/mobile/upload'),
    );

    if (imageFile is Uint8List) {
      req.files.add(http.MultipartFile.fromBytes(
        'file',
        imageFile,
        filename: 'daun_cabai.jpg',
      ));
    } else if (imageFile != null && imageFile.runtimeType.toString().contains('XFile')) {
      final bytes = await imageFile.readAsBytes();
      final name = (imageFile.name as String?)?.isNotEmpty == true
          ? imageFile.name as String
          : 'daun_cabai.jpg';
      req.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: name,
      ));
    } else if (imageFile is File) {
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        req.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'daun_cabai.jpg',
        ));
      } else {
        req.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      }
    } else {
      try {
        final bytes = await (imageFile as dynamic).readAsBytes();
        req.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'daun_cabai.jpg',
        ));
      } catch (_) {
        throw ApiException('Format gambar tidak didukung.');
      }
    }

    final streamed = await req.send().timeout(const Duration(seconds: 90));
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) throw _error(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ============ TRIGGER POMPA MANUAL ============
  Future<Map<String, dynamic>> triggerPump({double? dosisMl}) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/api/pump/trigger'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(dosisMl != null ? {'dosis_ml': dosisMl} : {}),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) throw _error(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ============ HEALTH ============
  Future<Map<String, dynamic>> health() async {
    final res = await http
        .get(Uri.parse('$baseUrl/health'))
        .timeout(const Duration(seconds: 10));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ============ HELPERS ============
  ApiException _error(http.Response res) {
    try {
      final msg = jsonDecode(res.body)['detail'] ?? jsonDecode(res.body)['message'];
      return ApiException((msg ?? 'Error ${res.statusCode}').toString());
    } catch (_) {
      return ApiException('Error ${res.statusCode}');
    }
  }
}
