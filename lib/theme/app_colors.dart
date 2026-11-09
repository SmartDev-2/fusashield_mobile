import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dark Mode Palette
  static const primary = Color(0xFF2EC486);
  static const primaryLight = Color(0xFF4EE3A2);
  static const primaryDark = Color(0xFF145C42);
  static const accent = Color(0xFF38E1A1);
  static const ink = Color(0xFFF1F7F4);
  static const muted = Color(0xFF8DA69A);
  static const darkBg = Color(0xFF080F0C);
  static const darkSurface = Color(0xFF13221B);
}

Color dosisColor(String? tingkat) {
  switch (tingkat?.toUpperCase()) {
    case 'AMAN':
      return const Color(0xFF34D399);
    case 'PREVENTIF':
      return const Color(0xFFFBBF24);
    case 'WASPADA':
      return const Color(0xFFFB923C);
    case 'KRITIS':
      return const Color(0xFFF87171);
    default:
      return const Color(0xFF94A3B8);
  }
}

extension ColorAlpha on Color {
  /// Versi ringkas withOpacity (aman di semua versi Flutter).
  Color o(double opacity) => withAlpha((opacity * 255).round());
}
