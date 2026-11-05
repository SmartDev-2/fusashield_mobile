import 'dart:async';

import 'package:flutter/material.dart';

import '../models/sensor_data.dart';
import '../theme/app_colors.dart';
import 'api_service.dart';

/// Menyimpan data dari server dan memperbaruinya otomatis tiap 15 detik.
/// Semua halaman membaca dari sini (lewat ListenableBuilder).
class LiveStore extends ChangeNotifier {
  LiveStore._();
  static final LiveStore instance = LiveStore._();

  Map<String, dynamic>? status;
  List<Map<String, dynamic>> history = [];
  String? error;
  Timer? _timer;
  bool _busy = false;

  void start() {
    if (_timer != null) return;
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => refresh());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh() async {
    if (_busy) return;
    _busy = true;
    try {
      status = await ApiService.instance.status();
      // Perbarui riwayat setiap kali atau bergantian
      final h = await ApiService.instance.history(limit: 30);
      final items = h['items'];
      if (items is List) {
        history = items.cast<Map<String, dynamic>>();
      }
      error = null;
    } catch (e) {
      if (e is ApiException) {
        error = e.message;
      } else {
        error = 'Server tidak terjangkau. Periksa alamat server dan jaringan.';
      }
    }
    _busy = false;
    notifyListeners();
  }

  // ---------- Pembantu & Aksesor Data ----------
  Map<String, dynamic> get _sens => (status?['sensors'] as Map?)?.cast<String, dynamic>() ?? {};
  Map<String, dynamic> get _dec => (status?['decision'] as Map?)?.cast<String, dynamic>() ?? {};

  static String fmt(Object? v) =>
      v is num ? v.toStringAsFixed(v % 1 == 0 ? 0 : 1) : '–';

  bool get online => status != null && error == null;
  String get updatedLabel => !online ? 'Server tidak terjangkau' : 'Update ${_dec['last_updated'] ?? '-'}';
  String get device => (status?['device'] ?? 'cabai_01').toString();
  String? get photoUrl => status?['photo_url'] as String?;

  String? get tingkatDosis => _dec['tingkat_dosis'] as String?;
  String? get statusMitigasi => _dec['status_mitigasi'] as String?;
  num? get dosisRekomendasi => _dec['dosis_rekomendasi_ml'] as num?;
  num? get dosisAktual => _dec['dosis_ml'] as num?;
  String? get cnnLabel => _dec['cnn_label'] as String?;
  num? get cnnConfidence => _dec['cnn_confidence'] as num?;
  num? get cnnSymptomScore => _dec['cnn_symptom_score'] as num?;
  String? get faseHst => _dec['fase_hst'] as String?;
  num? get sisaCooldownDetik => _dec['sisa_cooldown_detik'] as num?;
  String? get lastUpdated => _dec['last_updated'] as String?;
  String? get alasanBlokir => _dec['alasan_blokir'] as String?;
  bool get fotoBasi => _dec['foto_basi'] == true;
  num? get fotoUmurJam => _dec['foto_umur_jam'] as num?;

  String get _level => (tingkatDosis ?? '').toLowerCase();

  List<SensorData> get sensors {
    final soilOk = _sens['soil_valid'] == true;
    return [
      SensorData(
        title: 'Suhu',
        value: fmt(_sens['temperature']),
        unit: '°C',
        icon: Icons.thermostat_rounded,
        color: Colors.orange,
      ),
      SensorData(
        title: 'Kelembapan Udara',
        value: fmt(_sens['humidity']),
        unit: '%',
        icon: Icons.water_drop_rounded,
        color: Colors.blue,
      ),
      SensorData(
        title: soilOk ? 'Kelembapan Tanah' : 'Tanah',
        value: fmt(_sens['soil_moisture']),
        unit: '%',
        icon: Icons.grass_rounded,
        color: AppColors.accent,
      ),
      SensorData(
        title: 'Status Pompa',
        value: (_sens['pump_status'] ?? '–').toString(),
        icon: Icons.water_rounded,
        color: (_sens['pump_status'] == 'ON') ? Colors.green : Colors.deepPurple,
      ),
    ];
  }

  String get sensorSummary =>
      'Suhu ${fmt(_sens['temperature'])}°C · udara ${fmt(_sens['humidity'])}% · tanah ${fmt(_sens['soil_moisture'])}%';

  String get plantSummary => cnnLabel == null
      ? 'Menunggu hasil analisis'
      : '$cnnLabel (${fmt(cnnConfidence)}%) · ${_level.toUpperCase()}';

  String get alertText => _level.isEmpty
      ? 'Belum ada notifikasi baru.'
      : '${statusMitigasi ?? '-'} · ${_level.toUpperCase()}';

  static const _msg = {
    'aman': 'Kondisi aman, pompa tidak perlu menyala.',
    'preventif': 'Risiko mulai naik, dosis preventif.',
    'waspada': 'Gejala layu terdeteksi, dosis sedang.',
    'kritis': 'Risiko Fusarium tinggi, dosis booster. Periksa tanaman langsung.',
  };

  String get recommendation => _level.isEmpty
      ? 'Belum ada hasil analisis tanaman.'
      : '${_msg[_level] ?? _level} Dosis rekomendasi ${fmt(dosisRekomendasi)} ml.';

  String get pumpSummary {
    final cd = sisaCooldownDetik;
    final base = 'Pompa ${_sens['pump_status'] ?? '–'}';
    final blok = alasanBlokir;
    if (blok != null) return '$base · $blok';
    return cd != null && cd > 0 ? '$base · cooldown ${(cd / 3600).ceil()} jam' : base;
  }

  String get analysisSummary => cnnLabel == null
      ? 'Belum ada hasil analisis'
      : '$cnnLabel · skor gejala ${fmt(cnnSymptomScore)}%';

  /// Deret nilai dari lama ke baru untuk grafik riwayat.
  List<double> series(String key) =>
      history.reversed.map((h) => h[key]).whereType<num>().map((n) => n.toDouble()).toList();
}
