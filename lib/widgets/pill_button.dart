import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'pressable_scale.dart';

enum PillStyle { primary, glass, white }

class PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final PillStyle style;
  final bool expand;

  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.style = PillStyle.primary,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final BoxDecoration deco;

    if (style == PillStyle.primary) {
      fg = const Color(0xFF04140D);
      deco = BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.o(0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.o(0.40),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      );
    } else if (style == PillStyle.white) {
      fg = const Color(0xFF081C13);
      deco = BoxDecoration(
        color: const Color(0xFFE6F4ED),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.o(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );
    } else {
      // Glass button di dark mode
      fg = AppColors.ink;
      deco = BoxDecoration(
        color: const Color(0xFF1E3328).o(0.60),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.o(0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.o(0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.primary.o(0.10),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }

    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 58,
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        decoration: deco,
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: fg, size: 22),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
