import 'package:flutter/material.dart';

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
          title: 'Profil',
          subtitle: 'Informasi aplikasi FusaShield.',
        ),
        const SizedBox(height: 28),
        const Center(
          child: Column(
            children: [
              AppLogo(size: 96),
              SizedBox(height: 18),
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
        const SizedBox(height: 32),
        const GlassGroup(
          children: [
            ListRow(
              icon: Icons.info_rounded,
              title: 'Tentang Aplikasi',
              subtitle: 'Sistem monitoring dan mitigasi layu Fusarium',
            ),
            ListRow(
              icon: Icons.developer_mode_rounded,
              title: 'Versi Aplikasi',
              subtitle: 'Version 1.0.0',
              color: Colors.deepPurple,
            ),
          ],
        ),
        const SizedBox(height: 20),
        PillButton(
          label: 'Periksa Pembaruan',
          icon: Icons.system_update_rounded,
          onTap: () => showInfo(context, 'Aplikasi sudah versi terbaru.'),
        ),
      ],
    );
  }
}
