import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'pressable_scale.dart';

/// Kartu "Liquid Glass": blur + gradient putih transparan + border tipis.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool elevated;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 28,
    this.elevated = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.o(elevated ? 0.18 : 0.08),
            blurRadius: elevated ? 36 : 28,
            offset: Offset(0, elevated ? 14 : 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white.o(0.80), Colors.white.o(0.46)],
              ),
              border: Border.all(color: Colors.white.o(0.9), width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap == null) return card;
    return PressableScale(onTap: onTap, scale: 0.98, child: card);
  }
}
