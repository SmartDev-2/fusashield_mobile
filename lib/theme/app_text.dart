import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppText {
  AppText._();

  static const largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.9,
    color: AppColors.ink,
    height: 1.1,
  );
  static const sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.ink,
  );
  static const body = TextStyle(
    fontSize: 14,
    color: AppColors.muted,
    height: 1.45,
  );
  static const caption = TextStyle(fontSize: 12, color: AppColors.muted);
}
