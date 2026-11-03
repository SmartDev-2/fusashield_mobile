import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_group.dart';
import '../widgets/list_row.dart';
import '../widgets/page_layout.dart';
import '../widgets/pill_button.dart';
import '../widgets/show_info.dart';

class DetectionPage extends StatelessWidget {
  const DetectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      children: [
        const LargeTitle(
          title: 'Deteksi\nPenyakit',
          subtitle: 'Analisis kondisi tanaman cabai menggunakan PCV dan CNN.',
        ),
        const SizedBox(height: 26),
        GlassCard(
          radius: 34,
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
          child: Column(
            children: [
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accent.o(0.30),
                      AppColors.primary.o(0.10),
                    ],
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.add_a_photo_rounded,
                  size: 54,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Unggah Foto Tanaman',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih foto daun atau tanaman cabai untuk dianalisis oleh model CNN.',
                textAlign: TextAlign.center,
                style: AppText.body,
              ),
              const SizedBox(height: 26),
              PillButton(
                label: 'Pilih dari Galeri',
                icon: Icons.photo_library_rounded,
                onTap: () => showInfo(
                  context,
                  'Fitur unggah foto akan diintegrasikan dengan API CNN.',
                ),
              ),
              const SizedBox(height: 12),
              PillButton(
                label: 'Ambil Foto',
                icon: Icons.photo_camera_rounded,
                style: PillStyle.glass,
                onTap: () => showInfo(
                  context,
                  'Fitur kamera akan diintegrasikan dengan API CNN.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const SectionTitle(
          title: 'Informasi Analisis',
          subtitle: 'Model computer vision',
        ),
        const SizedBox(height: 14),
        const GlassGroup(
          children: [
            ListRow(
              icon: Icons.memory_rounded,
              title: 'CNN Model',
              subtitle: 'Menunggu integrasi model',
              color: Colors.deepPurple,
            ),
            ListRow(
              icon: Icons.api_rounded,
              title: 'Prediction API',
              subtitle: 'Menunggu koneksi backend',
              color: Colors.blue,
            ),
          ],
        ),
      ],
    );
  }
}
