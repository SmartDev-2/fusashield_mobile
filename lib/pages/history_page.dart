import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_group.dart';
import '../widgets/glass_segmented.dart';
import '../widgets/line_chart_painter.dart';
import '../widgets/list_row.dart';
import '../widgets/page_layout.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int _range = 0;

  static const _labels = ['Hari ini', 'Minggu', 'Bulan'];
  static const _values = ['45%', '48%', '44%'];
  static const _series = <List<double>>[
    [38, 42, 40, 47, 45, 43, 49, 45],
    [41, 46, 44, 52, 48, 40, 47, 48],
    [35, 44, 50, 42, 39, 47, 53, 44],
  ];

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      children: [
        const LargeTitle(
          title: 'Riwayat\nMonitoring',
          subtitle: 'Rekaman aktivitas dan kondisi tanaman cabai.',
        ),
        const SizedBox(height: 24),
        GlassSegmented(
          labels: _labels,
          index: _range,
          onChanged: (i) => setState(() => _range = i),
        ),
        const SizedBox(height: 18),
        GlassCard(
          radius: 32,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kelembapan Tanah', style: AppText.caption),
              const SizedBox(height: 4),
              Text(
                _values[_range],
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: CustomPaint(
                    key: ValueKey(_range),
                    painter: LineChartPainter(
                      _series[_range],
                      AppColors.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Data contoh. Grafik asli tampil setelah Firebase terhubung.',
                style: AppText.caption,
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const SectionTitle(
          title: 'Aktivitas Terbaru',
          subtitle: 'Riwayat sistem',
        ),
        const SizedBox(height: 14),
        const GlassGroup(
          children: [
            ListRow(
              icon: Icons.sensors_rounded,
              title: 'Pembacaan sensor',
              subtitle: 'Data akan muncul dari Firebase',
            ),
            ListRow(
              icon: Icons.document_scanner_rounded,
              title: 'Deteksi penyakit',
              subtitle: 'Belum ada riwayat deteksi',
              color: Colors.deepPurple,
            ),
          ],
        ),
      ],
    );
  }
}
