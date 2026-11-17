import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/prediction_result.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'glass_card.dart';

class PredictionCard extends StatelessWidget {
  final PredictionItem item;
  final bool isLatest;
  final bool defaultExpanded;

  const PredictionCard({
    super.key,
    required this.item,
    this.isLatest = false,
    this.defaultExpanded = true,
  });

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '–';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final y = dt.year.toString();
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$d-$m-$y $h:$min';
    } catch (_) {
      return raw;
    }
  }

  Color _attentionColor(String? attention) {
    final lower = attention?.toLowerCase() ?? '';
    if (lower.contains('tinggi') || lower.contains('kritis') || lower.contains('bahaya')) {
      return const Color(0xFFF87171);
    }
    if (lower.contains('sedang') || lower.contains('waspada') || lower.contains('perhatian')) {
      return const Color(0xFFFB923C);
    }
    if (lower.contains('rendah') || lower.contains('aman')) {
      return const Color(0xFF34D399);
    }
    return AppColors.accent;
  }

  void _showImageDialog(BuildContext context, String title, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.o(0.85),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 240,
                    color: Colors.white.o(0.05),
                    child: const Center(
                      child: Icon(Icons.broken_image_rounded, size: 48, color: AppColors.muted),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pred = item.prediction ?? 'Tidak diketahui';
    final conf = item.confidence;
    final margin = item.margin != null ? item.margin!.toStringAsFixed(3) : '–';
    final maskRatio = item.maskRatio != null ? item.maskRatio!.toStringAsFixed(2) : '–';
    final dateStr = _formatDate(item.processedAt);
    final rec = item.recommendation;
    final attColor = _attentionColor(rec.tingkatPerhatian);

    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.all(20),
      elevated: isLatest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Tag Terbaru & Waktu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isLatest)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.o(0.20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.o(0.40)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, color: AppColors.primary, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'KLASIFIKASI TERBARU',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history_rounded, size: 14, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text('Riwayat Klasifikasi', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              Text(
                dateStr,
                style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Judul Prediksi & Badge Keyakinan
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pred.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (item.imagePath != null && item.imagePath!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.imagePath!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (conf != null && conf.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).o(0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF38BDF8).o(0.35)),
                  ),
                  child: Text(
                    conf,
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Metrik: Margin & Mask Ratio
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.o(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.o(0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn('Margin Skor', margin, Icons.analytics_outlined),
                Container(height: 24, width: 1, color: Colors.white.o(0.12)),
                _buildMetricColumn('Rasio Mask', maskRatio, Icons.pie_chart_outline_rounded),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Gambar Hasil Pemrosesan ──
          const Text(
            'GAMBAR HASIL PEMROSESAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.muted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          _buildProcessedImages(context),
          const SizedBox(height: 18),

          // ── Rekomendasi ──
          if (rec.hasAnyField) ...[
            const Text(
              'REKOMENDASI & PENANGANAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.muted,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            _buildRecommendationSection(context, rec, attColor),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProcessedImages(BuildContext context) {
    final images = item.processedImages;

    if (!images.hasAnyImage) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.o(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.o(0.06)),
        ),
        child: const Row(
          children: [
            Icon(Icons.image_not_supported_outlined, size: 20, color: AppColors.muted),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Gambar hasil proses belum tersedia.',
                style: TextStyle(fontSize: 13, color: AppColors.muted, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        if (images.preprocess != null && images.preprocess!.isNotEmpty)
          Expanded(child: _buildImageThumbnail(context, 'Praproses', images.preprocess!)),
        if (images.preprocess != null && images.preprocess!.isNotEmpty) const SizedBox(width: 8),
        if (images.segmentation != null && images.segmentation!.isNotEmpty)
          Expanded(child: _buildImageThumbnail(context, 'Segmentasi', images.segmentation!)),
        if (images.segmentation != null && images.segmentation!.isNotEmpty) const SizedBox(width: 8),
        if (images.reconstruction != null && images.reconstruction!.isNotEmpty)
          Expanded(child: _buildImageThumbnail(context, 'Rekonstruksi', images.reconstruction!)),
      ],
    );
  }

  Widget _buildImageThumbnail(BuildContext context, String title, String url) {
    return GestureDetector(
      onTap: () => _showImageDialog(context, title, url),
      child: Container(
        height: 105,
        decoration: BoxDecoration(
          color: Colors.black.o(0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.o(0.12)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_rounded, size: 24, color: AppColors.muted),
                  ),
                ),
              ),
            ),
            // Badge label nama proses
            Positioned(
              left: 4,
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.o(0.70),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationSection(
    BuildContext context,
    PredictionRecommendation rec,
    Color attColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.o(0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.o(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rec.nama != null && rec.nama!.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    rec.nama!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (rec.tingkatPerhatian != null && rec.tingkatPerhatian!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: attColor.o(0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: attColor.o(0.40)),
                    ),
                    child: Text(
                      rec.tingkatPerhatian!,
                      style: TextStyle(
                        color: attColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (rec.tindakanSegera != null && rec.tindakanSegera!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).o(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEF4444).o(0.30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFF87171)),
                      SizedBox(width: 6),
                      Text(
                        'TINDAKAN SEGERA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF87171),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rec.tindakanSegera!,
                    style: const TextStyle(fontSize: 13, color: AppColors.ink, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (rec.kemungkinanPenyebab != null && rec.kemungkinanPenyebab!.isNotEmpty)
            _buildRecField('Kemungkinan Penyebab', rec.kemungkinanPenyebab!, Icons.help_outline_rounded),
          if (rec.budidaya != null && rec.budidaya!.isNotEmpty)
            _buildRecField('Pengendalian Budidaya', rec.budidaya!, Icons.agriculture_rounded),
          if (rec.hayati != null && rec.hayati!.isNotEmpty)
            _buildRecField('Pengendalian Hayati (Trichoderma dsb)', rec.hayati!, Icons.eco_rounded),
          if (rec.kimia != null && rec.kimia!.isNotEmpty)
            _buildRecField('Pengendalian Kimiawi', rec.kimia!, Icons.science_outlined),
          if (rec.pemantauan != null && rec.pemantauan!.isNotEmpty)
            _buildRecField('Langkah Pemantauan', rec.pemantauan!, Icons.visibility_outlined),
        ],
      ),
    );
  }

  Widget _buildRecField(String title, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.ink,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
