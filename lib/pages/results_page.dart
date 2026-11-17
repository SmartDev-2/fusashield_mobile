import 'dart:async';

import 'package:flutter/material.dart';

import '../models/prediction_result.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/page_layout.dart';
import '../widgets/prediction_card.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  bool _loading = true;
  String? _errorMessage;

  PredictionItem? _latest;
  List<PredictionItem> _history = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _fetchData(showLoading: false);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData({bool showLoading = true}) async {
    if (!mounted) return;
    setState(() {
      _loading = showLoading;
      _errorMessage = null;
    });

    try {
      // 1. Fetch latest prediction
      final latestRes = await ApiService.instance.getLatestPrediction();
      final latestRaw = latestRes['latest'];
      final latest = latestRaw is Map<String, dynamic>
          ? PredictionItem.fromJson(latestRaw)
          : (latestRaw is Map
              ? PredictionItem.fromJson(latestRaw.cast<String, dynamic>())
              : null);

      // 2. Fetch history (limit 30)
      final historyRes =
          await ApiService.instance.getPredictionHistory(limit: 30);
      final rawItems = historyRes['items'] as List? ?? [];
      final history = rawItems
          .whereType<Map>()
          .map((m) => PredictionItem.fromJson(m.cast<String, dynamic>()))
          .toList();

      if (!mounted) return;
      setState(() {
        _latest = latest;
        _history = history;
        _loading = false;
        _errorMessage = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat hasil klasifikasi ($e).';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: LargeTitle(
                eyebrow: 'HASIL & RIWAYAT KLASIFIKASI',
                title: 'Penyakit\nCabai',
                subtitle:
                    'Hasil segmentasi & klasifikasi citra daun dari API FusaShield.',
              ),
            ),
            IconButton(
              onPressed: _loading ? null : _fetchData,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Icon(Icons.refresh_rounded,
                      color: AppColors.primary, size: 26),
              tooltip: 'Perbarui Data',
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Error State
        if (_errorMessage != null) ...[
          GlassCard(
            radius: 24,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Color(0xFFF87171), size: 44),
                const SizedBox(height: 12),
                const Text(
                  'Gagal Mengambil Data',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _fetchData,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Loading State
        if (_loading && _errorMessage == null) ...[
          GlassCard(
            radius: 24,
            padding: const EdgeInsets.all(32),
            child: const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Memuat hasil klasifikasi dari server...',
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Content
        if (!_loading && _errorMessage == null) ...[
          // ── Section 1: Klasifikasi Terbaru ──
          const SectionTitle(
            title: 'Klasifikasi Terbaru',
            subtitle: 'Hasil analisis citra daun terakhir yang diproses',
          ),
          const SizedBox(height: 14),

          if (_latest != null)
            PredictionCard(item: _latest!, isLatest: true)
          else
            GlassCard(
              radius: 24,
              padding: const EdgeInsets.all(24),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.muted, size: 24),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Belum ada klasifikasi terbaru. Silakan unggah foto daun cabai di menu Deteksi.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.muted, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),

          // ── Section 2: Riwayat Klasifikasi ──
          SectionTitle(
            title: 'Riwayat Klasifikasi',
            subtitle:
                'Daftar riwayat klasifikasi citra (${_history.length} data tersimpan)',
          ),
          const SizedBox(height: 14),

          if (_history.isEmpty)
            GlassCard(
              radius: 24,
              padding: const EdgeInsets.all(24),
              child: const Center(
                child: Text(
                  'Riwayat klasifikasi masih kosong.',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, i) {
                return PredictionCard(
                  item: _history[i],
                  isLatest: false,
                  defaultExpanded: false,
                );
              },
            ),
        ],
      ],
    );
  }
}
