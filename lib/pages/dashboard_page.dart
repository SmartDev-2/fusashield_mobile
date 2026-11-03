import 'package:flutter/material.dart';

import '../models/sensor_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_logo.dart';
import '../widgets/glass_group.dart';
import '../widgets/glass_icon_button.dart';
import '../widgets/list_row.dart';
import '../widgets/page_layout.dart';
import '../widgets/sensor_card.dart';
import '../widgets/show_info.dart';
import '../widgets/status_pill.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      children: [
        Row(
          children: [
            const AppLogo(),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FusaShield',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppColors.ink,
                    ),
                  ),
                  Text('Smart Chili Monitoring System', style: AppText.caption),
                ],
              ),
            ),
            GlassIconButton(
              icon: Icons.notifications_none_rounded,
              badge: true,
              onTap: () => showInfo(context, 'Belum ada notifikasi baru.'),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const LargeTitle(
          eyebrow: 'RINGKASAN',
          title: 'Dashboard',
          subtitle: 'Pantau kondisi tanaman cabai Anda.',
        ),
        const SizedBox(height: 22),
        const _DeviceHero(),
        const SizedBox(height: 30),
        const SectionTitle(
          title: 'Kondisi Lingkungan',
          subtitle: 'Data sensor tanaman cabai',
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dummySensors.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 148,
          ),
          itemBuilder: (_, i) => SensorCard(data: dummySensors[i]),
        ),
        const SizedBox(height: 30),
        const SectionTitle(
          title: 'Kondisi Tanaman',
          subtitle: 'Hasil pemantauan terakhir',
        ),
        const SizedBox(height: 14),
        GlassGroup(
          children: [
            ListRow(
              icon: Icons.eco_rounded,
              title: 'Cabai #01',
              subtitle: 'Menunggu hasil analisis PCV',
              onTap: () => showInfo(context, 'Detail tanaman segera hadir.'),
            ),
          ],
        ),
        const SizedBox(height: 30),
        const SectionTitle(
          title: 'Aktivitas Sistem',
          subtitle: 'Ringkasan perangkat',
        ),
        const SizedBox(height: 14),
        const GlassGroup(
          children: [
            ListRow(
              icon: Icons.sensors_rounded,
              title: 'Sensor aktif',
              subtitle: 'Monitoring lingkungan tanaman',
            ),
            ListRow(
              icon: Icons.cloud_done_rounded,
              title: 'Firebase',
              subtitle: 'Menunggu sinkronisasi data',
              color: Colors.blue,
            ),
          ],
        ),
      ],
    );
  }
}

class _DeviceHero extends StatelessWidget {
  const _DeviceHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.o(0.40),
            blurRadius: 34,
            offset: const Offset(0, 18),
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ESP32-S3',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 19,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Perangkat monitoring terhubung',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const StatusPill(label: 'ONLINE'),
                  ],
                ),
                const SizedBox(height: 20),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeroChip(
                      icon: Icons.sensors_rounded,
                      label: 'Sensor aktif',
                    ),
                    _HeroChip(
                      icon: Icons.sync_rounded,
                      label: 'Menunggu sinkronisasi',
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
