import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/live_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_logo.dart';
import '../widgets/glass_card.dart';
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
          title: 'Tentang & Sistem',
          subtitle: 'Informasi sistem dan status cloud FusaShield.',
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
              Text('Smart Chili Monitoring System', style: AppText.body),
            ],
          ),
        ),
        const SizedBox(height: 28),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.cloud_done_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Cloud Endpoint Terhubung',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Aplikasi terhubung langsung ke layanan cloud produksi FusaShield:',
                style: AppText.caption,
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(160),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withAlpha(20)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.link_rounded, size: 18, color: AppColors.muted),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ApiService.baseUrl,
                        style: TextStyle(
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
              subtitle: '1 Petani • 1 Perangkat • 1 Dedicated Cloud',
            ),
            ListRow(
              icon: Icons.developer_mode_rounded,
              title: 'Versi Aplikasi',
              subtitle: 'Version 1.0.0 (Cloud Connected)',
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
                    ? 'Koneksi ke cloud aktif & data berhasil diperbarui.'
                    : 'Gagal menghubungi cloud (${ApiService.baseUrl}). Periksa koneksi internet Anda.',
              );
            }
          },
        ),
      ],
    );
  }
}
