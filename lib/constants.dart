import 'package:flutter/material.dart';

/// Central design tokens for TapVerify — Revenue proof for manufacturing SMEs.
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
  ///  - [sasapay] / [avalanche] / [africasTalking] — rail chips & the
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

  // Bright, welcoming accents for auth/hero gradients.
  static const Color emerald = Color(0xFF34D399);
  static const Color mint = Color(0xFF10B981);
  static const Color sky = Color(0xFF0EA5E9);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color amber = Color(0xFFFBBF24);
  static const Color orange = Color(0xFFFB923C);

  static const Color loop = Color(0xFF0D9488);
  static const Color sasapay = Color(0xFF1E40AF);
  static const Color avalanche = Color(0xFFE84142);
  static const Color africasTalking = Color(0xFF0F766E);
}

/// Online imagery for backgrounds. Africa-first: real people in workshops,
/// markets, farms and boardrooms — the audience TapVerify serves. Every URL is
/// a verified Unsplash image; the UI always falls back to a gradient when
/// offline so screens never break.
class AppImages {
  static const String teamMeeting =
      'https://images.unsplash.com/photo-1556761175-b413da4baf72?w=1200&q=70';
  static const String africanTech =
      'https://images.unsplash.com/photo-1600880292203-757bb62b4baf?w=1200&q=70';
  static const String africanBusinessWoman =
      'https://images.unsplash.com/photo-1587614382346-4ec70e388b28?w=1200&q=70';
  static const String africanCraft =
      'https://images.unsplash.com/photo-1526129318478-62ed807ebdf9?w=1200&q=70';
  static const String warehouseWorker =
      'https://images.unsplash.com/photo-1553413077-190dd305871c?w=1200&q=70';
  static const String industry =
      'https://images.unsplash.com/photo-1531973576160-7125cd663d86?w=1200&q=70';
  static const String boardroom =
      'https://images.unsplash.com/photo-1542744173-8e7e53415bb0?w=1200&q=70';
  static const String engineer =
      'https://images.unsplash.com/photo-1581092160562-40aa08e78837?w=1200&q=70';
  static const String portraitWoman =
      'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=1200&q=70';

  // Chama & SACCO — Kenyan savings groups, market days and community money
  // circles. These run on the login/register backgrounds and the worker banner.
  static const String chamaWomen =
      'https://images.unsplash.com/photo-1523821741446-edb2b68bb7a0?w=1200&q=70';
  static const String chamaMeeting =
      'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=1200&q=70';
  static const String chamaFriends =
      'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=1200&q=70';
  static const String saccoGroup =
      'https://images.unsplash.com/photo-1543269865-cbf427effbad?w=1200&q=70';
  static const String africanMarket =
      'https://images.unsplash.com/photo-1533900298318-6b8da08a523e?w=1200&q=70';
  static const String marketStall =
      'https://images.unsplash.com/photo-1488459716781-31db52582fe9?w=1200&q=70';
  static const String handshake =
      'https://images.unsplash.com/photo-1596526131083-e8c633c948d2?w=1200&q=70';
}

class AppAssets {
  static const String appIcon = 'assets/images/icon_adaptive_foreground.png';
  static const String logoFull = 'assets/images/logo_transparent.png';
}