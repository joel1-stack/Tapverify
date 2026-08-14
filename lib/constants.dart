import 'package:flutter/material.dart';

/// Central design tokens for TapVerify.
///
/// Brand palette: LOOP orange everywhere — [accent]/[loop] for actions & CTAs,
/// [primary]/[deep]/[primaryLight] for the same orange expressed at deeper and
/// lighter densities for gradients, app bars and trusted accents.
/// Warm cream backgrounds and [gold] for premium highlights.
class AppColors {
  static const Color primary = Color(0xFFEA580C);
  static const Color deep = Color(0xFF9A3412);
  static const Color primaryLight = Color(0xFFFFB27A);
  static const Color accent = Color(0xFFFF6B00);
  static const Color loop = Color(0xFFFF6B00);
  static const Color gold = Color(0xFFC9A227);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color background = Color(0xFFFAF7F2);
  static const Color surface = Colors.white;
  static const Color text = Color(0xFF1B2A26);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0xFFE6E0D6);
}

class AppAssets {
  static const String appIcon = 'assets/images/icon_adaptive_foreground.png';
  static const String logoFull =
      'assets/images/logo text sms web app screens splash .png';
}
