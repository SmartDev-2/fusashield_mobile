import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'pressable_scale.dart';

/// Kartu "Liquid Glass" Dark Mode: blur + gradient gelap obsidian transparan + border specular tipis.
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
            color: Colors.black.o(elevated ? 0.50 : 0.32),
            blurRadius: elevated ? 36 : 24,
            offset: Offset(0, elevated ? 16 : 10),
          ),
          BoxShadow(
            color: AppColors.primary.o(elevated ? 0.14 : 0.06),
            blurRadius: elevated ? 28 : 16,
            offset: Offset(0, elevated ? 4 : 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E3328).o(0.72),
                  const Color(0xFF0F1A15).o(0.56),
                ],
              ),
              border: Border.all(
                color: Colors.white.o(0.14),
                width: 1.0,
              ),
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
