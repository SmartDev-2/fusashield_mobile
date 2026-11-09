import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'aurora_background.dart';

class _BlurLayer {
  final double sigma;
  final double from; // 0.0 = atas layar, 1.0 = bawah layar
  final double to;

  const _BlurLayer(this.sigma, this.from, this.to);
}

/// Foto lahan cabai di belakang semua halaman versi Dark Mode.
/// Bagian atas tajam, makin ke bawah makin blur (ala iOS / visionOS).
/// Menggunakan dark atmospheric veil agar kartu kaca dark mode menyatu indah.
class FarmBackground extends StatelessWidget {
  const FarmBackground({super.key});

  static const _imagePath = 'assets/images/chili_farm.png';

  // Bagian layar dari atas sampai titik ini 100% tajam (0.0 = atas, 1.0 = bawah).
  static const double _sharpUntil = 0.50;

  // Titik di mana blur sudah penuh (kekuatan maksimal).
  static const double _fullBlurAt = 0.95;

  // Kekuatan blur tiap lapisan, dari yang paling halus ke paling kuat.
  static const _sigmas = <double>[2.5, 6, 12, 22];

  static List<_BlurLayer> _buildLayers() {
    final span = _fullBlurAt - _sharpUntil;
    final n = _sigmas.length;
    return [
      for (var i = 0; i < n; i++)
        _BlurLayer(
          _sigmas[i],
          _sharpUntil + span * (i / (n + 1)),
          _sharpUntil + span * ((i + 2) / (n + 1)),
        ),
    ];
  }

  Widget _photo() => Image.asset(
    _imagePath,
    fit: BoxFit.cover,
    alignment: Alignment.topCenter,
    width: double.infinity,
    height: double.infinity,
    errorBuilder: (context, error, stackTrace) => const AuroraBackground(),
  );

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _photo(),
            for (final l in _buildLayers())
              ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: const [Colors.transparent, Colors.black],
                  stops: [l.from, l.to],
                ).createShader(rect),
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: l.sigma,
                    sigmaY: l.sigma,
                  ),
                  child: _photo(),
                ),
              ),
            // Dark Mode Atmospheric Veil: menjaga foto tetap bernuansa malam/gelap dengan aksen emerald dalam.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF09140F).o(0.55),
                    const Color(0xFF070F0C).o(0.78),
                    const Color(0xFF050A08).o(0.95),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
