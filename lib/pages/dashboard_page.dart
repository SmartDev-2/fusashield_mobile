import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/live_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/analysis_bottom_sheet.dart';
import '../widgets/app_logo.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_group.dart';
import '../widgets/glass_icon_button.dart';
import '../widgets/list_row.dart';
import '../widgets/page_layout.dart';
import '../widgets/pill_button.dart';
import '../widgets/sensor_card.dart';
import '../widgets/show_info.dart';
import '../widgets/status_pill.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LiveStore.instance,
      builder: (context, _) {
        final s = LiveStore.instance;
        final tColor = dosisColor(s.tingkatDosis);

        return PageScaffold(
          children: [
            // Top Bar
            Row(
              children: [
                const AppLogo(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FusaShield',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppColors.ink,
                        ),
                      ),
                      Text('Perangkat: ${s.device}', style: AppText.caption),
                    ],
                  ),
                ),
                GlassIconButton(
                  icon: Icons.refresh_rounded,
                  onTap: () {
                    LiveStore.instance.refresh();
                    showInfo(context, 'Memperbarui data...');
                  },
                ),
                const SizedBox(width: 8),
                GlassIconButton(
                  icon: Icons.notifications_none_rounded,
                  badge: s.tingkatDosis != null && s.tingkatDosis != 'AMAN',
                  onTap: () => showInfo(context, s.alertText),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Header Title
            const LargeTitle(
              eyebrow: 'MONITORING IOT & AI',
              title: 'Dashboard',
              subtitle: 'Pantau kondisi realtime tanaman cabai Anda.',
            ),
            const SizedBox(height: 20),

            // Device Hero Banner
            _DeviceHero(online: s.online, device: s.device, info: s.updatedLabel),
            const SizedBox(height: 16),

            // Warning Alasan Blokir jika ada
            if (s.alasanBlokir != null && s.alasanBlokir!.isNotEmpty) ...[
              _WarningCard(
                icon: Icons.block_rounded,
                color: Colors.red,
                title: 'Pompa Dinonaktifkan',
                message: s.alasanBlokir!,
              ),
              const SizedBox(height: 14),
            ],

            // Warning Foto Basi jika true
            if (s.fotoBasi) ...[
              _WarningCard(
                icon: Icons.history_rounded,
                color: Colors.amber.shade800,
                title: 'Foto Daun Kedaluwarsa',
                message:
                    'Foto diambil ${LiveStore.fmt(s.fotoUmurJam)} jam yang lalu. Disarankan upload foto daun baru untuk akurasi optimal.',
              ),
              const SizedBox(height: 14),
            ],

            // Decision & Tingkat Dosis Card
            const SectionTitle(
              title: 'Keputusan Mitigasi Fuzzy',
              subtitle: 'Rekomendasi tindakan otomatis',
            ),
            const SizedBox(height: 12),
            GlassCard(
              radius: 28,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TINGKAT DOSIS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.muted,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: tColor.o(0.18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: tColor, width: 1.5),
                        ),
                        child: Text(
                          s.tingkatDosis ?? 'MENUNGGU',
                          style: TextStyle(
                            color: tColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.statusMitigasi ?? 'Belum ada keputusan mitigasi.',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, thickness: 1, color: Colors.white.o(0.08)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricItem(
                          label: 'Dosis Rekomendasi',
                          value: '${LiveStore.fmt(s.dosisRekomendasi)} ml',
                          icon: Icons.science_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      Container(width: 1, height: 42, color: Colors.white.o(0.08)),
                      Expanded(
                        child: _MetricItem(
                          label: 'Dosis Aktual Pompa',
                          value: '${LiveStore.fmt(s.dosisAktual)} ml',
                          icon: Icons.water_drop_rounded,
                          color: (s.dosisAktual ?? 0) > 0 ? const Color(0xFF34D399) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  if (s.sisaCooldownDetik != null && s.sisaCooldownDetik! > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.o(0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blueGrey.o(0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 18, color: Color(0xFF93C5FD)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Masa Cooldown: sisa ${(s.sisaCooldownDetik! / 3600).toStringAsFixed(1)} jam. Pompa ditahan OFF agar tanaman tidak overdosis.',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (s.faseHst != null && s.faseHst!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.o(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.o(0.20)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.faseHst!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 26),

            // Foto Daun & Hasil CNN
            const SectionTitle(
              title: 'Foto Daun & Analisis CNN',
              subtitle: 'Klasifikasi citra penyakit daun',
            ),
            const SizedBox(height: 12),
            GlassCard(
              radius: 28,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      color: AppColors.primary.o(0.08),
                      child: s.photoUrl != null && s.photoUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: s.photoUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Gagal memuat foto', style: AppText.caption),
                                  ],
                                ),
                              ),
                            )
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo_library_outlined, size: 48, color: AppColors.muted),
                                  SizedBox(height: 8),
                                  Text('Belum ada foto daun', style: AppText.caption),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.cnnLabel ?? 'Belum ada deteksi',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Confidence: ${LiveStore.fmt(s.cnnConfidence)}% · Gejala: ${LiveStore.fmt(s.cnnSymptomScore)}%',
                            style: AppText.caption,
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.o(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          s.fotoUmurJam != null ? '${LiveStore.fmt(s.fotoUmurJam)} jam lalu' : '–',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PillButton(
                    label: 'Pindai Daun Baru',
                    icon: Icons.camera_alt_rounded,
                    style: PillStyle.glass,
                    onTap: () => _showQuickScanPicker(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // Kondisi Lingkungan Sensor Grid
            const SectionTitle(
              title: 'Kondisi Lingkungan',
              subtitle: 'Data sensor realtime dari ESP32',
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: s.sensors.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 148,
              ),
              itemBuilder: (_, i) => SensorCard(data: s.sensors[i]),
            ),
            const SizedBox(height: 26),

            // Aktivitas Sistem
            const SectionTitle(
              title: 'Aktivitas Sistem',
              subtitle: 'Ringkasan konektivitas',
            ),
            const SizedBox(height: 12),
            GlassGroup(
              children: [
                ListRow(
                  icon: Icons.sensors_rounded,
                  title: s.online ? 'Sensor Aktif' : 'Sensor Tidak Terbaca',
                  subtitle: s.sensorSummary,
                ),
                ListRow(
                  icon: Icons.cloud_done_rounded,
                  title: 'Server API',
                  subtitle: s.online
                      ? 'Tersambung ke server FusaShield'
                      : (s.error ?? 'Menghubungkan…'),
                  color: s.online ? Colors.blue : Colors.redAccent,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _showQuickScanPicker(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF13221B),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: Colors.white.o(0.12)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.o(0.20),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pindai Daun Cabai',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded, color: AppColors.primary),
                title: const Text('Ambil Foto Kamera', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                subtitle: const Text('Scan langsung dari tanaman', style: TextStyle(color: AppColors.muted)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                subtitle: const Text('Unggah berkas foto daun tersimpan', style: TextStyle(color: AppColors.muted)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !context.mounted) return;

    final x = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (x == null || !context.mounted) return;

    final len = await x.length();
    if (!context.mounted) return;
    if (len > 5 * 1024 * 1024) {
      showInfo(context, 'Ukuran foto maksimal 5 MB');
      return;
    }
    final bytes = await x.readAsBytes();
    if (!context.mounted) return;
    AnalysisBottomSheet.show(context, imageFile: x, previewBytes: bytes);
  }
}

class _WarningCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _WarningCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.o(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.o(0.5), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink.o(0.85),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: AppText.caption),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _DeviceHero extends StatelessWidget {
  final bool online;
  final String device;
  final String info;

  const _DeviceHero({
    required this.online,
    required this.device,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
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
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -40,
            child: _circle(170, Colors.white.o(0.10)),
          ),
          Positioned(
            bottom: -60,
            left: -30,
            child: _circle(150, Colors.white.o(0.07)),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.o(0.18),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.o(0.3)),
                      ),
                      child: const Icon(
                        Icons.sensors_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 19,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Node IoT Smart Cabai',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusPill(label: online ? 'ONLINE' : 'OFFLINE'),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeroChip(
                      icon: Icons.sensors_rounded,
                      label: online ? 'Sensor Aktif' : 'Tidak Ada Data',
                    ),
                    _HeroChip(
                      icon: Icons.sync_rounded,
                      label: info,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.o(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.o(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
