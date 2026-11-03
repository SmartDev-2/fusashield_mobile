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

/// Foto lahan cabai di belakang semua halaman.
/// Bagian atas tajam, makin ke bawah makin blur (ala iOS).
/// Caranya: foto yang sama ditumpuk beberapa kali dengan blur makin kuat,
/// tiap lapisan di-mask gradient supaya muncul bertahap dari bawah.
class FarmBackground extends StatelessWidget {
  const FarmBackground({super.key});

  static const _imagePath = 'assets/images/chili_farm.png';

  // ---- ATUR BLUR DI SINI ----
  // Bagian layar dari atas sampai titik ini 100% tajam (0.0 = atas, 1.0 = bawah).
  static const double _sharpUntil = 0.50;

  // Titik di mana blur sudah penuh (kekuatan maksimal).
  static const double _fullBlurAt = 0.95;

  // Kekuatan blur tiap lapisan, dari yang paling halus ke paling kuat.
  static const _sigmas = <double>[2.5, 6, 12, 22];

  // Gradasi dihitung otomatis di antara _sharpUntil dan _fullBlurAt,
  // jadi blur tetap naik halus walau zona tajamnya diperluas.
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
    // Kalau foto belum ditambahkan, tampil background gradient lama.
    errorBuilder: (_, __, ___) => const AuroraBackground(),
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
            // Veil tipis: atas agar judul terbaca, bawah agar kartu kaca menyatu.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.o(0.20),
                    const Color(0xFFF1F8F3).o(0.30),
                    const Color(0xFFF1F8F3).o(0.72),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
