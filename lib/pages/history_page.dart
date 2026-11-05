import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/live_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_segmented.dart';
import '../widgets/line_chart_painter.dart';
import '../widgets/page_layout.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int _metric = 0;

  static const _labels = ['Tanah', 'Suhu', 'Gejala'];
  static const _titles = ['Kelembapan Tanah', 'Suhu', 'Gejala Daun (CNN)'];
  static const _units = ['%', '°C', '%'];
  static const _keys = ['soil_moisture', 'temperature', 'cnn_symptom_score'];
  static const _colors = <Color>[AppColors.accent, Colors.orange, Colors.redAccent];

  void _showDetail(BuildContext context, Map<String, dynamic> item) {
    final tColor = dosisColor(item['tingkat_dosis']?.toString());
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.o(0.15),
              blurRadius: 30,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item['cnn_label']?.toString() ?? 'Deteksi',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: tColor.o(0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tColor, width: 1.2),
                  ),
                  child: Text(
                    (item['tingkat_dosis'] ?? 'AMAN').toString(),
                    style: TextStyle(
                      color: tColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item['last_updated']?.toString() ?? '-',
              style: AppText.caption,
            ),
            const SizedBox(height: 16),
            if (item['photo_url'] != null && (item['photo_url'] as String).isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: item['photo_url'],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              item['status_mitigasi']?.toString() ?? '-',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _infoBlock(
                    'Keyakinan CNN',
                    '${LiveStore.fmt(item['cnn_confidence'])}%',
                  ),
                ),
                Expanded(
                  child: _infoBlock(
                    'Skor Gejala',
                    '${LiveStore.fmt(item['cnn_symptom_score'])}%',
                  ),
                ),
                Expanded(
                  child: _infoBlock(
                    'Dosis Pompa',
                    '${LiveStore.fmt(item['dosis_ml'])} ml',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _infoBlock(
                    'Suhu',
                    '${LiveStore.fmt(item['temperature'])}°C',
                  ),
                ),
                Expanded(
                  child: _infoBlock(
                    'Udara',
                    '${LiveStore.fmt(item['humidity'])}%',
                  ),
                ),
                Expanded(
                  child: _infoBlock(
                    'Tanah',
                    '${LiveStore.fmt(item['soil_moisture'])}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoBlock(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primary.o(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LiveStore.instance,
      builder: (context, _) {
        final s = LiveStore.instance;
        final data = s.series(_keys[_metric]);
        final latest = data.isEmpty ? '–' : '${LiveStore.fmt(data.last)}${_units[_metric]}';

        return PageScaffold(
          children: [
            const LargeTitle(
              title: 'Riwayat\nMonitoring',
              subtitle: 'Rekaman aktivitas dan riwayat keputusan fuzzy.',
            ),
            const SizedBox(height: 24),
            GlassSegmented(
              labels: _labels,
              index: _metric,
              onChanged: (i) => setState(() => _metric = i),
            ),
            const SizedBox(height: 18),
            GlassCard(
              radius: 32,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_titles[_metric], style: AppText.caption),
                  const SizedBox(height: 4),
                  Text(
                    latest,
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 170,
                    width: double.infinity,
                    child: data.length < 2
                        ? const Center(
                            child: Text('Belum cukup data untuk grafik.', style: AppText.caption),
                          )
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            child: CustomPaint(
                              key: ValueKey(_metric),
                              painter: LineChartPainter(data, _colors[_metric]),
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.online
                        ? 'Data dari server (${data.length} titik riwayat).'
                        : (s.error ?? 'Menghubungkan…'),
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const SectionTitle(
              title: 'Daftar Riwayat Keputusan',
              subtitle: 'Urutan terbaru dari server (pilih kartu untuk detail)',
            ),
            const SizedBox(height: 14),
            if (s.history.isEmpty)
              GlassCard(
                radius: 24,
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.history_rounded, size: 42, color: AppColors.muted.o(0.5)),
                      const SizedBox(height: 10),
                      const Text(
                        'Belum ada data riwayat',
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.online ? 'Data riwayat akan muncul otomatis.' : (s.error ?? 'Menghubungkan ke server…'),
                        textAlign: TextAlign.center,
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: s.history.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final h = s.history[index];
                  final tColor = dosisColor(h['tingkat_dosis']?.toString());
                  final photo = h['photo_url']?.toString();

                  return GlassCard(
                    radius: 22,
                    padding: const EdgeInsets.all(16),
                    onTap: () => _showDetail(context, h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (photo != null && photo.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(
                              imageUrl: photo,
                              width: 58,
                              height: 58,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 58,
                                height: 58,
                                color: AppColors.primary.o(0.1),
                                child: const Icon(Icons.image, size: 20, color: Colors.grey),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 58,
                                height: 58,
                                color: AppColors.primary.o(0.1),
                                child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: tColor.o(0.14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.document_scanner_rounded,
                              color: tColor,
                              size: 26,
                            ),
                          ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      h['cnn_label']?.toString() ?? 'Pemeriksaan Daun',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: tColor.o(0.16),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      (h['tingkat_dosis'] ?? '-').toString(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: tColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                h['last_updated']?.toString() ?? '-',
                                style: AppText.caption,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Dosis: ${LiveStore.fmt(h['dosis_ml'])} ml · Suhu: ${LiveStore.fmt(h['temperature'])}°C · Tanah: ${LiveStore.fmt(h['soil_moisture'])}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink.o(0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.muted,
                          size: 20,
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
