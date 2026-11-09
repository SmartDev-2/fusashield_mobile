import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF09140F), Color(0xFF050A08)],
          ),
        ),
        child: IgnorePointer(
          child: Stack(
            children: [
              _blob(
                top: -90,
                right: -70,
                size: 320,
                color: AppColors.primary.o(0.24),
              ),
              _blob(
                top: 280,
                left: -130,
                size: 340,
                color: const Color(0xFF0EA5E9).o(0.16),
              ),
              _blob(
                bottom: 40,
                right: -90,
                size: 300,
                color: const Color(0xFF10B981).o(0.18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blob({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.o(0)]),
        ),
      ),
    );
  }
}
