import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Pill status dark glass dengan titik yang berdenyut neon.
class StatusPill extends StatefulWidget {
  final String label;

  const StatusPill({super.key, required this.label});

  @override
  State<StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<StatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1D16).o(0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.o(0.40), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.o(0.3),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.o(0.8),
                    blurRadius: 3 + 7 * _ctrl.value,
                    spreadRadius: 1 * _ctrl.value,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            widget.label,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
