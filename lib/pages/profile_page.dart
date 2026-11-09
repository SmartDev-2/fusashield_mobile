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

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _serverController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _serverController.text = ApiService.baseUrl;
  }

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

  Future<void> _saveServer() async {
    final text = _serverController.text.trim();
    if (text.isEmpty) return;

    setState(() => _saving = true);
    await ApiService.instance.setBaseUrl(text);
    _serverController.text = ApiService.baseUrl;
    await LiveStore.instance.refresh();
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat server berhasil disimpan & dimuat ulang.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      children: [
        const LargeTitle(
          title: 'Pengaturan & Profil',
          subtitle: 'Konfigurasi server dan informasi FusaShield.',
        ),
        const SizedBox(height: 20),
        const Center(
          child: Column(
            children: [
              AppLogo(size: 80),
              SizedBox(height: 12),
              Text(
                'FusaShield',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.ink,
                ),
              ),
              SizedBox(height: 2),
              Text('Smart Chili Monitoring System', style: AppText.body),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.dns_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Konfigurasi Alamat Server',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Tentukan IP / domain cloud server FusaShield Anda.',
                style: AppText.caption,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _serverController,
                keyboardType: TextInputType.url,
                style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'http://192.168.1.100:5000',
                  hintStyle: const TextStyle(color: AppColors.muted),
                  filled: true,
                  fillColor: Colors.black.o(0.25),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.o(0.12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PillButton(
                label: _saving ? 'Menyimpan...' : 'Simpan Server & Refresh',
                icon: Icons.check_circle_outline_rounded,
                onTap: () {
                  if (!_saving) {
                    _saveServer();
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const GlassGroup(
          children: [
            ListRow(
              icon: Icons.info_rounded,
              title: 'Tentang Sistem',
              subtitle: 'Mitigasi Presisi Layu Fusarium (1 Petani, 1 Device, 1 Cloud)',
            ),
            ListRow(
              icon: Icons.developer_mode_rounded,
              title: 'Versi Aplikasi',
              subtitle: 'Version 1.0.0 (Direct Connection)',
              color: Colors.deepPurple,
            ),
          ],
        ),
        const SizedBox(height: 18),
        PillButton(
          label: 'Periksa Koneksi / Pembaruan',
          icon: Icons.wifi_protected_setup_rounded,
          style: PillStyle.glass,
          onTap: () async {
            await LiveStore.instance.refresh();
            if (context.mounted) {
              final ok = LiveStore.instance.online;
              showInfo(
                context,
                ok ? 'Terhubung ke server: ${ApiService.baseUrl}' : 'Gagal terhubung ke server. Periksa alamat server!',
              );
            }
          },
        ),
      ],
    );
  }
}
