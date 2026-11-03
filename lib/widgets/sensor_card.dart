import 'package:flutter/material.dart';

import '../models/sensor_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'glass_card.dart';
import 'icon_badge.dart';

class SensorCard extends StatelessWidget {
  final SensorData data;

  const SensorCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: data.icon, color: data.color, size: 44),
          const Spacer(),
          Text(data.title, style: AppText.caption),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  data.value,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: AppColors.ink,
                    height: 1.05,
                  ),
                ),
              ),
              if (data.unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 3),
                  child: Text(
                    data.unit,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
