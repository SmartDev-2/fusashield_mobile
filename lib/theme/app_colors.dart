import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF145C42);
  static const primaryLight = Color(0xFF1F8A62);
  static const accent = Color(0xFF43B581);
  static const ink = Color(0xFF10231B);
  static const muted = Color(0xFF6B7C73);
}

extension ColorAlpha on Color {
  /// Versi ringkas withOpacity (aman di semua versi Flutter).
  Color o(double opacity) => withAlpha((opacity * 255).round());
}
