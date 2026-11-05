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
    defaultValue: kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000',
  );
  static String baseUrl = _defaultUrl;

  String? _token;
  DateTime? _tokenExpiry;

  /// Notifier untuk perubahan status login (diamati oleh main.dart / Gate).
  static final ValueNotifier<bool> loggedIn = ValueNotifier<bool>(false);

  bool get isLoggedIn =>
      _token != null &&
      _tokenExpiry != null &&
      DateTime.now().isBefore(_tokenExpiry!);

  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer $_token',
      };

  // ============ PERSISTENCE ============
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final exp = prefs.getInt('token_expiry');
    if (exp != null) {
      _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(exp);
    }
    baseUrl = prefs.getString('base_url') ?? _defaultUrl;
    loggedIn.value = isLoggedIn;
  }

  /// Alias untuk loadToken
  Future<void> restore() => loadToken();

  Future<void> setBaseUrl(String url) async {
    String cleaned = url.trim().replaceAll(RegExp(r'^[=\s]+'), '').replaceAll(RegExp(r'/+$'), '');
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'http://$cleaned';
    }
    baseUrl = cleaned;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('base_url', baseUrl);
  }

  Future<void> _saveToken(String token, int expiresIn) async {
    _token = token;
    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setInt('token_expiry', _tokenExpiry!.millisecondsSinceEpoch);
    loggedIn.value = true;
  }

  Future<void> clearToken() async {
    _token = null;
    _tokenExpiry = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('token_expiry');
    loggedIn.value = false;
  }

  /// Alias untuk clearToken
  Future<void> logout() => clearToken();

  // ============ LOGIN ============
  Future<void> login(String username, String password) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/mobile/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) throw _error(res);
    final j = jsonDecode(res.body);
    final token = j['token'] as String;
    final expiresIn = (j['expires_in'] as num?)?.toInt() ?? 43200; // default 12 jam
    await _saveToken(token, expiresIn);
  }

  // ============ STATUS ============
  Future<Map<String, dynamic>> getStatus() async {
    _checkAuth();
    final res = await http
        .get(
          Uri.parse('$baseUrl/mobile/status'),
          headers: _authHeaders,
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 401) {
      await clearToken();
      throw _error(res);
    }
    if (res.statusCode != 200) throw _error(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Alias untuk getStatus
  Future<Map<String, dynamic>> status() => getStatus();

  // ============ HISTORY ============
  Future<List<Map<String, dynamic>>> getHistory({int limit = 30}) async {
    _checkAuth();
    final res = await http
        .get(
          Uri.parse('$baseUrl/mobile/history?limit=$limit'),
          headers: _authHeaders,
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 401) {
      await clearToken();
      throw _error(res);
    }
    if (res.statusCode != 200) throw _error(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = data['items'] as List? ?? [];
    return List<Map<String, dynamic>>.from(items);
  }

  /// Format respons mentah history
  Future<Map<String, dynamic>> history({int limit = 30}) async {
    _checkAuth();
    final res = await http
        .get(
          Uri.parse('$baseUrl/mobile/history?limit=$limit'),
          headers: _authHeaders,
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 401) {
      await clearToken();
      throw _error(res);
    }
    if (res.statusCode != 200) throw _error(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ============ UPLOAD FOTO ============
  Future<Map<String, dynamic>> uploadPhoto(dynamic imageFile) async {
    _checkAuth();
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/mobile/upload'),
    );
    req.headers['Authorization'] = 'Bearer $_token';

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
      // Fallback duck-typing for XFile or similar
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

    if (res.statusCode == 401) {
      await clearToken();
      throw _error(res);
    }
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
  void _checkAuth() {
    if (!isLoggedIn) {
      if (_token != null) clearToken();
      throw ApiException('Sesi habis, silakan login ulang');
    }
  }

  ApiException _error(http.Response res) {
    try {
      final msg = jsonDecode(res.body)['detail'];
      return ApiException((msg ?? 'Error ${res.statusCode}').toString());
    } catch (_) {
      return ApiException('Error ${res.statusCode}');
    }
  }
}
