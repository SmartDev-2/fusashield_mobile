import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/live_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_logo.dart';
import '../widgets/glass_group.dart';
import '../widgets/list_row.dart';
import '../widgets/page_layout.dart';
import '../widgets/pill_button.dart';
import '../widgets/show_info.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      children: [
        const LargeTitle(
          title: 'Tentang & Profil',
          subtitle: 'Informasi sistem FusaShield.',
        ),
        const SizedBox(height: 24),
        const Center(
          child: Column(
            children: [
              AppLogo(size: 88),
              SizedBox(height: 14),
              Text(
                'FusaShield',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: AppColors.ink,
                ),
              ),
              SizedBox(height: 4),
              Text('Sistem Mitigasi Presisi Layu Fusarium', style: AppText.body),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withAlpha(40)),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_done_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cloud Server',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        )),
                    Text(
                      ApiService.baseUrl,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const GlassGroup(
          children: [
            ListRow(
              icon: Icons.shield_rounded,
              title: 'Sistem Proteksi',
              subtitle: 'Mitigasi Presisi Layu Fusarium Berbasis IoT & Agen Hayati',
            ),
            ListRow(
              icon: Icons.verified_user_rounded,
              title: 'Arsitektur Sistem',
              subtitle: '1 Petani · 1 Perangkat · 1 Dedicated Cloud',
            ),
            ListRow(
              icon: Icons.developer_mode_rounded,
              title: 'Versi Aplikasi',
              subtitle: 'Version 1.0.0',
              color: Colors.deepPurple,
            ),
          ],
        ),
        const SizedBox(height: 22),
        PillButton(
          label: 'Periksa Status Koneksi',
          icon: Icons.wifi_protected_setup_rounded,
          onTap: () async {
            await LiveStore.instance.refresh();
            if (context.mounted) {
              final ok = LiveStore.instance.online;
              showInfo(
                context,
                ok
                    ? 'Koneksi aktif! Server merespons normal.'
                    : 'Gagal terhubung. Periksa koneksi internet.',
              );
            }
          },
        ),
      ],
    );
  }
}
