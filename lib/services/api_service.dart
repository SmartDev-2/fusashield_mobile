import 'dart:convert';
import 'dart:typed_data';

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

  /// Endpoint ada di folder api/ pada proyek Vercel (api/mobile/status.js, dst.).
  static const String baseUrl = 'https://fusashield.vercel.app/api';

  /// Kunci aplikasi (opsional, harus sama dengan MOBILE_APP_KEY di Vercel). Jangan ditulis di kode:
  ///   flutter run --dart-define=APP_KEY=isi-kunci
  /// Catatan: kunci ini tetap bisa diambil dari aplikasi yang di-decompile. Untuk akses lebih aman pakai login().
  static const String _appKey = 'bXfbIXRQ8vmETKptnwq3aToDI2BOfKFe1ptLnEg0b5o';

  String? _token;

  // ============ PERSISTENCE ============
  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    _token = p.getString('token');
  }

  /// Alias init
  Future<void> restore() => init();

  bool get isLoggedIn => _token != null;

  // ============ LOGIN (opsional) ============
  Future<void> login(String username, String password) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/mobile/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw _error(res);
    _token = (jsonDecode(res.body) as Map<String, dynamic>)['token'] as String;
    final p = await SharedPreferences.getInstance();
    await p.setString('token', _token!);
  }

  Future<void> logout() async {
    _token = null;
    final p = await SharedPreferences.getInstance();
    await p.remove('token');
  }

  Map<String, String> _headers([Map<String, String>? extra]) => {
        if (_appKey.isNotEmpty) 'X-API-KEY': _appKey,
        if (_token != null) 'Authorization': 'Bearer $_token',
        ...?extra,
      };

  Future<Map<String, dynamic>> _getJson(String path) async {
    final res = await http
        .get(Uri.parse('$baseUrl$path'), headers: _headers())
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw _error(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ============ STATUS / MONITORING ============
  Future<Map<String, dynamic>> getStatus() => _getJson('/mobile/status');

  /// Alias untuk getStatus
  Future<Map<String, dynamic>> status() => getStatus();

  // ============ HISTORY ============
  /// Format respons mentah history ({items: [...]})
  Future<Map<String, dynamic>> history({int limit = 30}) =>
      _getJson('/mobile/history?limit=$limit');

  Future<List<Map<String, dynamic>>> getHistory({int limit = 30}) async {
    final data = await history(limit: limit);
    final items = data['items'] as List? ?? [];
    return List<Map<String, dynamic>>.from(items);
  }

  // ============ UPLOAD FOTO ============
  /// Menerima Uint8List, XFile (image_picker), atau File. Dikirim sebagai bytes mentah (bukan multipart).
  /// Server menyimpannya ke Supabase; hasil CNN muncul di status() setelah diproses layanan Keras.
  /// Mengembalikan {path, photo_url}.
  Future<Map<String, dynamic>> uploadPhoto(dynamic imageFile) async {
    final bytes = await _bytesOf(imageFile);
    if (bytes.isEmpty) throw ApiException('Foto kosong.');
    if (bytes.length > 4 * 1024 * 1024) {
      throw ApiException('Foto terlalu besar (maksimal 4 MB).');
    }
    final res = await http
        .post(
          Uri.parse('$baseUrl/mobile/upload'),
          headers: _headers({
            'Content-Type': 'image/jpeg'
          }), // tipe asli dideteksi server dari isi file
          body: bytes,
        )
        .timeout(const Duration(seconds: 90));
    if (res.statusCode != 200) throw _error(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Uint8List> _bytesOf(dynamic image) async {
    if (image is Uint8List) return image;
    try {
      // XFile dan File sama-sama punya readAsBytes() (aman juga untuk Flutter Web)
      final data = await (image as dynamic).readAsBytes();
      return Uint8List.fromList(List<int>.from(data as List));
    } catch (_) {
      throw ApiException('Format gambar tidak didukung.');
    }
  }

  // ============ TRIGGER POMPA MANUAL ============
  /// BELUM ADA di server (api/pump/trigger.js belum dibuat), jadi saat ini akan menghasilkan error 404.
  Future<Map<String, dynamic>> triggerPump({double? dosisMl}) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/pump/trigger'),
          headers: _headers({'Content-Type': 'application/json'}),
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
    if (res.statusCode == 401 && _token != null) logout(); // token kedaluwarsa
    try {
      final body = jsonDecode(res.body);
      final msg = body['detail'] ?? body['message'];
      return ApiException((msg ?? 'Error ${res.statusCode}').toString());
    } catch (_) {
      return ApiException('Error ${res.statusCode}');
    }
  }
}
