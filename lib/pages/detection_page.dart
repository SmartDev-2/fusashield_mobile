import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/live_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/analysis_bottom_sheet.dart';
import '../widgets/farm_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_group.dart';
import '../widgets/glass_icon_button.dart';
import '../widgets/list_row.dart';
import '../widgets/page_layout.dart';
import '../widgets/pill_button.dart';
import '../widgets/show_info.dart';
import 'results_page.dart';

class DetectionPage extends StatefulWidget {
  const DetectionPage({super.key});

  @override
  State<DetectionPage> createState() => _DetectionPageState();
}

class _DetectionPageState extends State<DetectionPage> {
  Uint8List? _lastPickedBytes;

  Future<void> _handleImageSelection(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (x == null) return;

      final size = await x.length();
      if (size > 5 * 1024 * 1024) {
        if (mounted) {
          showInfo(context, 'Ukuran foto maksimal 5 MB.');
        }
        return;
      }

      final bytes = await x.readAsBytes();
      if (mounted) {
        setState(() => _lastPickedBytes = bytes);
      }

      // Tampilkan Modal Bottom Sheet untuk alur upload & analisis polling
      if (!mounted) return;
      await AnalysisBottomSheet.show(
        context,
        imageFile: x,
        previewBytes: bytes,
        onCompleted: () {
          if (mounted) setState(() {});
        },
      );
    } catch (e) {
      if (mounted) {
        showInfo(context, 'Tidak dapat memproses gambar: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LiveStore.instance,
      builder: (context, _) {
        final s = LiveStore.instance;

        return PageScaffold(
          children: [
            const LargeTitle(
              eyebrow: 'COMPUTER VISION CNN',
              title: 'Deteksi\nPenyakit',
              subtitle: 'Ambil foto daun cabai untuk dianalisis oleh AI & Fuzzy.',
            ),
            const SizedBox(height: 24),

            // Card Upload & Action Buttons
            GlassCard(
              radius: 34,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: double.infinity,
                      height: 190,
                      decoration: BoxDecoration(
                        color: Colors.black.o(0.25),
                        border: Border.all(color: Colors.white.o(0.14), width: 1.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: _lastPickedBytes != null
                          ? Image.memory(_lastPickedBytes!, fit: BoxFit.cover)
                          : s.photoUrl != null && s.photoUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: s.photoUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      const Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) =>
                                      const Center(
                                    child: Icon(Icons.broken_image_rounded,
                                        size: 44, color: Colors.grey),
                                  ),
                                )
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_rounded,
                                        size: 52,
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'Pilih foto daun cabai',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text('Kamera langsung atau galeri (maks 5 MB)', style: AppText.caption),
                                    ],
                                  ),
                                ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Pindai Daun Berpenyakit',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Arahkan kamera ke daun cabai yang bergejala (bercak, kuning, atau layu) untuk klasifikasi CNN dan kalkulasi dosis mitigasi.',
                    textAlign: TextAlign.center,
                    style: AppText.body,
                  ),
                  const SizedBox(height: 22),
                  PillButton(
                    label: 'Scan via Kamera',
                    icon: Icons.photo_camera_rounded,
                    onTap: () => _handleImageSelection(ImageSource.camera),
                  ),
                  const SizedBox(height: 12),
                  PillButton(
                    label: 'Unggah dari Galeri',
                    icon: Icons.photo_library_rounded,
                    style: PillStyle.glass,
                    onTap: () => _handleImageSelection(ImageSource.gallery),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Card Shortcut ke Hasil & Riwayat Klasifikasi Penyakit Cabai
            GlassCard(
              radius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              onTap: () {
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
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.o(0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.o(0.30)),
                    ),
                    child: const Icon(Icons.biotech_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hasil & Riwayat Klasifikasi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Lihat gambar praproses, segmentasi, rekonstruksi & rekomendasi penyakit.',
                          style: AppText.caption,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.muted, size: 16),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const SectionTitle(
              title: 'Hasil Analisis Terakhir',
              subtitle: 'Data CNN & Fuzzy dari server',
            ),
            const SizedBox(height: 14),
            GlassGroup(
              children: [
                ListRow(
                  icon: Icons.document_scanner_rounded,
                  title: s.cnnLabel ?? 'Belum ada deteksi',
                  subtitle:
                      'Keyakinan ${LiveStore.fmt(s.cnnConfidence)}% · Skor gejala ${LiveStore.fmt(s.cnnSymptomScore)}%',
                  color: Colors.deepPurple,
                ),
                ListRow(
                  icon: Icons.eco_rounded,
                  title: s.statusMitigasi ?? 'Menunggu data mitigasi',
                  subtitle:
                      'Tingkat ${s.tingkatDosis ?? '-'} · Dosis rekomendasi ${LiveStore.fmt(s.dosisRekomendasi)} ml',
                  color: dosisColor(s.tingkatDosis),
                ),
                ListRow(
                  icon: Icons.water_drop_rounded,
                  title: 'Pompa ${s.status?['sensors']?['pump_status'] ?? '–'}',
                  subtitle: s.alasanBlokir ?? 'Dosis aktual: ${LiveStore.fmt(s.dosisAktual)} ml',
                  color: Colors.blue,
                ),
              ],
            ),

            const SizedBox(height: 30),
            const SectionTitle(
              title: 'Informasi Model AI',
              subtitle: 'Pipeline pemrosesan FusaShield',
            ),
            const SizedBox(height: 14),
            const GlassGroup(
              children: [
                ListRow(
                  icon: Icons.memory_rounded,
                  title: 'Klasifikasi CNN',
                  subtitle: 'Mendeteksi 6 kelas penyakit daun cabai di server Keras',
                  color: Colors.deepPurple,
                ),
                ListRow(
                  icon: Icons.calculate_rounded,
                  title: 'Inferensi Fuzzy Mamdani',
                  subtitle: 'Kombinasi skor CNN + HST + suhu + kelembapan',
                  color: AppColors.primary,
                ),
                ListRow(
                  icon: Icons.shield_rounded,
                  title: 'Mitigasi Trichoderma',
                  subtitle: 'Kontrol otomatis pompa hayati dengan cooldown',
                  color: Colors.teal,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
