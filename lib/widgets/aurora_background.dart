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
            colors: [Color(0xFFE3F4EA), Color(0xFFF7FAF7)],
          ),
        ),
        child: IgnorePointer(
          child: Stack(
            children: [
              _blob(
                top: -90,
                right: -70,
                size: 300,
                color: AppColors.accent.o(0.40),
              ),
              _blob(
                top: 280,
                left: -130,
                size: 320,
                color: const Color(0xFF7DD3FC).o(0.30),
              ),
              _blob(
                bottom: 40,
                right: -90,
                size: 280,
                color: const Color(0xFFFDE68A).o(0.35),
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
