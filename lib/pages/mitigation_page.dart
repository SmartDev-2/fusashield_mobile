import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/live_store.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_group.dart';
import '../widgets/list_row.dart';
import '../widgets/page_layout.dart';
import '../widgets/pill_button.dart';
import '../widgets/show_info.dart';

class MitigationPage extends StatefulWidget {
  const MitigationPage({super.key});

  @override
  State<MitigationPage> createState() => _MitigationPageState();
}

class _MitigationPageState extends State<MitigationPage> {
  bool _autoIrrigation = false;
  bool _aiAlerts = true;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LiveStore.instance,
      builder: (context, _) {
        final s = LiveStore.instance;
        return PageScaffold(
      children: [
        const LargeTitle(
          title: 'Mitigasi\nTanaman',
          subtitle: 'Rekomendasi dan pengelolaan tindakan mitigasi.',
        ),
        const SizedBox(height: 26),
        Container(
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B4E38), Color(0xFF0F2E22)],
            ),
            border: Border.all(color: AppColors.primary.o(0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.o(0.45),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: AppColors.primary.o(0.18),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.o(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.o(0.3)),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Sistem Mitigasi Cerdas',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Rekomendasi tindakan berdasarkan data sensor dan hasil analisis tanaman.',
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 22),
              PillButton(
                label: 'Lihat Rekomendasi',
                icon: Icons.auto_awesome_rounded,
                style: PillStyle.white,
                onTap: () => showInfo(context, s.recommendation),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const SectionTitle(
          title: 'Status Mitigasi',
          subtitle: 'Kondisi tindakan saat ini',
        ),
        const SizedBox(height: 14),
        GlassGroup(
          children: [
            ListRow(
              icon: Icons.water_drop_rounded,
              title: 'Irigasi otomatis',
              subtitle: s.pumpSummary,
              color: Colors.blue,
              trailing: Switch.adaptive(
                value: _autoIrrigation,
                activeTrackColor: AppColors.accent,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _autoIrrigation = v);
                },
              ),
            ),
            ListRow(
              icon: Icons.psychology_rounded,
              title: 'Peringatan AI',
              subtitle: s.analysisSummary,
              color: Colors.deepPurple,
              trailing: Switch.adaptive(
                value: _aiAlerts,
                activeTrackColor: AppColors.accent,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _aiAlerts = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        PillButton(
          label: 'Siram Sekarang',
          icon: Icons.shower_rounded,
          style: PillStyle.glass,
          onTap: () => showInfo(context, 'Penyiraman manual belum tersedia. Pompa dijalankan otomatis oleh sistem fuzzy.'),
        ),
      ],
    );
      },
    );
  }
}
