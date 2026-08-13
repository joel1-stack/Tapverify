import 'package:flutter/material.dart';

/// Central design tokens for TapVerify.
///
/// [AppColors] holds the brand palette (emerald primary, orange accent,
/// semantic danger/warning) so screens never hard-code hex values.
/// [AppAssets] points at the bundled images used on the splash + login.
class AppColors {
  static const Color primary = Color(0xFF059669);
  static const Color deep = Color(0xFF064E3B);
  static const Color primaryLight = Color(0xFF10B981);
  static const Color accent = Color(0xFFF97316);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color text = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
}

class AppAssets {
  static const String appIcon = 'assets/images/icon_adaptive_foreground.png';
  static const String logoFull =
      'assets/images/logo text sms web app screens splash .png';
}
