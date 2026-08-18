import 'package:flutter/material.dart';

/// Central design tokens for TapVerify Workforce.
///
/// Brand palette: Trust Teal as the money-movement / navigation system, with
/// partner-rail tints so LOOP, SasaPay, Africa's Talking and Avalanche read
/// clearly without the app looking like a rainbow.
///
///  - [primary]/[deep]/[primaryLight] — Trust Teal (main buttons, progress,
///    gradients, paid/verified emphasis)
///  - [accent] — Avalanche Red (badges, streaks, urgent CTAs: raise a
///    collection, simulate a payment)
///  - [secondary] — SasaPay Blue (payment rails, checkout links, secondary
///    buttons)
///  - [loop] / [sasapay] / [avalanche] / [africasTalking] — rail chips & the
///    More/evidence console
///  - [success]/[warning]/[danger] — 9-state lifecycle semantics
class AppColors {
  static const Color primary = Color(0xFF0D9488);
  static const Color deep = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color accent = Color(0xFFE84142);
  static const Color secondary = Color(0xFF1E40AF);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color text = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color gold = Color(0xFFC9A227);

  static const Color loop = Color(0xFF0D9488);
  static const Color sasapay = Color(0xFF1E40AF);
  static const Color avalanche = Color(0xFFE84142);
  static const Color africasTalking = Color(0xFF0F766E);
}

class AppAssets {
  static const String appIcon = 'assets/images/icon_adaptive_foreground.png';
  static const String logoFull =
      'assets/images/logo text sms web app screens splash .png';
}