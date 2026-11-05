import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF145C42);
  static const primaryLight = Color(0xFF1F8A62);
  static const accent = Color(0xFF43B581);
  static const ink = Color(0xFF10231B);
  static const muted = Color(0xFF6B7C73);
}

Color dosisColor(String? tingkat) {
  switch (tingkat?.toUpperCase()) {
    case 'AMAN':
      return Colors.green;
    case 'PREVENTIF':
      return Colors.amber;
    case 'WASPADA':
      return Colors.orange;
    case 'KRITIS':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

extension ColorAlpha on Color {
  /// Versi ringkas withOpacity (aman di semua versi Flutter).
  Color o(double opacity) => withAlpha((opacity * 255).round());
}
