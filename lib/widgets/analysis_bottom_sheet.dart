import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/prediction_result.dart';
import '../pages/results_page.dart';
import '../services/api_service.dart';
import '../services/live_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'farm_background.dart';
import 'glass_icon_button.dart';
import 'pill_button.dart';
import 'prediction_card.dart';

enum _AnalysisStage {
  uploading,
  analyzing,
  completed,
  error,
}

class AnalysisBottomSheet extends StatefulWidget {
  final XFile imageFile;
  final Uint8List? previewBytes;
  final VoidCallback? onCompleted;

  const AnalysisBottomSheet({
    super.key,
    required this.imageFile,
    this.previewBytes,
    this.onCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    required XFile imageFile,
    Uint8List? previewBytes,
    VoidCallback? onCompleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (ctx) => AnalysisBottomSheet(
        imageFile: imageFile,
        previewBytes: previewBytes,
        onCompleted: onCompleted,
      ),
    );
  }

  @override
  State<AnalysisBottomSheet> createState() => _AnalysisBottomSheetState();
}

class _AnalysisBottomSheetState extends State<AnalysisBottomSheet> {
  _AnalysisStage _stage = _AnalysisStage.uploading;
  String? _errorMessage;
  String? _uploadedPhotoUrl;
  Map<String, dynamic>? _resultStatus;
  Timer? _pollingTimer;
  int _secondsElapsed = 0;
  Timer? _elapsedTimer;
  bool _statusCheckInProgress = false;
  Uint8List? _bytes;
  PredictionItem? _latestPrediction;
  bool _isLoadingPrediction = false;

  bool _matchesUploadedPhoto(String? candidate, String? uploadedPath) {
    if (candidate == null || uploadedPath == null) return false;
    final cleanCandidate = candidate.split('?').first;
    final cleanUploadedPath = uploadedPath.split('?').first;
    final candidateName = cleanCandidate.split('/').last;
    final uploadedName = cleanUploadedPath.split('/').last;
    return cleanCandidate == cleanUploadedPath ||
        (candidateName.isNotEmpty &&
            uploadedName.isNotEmpty &&
            candidateName == uploadedName);
  }

  @override
  void initState() {
    super.initState();
    _bytes = widget.previewBytes;
    if (_bytes == null) {
      widget.imageFile.readAsBytes().then((b) {
        if (mounted) setState(() => _bytes = b);
      });
    }
    _startFlow();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _secondsElapsed = 0;
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  Future<void> _startFlow() async {
    _startElapsedTimer();
    setState(() {
      _stage = _AnalysisStage.uploading;
      _errorMessage = null;
    });

    try {
      // 1. Upload foto ke server via API: POST /mobile/upload
      final uploadRes = await ApiService.instance.uploadPhoto(widget.imageFile);
      if (!mounted) return;

      final photoUrl = uploadRes['photo_url']?.toString();
      final uploadedPath = uploadRes['path']?.toString();
      setState(() {
        _stage = _AnalysisStage.analyzing;
        _uploadedPhotoUrl = photoUrl;
        _isLoadingPrediction = true;
      });

      // 2. Cek hasil segera, lalu polling sampai hasil foto ini tersedia.
      // Popup selesai hanya dibuka setelah hasil FusaShield dan klasifikasi
      // penyakit dari API predictions sama-sama menunjuk foto ini.
      Future<void> checkStatus() async {
        if (!mounted || _statusCheckInProgress) return;
        _statusCheckInProgress = true;
        try {
          final statusRes = await ApiService.instance.getStatus();
          final decision =
              (statusRes['decision'] as Map?)?.cast<String, dynamic>() ?? {};
          final newPhotoUrl = statusRes['photo_url']?.toString();
          final fotoSumber = decision['foto_sumber']?.toString();

          // Ekstrak nama file unik tanpa query params
          final uploadedName = photoUrl?.split('/').last.split('?').first;
          final currentPhotoName =
              newPhotoUrl?.split('/').last.split('?').first;
          final currentSumberName =
              fotoSumber?.split('/').last.split('?').first;

          final hasMatchedPhoto = (uploadedName != null &&
                  currentPhotoName != null &&
                  (currentPhotoName.contains(uploadedName) ||
                      uploadedName.contains(currentPhotoName))) ||
              (uploadedName != null &&
                  currentSumberName != null &&
                  (currentSumberName.contains(uploadedName) ||
                      uploadedName.contains(currentSumberName)));

          PredictionItem? prediction;
          try {
            final predictionRes =
                await ApiService.instance.getLatestPrediction();
            final rawPrediction = predictionRes['latest'];
            if (rawPrediction is Map) {
              final parsed = PredictionItem.fromJson(
                rawPrediction.cast<String, dynamic>(),
              );
              if (_matchesUploadedPhoto(parsed.imagePath, uploadedPath) ||
                  _matchesUploadedPhoto(parsed.imagePath, photoUrl)) {
                prediction = parsed;
              }
            }
          } on ApiException catch (e) {
            _pollingTimer?.cancel();
            _elapsedTimer?.cancel();
            if (mounted) {
              setState(() {
                _stage = _AnalysisStage.error;
                _errorMessage = e.message;
                _isLoadingPrediction = false;
              });
            }
            return;
          }

          final hasMatchedPrediction = prediction != null;
          if (hasMatchedPhoto && hasMatchedPrediction) {
            _pollingTimer?.cancel();
            _elapsedTimer?.cancel();
            // Perbarui LiveStore agar Dashboard & halaman lain ikut update
            await LiveStore.instance.refresh();
            if (mounted) {
              setState(() {
                _stage = _AnalysisStage.completed;
                _resultStatus = statusRes;
                _latestPrediction = prediction;
                _isLoadingPrediction = false;
              });
              widget.onCompleted?.call();
            }
            return;
          }
        } catch (e) {
          debugPrint('Gagal mengecek hasil analisis: $e');
        } finally {
          _statusCheckInProgress = false;
        }
      }

      await checkStatus();
      if (!mounted ||
          _stage == _AnalysisStage.completed ||
          _stage == _AnalysisStage.error) {
        return;
      }
      _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        checkStatus();
      });
    } on ApiException catch (e) {
      _pollingTimer?.cancel();
      _elapsedTimer?.cancel();
      if (mounted) {
        setState(() {
          _stage = _AnalysisStage.error;
          _errorMessage = e.message;
        });
      }
    } catch (_) {
      _pollingTimer?.cancel();
      _elapsedTimer?.cancel();
      if (mounted) {
        setState(() {
          _stage = _AnalysisStage.error;
          _errorMessage =
              'Gagal mengunggah foto. Pastikan koneksi ke server stabil.';
        });
      }
    }
  }

  String _getMitigationAdvice(String? level) {
    switch (level?.toUpperCase()) {
      case 'KRITIS':
        return 'Indikasi Fusarium tinggi atau gejala layu parah! Segera lakukan penyiraman Trichoderma dosis booster dan pisahkan tanaman bergejala agar tidak menular ke tanaman sehat.';
      case 'WASPADA':
        return 'Terdeteksi gejala bercak daun / awal infeksi. Lakukan aplikasi agen hayati mitigasi sedang dan pastikan sirkulasi air tanah lancar.';
      case 'PREVENTIF':
        return 'Risiko mulai naik akibat faktor lingkungan/usia tanaman. Berikan dosis Trichoderma preventif dan pantau kelembapan secara teratur.';
      case 'AMAN':
      default:
        return 'Kondisi daun cabai tergolong sehat & aman. Lanjutkan perawatan standar dan pertahankan aerasi tanah.';
    }
  }

  Widget _previewWidget() {
    if (_bytes != null) {
      return Image.memory(_bytes!, fit: BoxFit.cover);
    }
    return Container(
      color: AppColors.primary.o(0.08),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: const Color(0xFF13221B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.o(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.o(0.45),
            blurRadius: 36,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.o(0.20),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Content scrollable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_stage) {
      case _AnalysisStage.uploading:
        return _buildProgressView(
          title: 'Mengunggah Foto Daun',
          subtitle: 'Kirim gambar daun ke server FusaShield...',
          icon: Icons.cloud_upload_rounded,
          iconColor: AppColors.primary,
          showSpinner: true,
        );

      case _AnalysisStage.analyzing:
        return _buildProgressView(
          title: 'Menganalisis Citra',
          subtitle: 'Sedang menganalisis citra & menunggu perhitungan fuzzy...',
          icon: Icons.psychology_rounded,
          iconColor: Colors.deepPurple,
          showSpinner: true,
          extraInfo:
              'Waktu proses: $_secondsElapsed detik\nModel Keras sedang mengklasifikasikan kelas penyakit di server.',
        );

      case _AnalysisStage.completed:
        return _buildCompletedView();

      case _AnalysisStage.error:
        return _buildErrorView();
    }
  }

  Widget _buildProgressView({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool showSpinner,
    String? extraInfo,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Thumbnail preview foto
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 140,
            height: 140,
            child: _previewWidget(),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: iconColor.o(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 34),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.muted,
            height: 1.4,
          ),
        ),
        if (extraInfo != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.o(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              extraInfo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.muted, height: 1.4),
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (showSpinner)
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
      ],
    );
  }

  Widget _buildCompletedView() {
    final status = _resultStatus ?? LiveStore.instance.status ?? {};
    final decision =
        (status['decision'] as Map?)?.cast<String, dynamic>() ?? {};
    final cnnLabel = decision['cnn_label']?.toString() ?? 'Analisis Selesai';
    final confidence = decision['cnn_confidence'] as num? ?? 0.0;
    final symptomScore = decision['cnn_symptom_score'] as num? ?? 0.0;
    final tingkatDosis = decision['tingkat_dosis']?.toString() ?? 'AMAN';
    final statusMitigasi =
        decision['status_mitigasi']?.toString() ?? 'Mitigasi diterapkan';
    final dosisRekomendasi = decision['dosis_rekomendasi_ml'] as num? ?? 0.0;
    final dosisAktual = decision['dosis_ml'] as num? ?? 0.0;
    final sisaCooldown = decision['sisa_cooldown_detik'] as num? ?? 0;
    final tColor = dosisColor(tingkatDosis);
    final photoUrl = status['photo_url']?.toString() ?? _uploadedPhotoUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header Status
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.o(0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hasil Analisis Citra & Fuzzy',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  Text('Keras CNN & Fuzzy Inference Mamdani',
                      style: AppText.caption),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Foto preview
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 170,
            width: double.infinity,
            color: AppColors.primary.o(0.08),
            child: photoUrl != null && photoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _previewWidget(),
                    errorWidget: (context, url, error) => _previewWidget(),
                  )
                : _previewWidget(),
          ),
        ),
        const SizedBox(height: 18),

        // Kartu Klasifikasi Citra CNN
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.o(0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.o(0.10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('HASIL KLASIFIKASI CNN',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.muted,
                          letterSpacing: 1.1)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC084FC).o(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${LiveStore.fmt(confidence)}% Akurasi',
                      style: const TextStyle(
                          color: Color(0xFFC084FC),
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                cnnLabel,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.speed_rounded,
                      size: 16, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Text(
                    'Skor Gejala Layu: ${LiveStore.fmt(symptomScore)}%',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Kartu Status & Rekomendasi Fuzzy
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tColor.o(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tColor.o(0.4), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('REKOMENDASI FUZZY',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.muted,
                          letterSpacing: 1.1)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: tColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tingkatDosis.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                statusMitigasi,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.science_rounded,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Rekomendasi: ${LiveStore.fmt(dosisRekomendasi)} ml',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                  Text(
                    'Aktual: ${LiveStore.fmt(dosisAktual)} ml',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color:
                          dosisAktual > 0 ? Colors.green : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              if (sisaCooldown > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.o(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Pompa OFF (Masa Cooldown ${(sisaCooldown / 3600).toStringAsFixed(1)} jam aktif untuk melindungi akar cabai dari overdosis).',
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Kartu Keterangan & Tindakan Petani
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.o(0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.o(0.10)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_rounded, color: tColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tindakan yang Disarankan',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getMitigationAdvice(tingkatDosis),
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.muted, height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // ═════════════════════════════════════════════════════════════════
        // HASIL KEDUA: KLASIFIKASI PENYAKIT CABAI (YOLO / SEGMENTASI)
        // ═════════════════════════════════════════════════════════════════
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          height: 1,
          color: Colors.white.o(0.12),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.o(0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.biotech_rounded,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hasil Klasifikasi Penyakit Cabai',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  Text('Model Segmentasi & Rekonstruksi Citra Daun',
                      style: AppText.caption),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_isLoadingPrediction) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.o(0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.o(0.08)),
            ),
            child: const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                      strokeWidth: 2.5, color: AppColors.primary),
                  SizedBox(height: 12),
                  Text(
                    'Memuat hasil klasifikasi penyakit cabai...',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ] else if (_latestPrediction != null) ...[
          PredictionCard(
            item: _latestPrediction!,
            isLatest: true,
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.o(0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.o(0.08)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 20, color: AppColors.muted),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Data klasifikasi penyakit cabai belum tersedia di server.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),

        // Tombol Buka Halaman Hasil & Riwayat Lengkap
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    body: Stack(
                      children: [
                        const FarmBackground(),
                        const ResultsPage(),
                        Positioned(
                          top: 48,
                          left: 16,
                          child: GlassIconButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.history_rounded, size: 18),
            label: const Text(
              'Buka Halaman Hasil & Riwayat Lengkap',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: BorderSide(color: Colors.white.o(0.18)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Tombol Selesai
        PillButton(
          label: 'Selesai & Buka Dashboard',
          icon: Icons.check_circle_outline_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.red.o(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline_rounded,
              color: Colors.red, size: 34),
        ),
        const SizedBox(height: 18),
        const Text(
          'Gagal Menganalisis',
          style: TextStyle(
              fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage ?? 'Terjadi kesalahan saat menghubungi server.',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 13, color: AppColors.muted, height: 1.45),
        ),
        const SizedBox(height: 24),
        PillButton(
          label: 'Coba Lagi',
          icon: Icons.refresh_rounded,
          onTap: _startFlow,
        ),
        const SizedBox(height: 12),
        PillButton(
          label: 'Tutup',
          style: PillStyle.glass,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
