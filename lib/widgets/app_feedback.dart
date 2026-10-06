import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api.dart';
import '../main.dart';

/// Turns any thrown error into one short sentence a secretary can act on.
///
/// Every screen used to catch only [ApiException], so a dead socket or an HTML
/// error page failed silently: the spinner stopped and nothing was shown.
String friendlyError(Object error) {
  if (error is ApiException) return error.message;
  if (error is TimeoutException) {
    return 'The network is slow. Check your connection and try again.';
  }
  if (error is SocketException || error is http.ClientException) {
    return 'Cannot reach TapVerify. Check your internet connection.';
  }
  if (error is FormatException) {
    return 'TapVerify sent an unexpected reply. Please try again.';
  }
  return 'Something went wrong. Please try again.';
}

/// Shows a floating error [SnackBar] with consistent styling.
void showErrorSnack(BuildContext context, Object error) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(friendlyError(error)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: kDanger,
    ),
  );
}

/// Shows a floating success [SnackBar] with consistent styling.
void showSuccessSnack(BuildContext context, String message) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: kSuccess,
    ),
  );
}

/// Warns, in a release build only, that the API base URL was never set.
///
/// Without this, shipping with the localhost default produced a site that
/// simply never loaded data and gave the visitor no clue why.
class BackendWarningBanner extends StatelessWidget {
  const BackendWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kBackendMisconfigured) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF7E8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFE08E0B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This build is pointed at $kApiBaseUrl. Rebuild with '
              '--dart-define=API_BASE_URL=https://your-api-host',
              style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared motion language: one place to tune how the app feels.
class AppMotion {
  const AppMotion._();

  /// Entrance for whole screens and cards.
  static const Duration fast = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 380);
  static const Duration slow = Duration(milliseconds: 620);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;

  /// Used by staggered lists. Capped so a 500 member list never waits 20s.
  static Duration stagger(int index, {int stepMs = 35, int capMs = 600}) =>
      Duration(milliseconds: (index * stepMs).clamp(0, capMs));
}

/// Fade plus a small upward slide. Used instead of copy pasted
/// TweenAnimationBuilder blocks.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.medium,
    this.offset = 18,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration + delay,
      curve: Interval(
        delay.inMilliseconds / (duration + delay).inMilliseconds,
        1,
        curve: AppMotion.enter,
      ),
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, offset * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// The one and only brand mark.
///
/// Always renders [AppLogo.asset], which has a real alpha channel. The previous
/// `logo_full.png` was an opaque near white square, so `Image.asset(color:)`
/// painted a solid white block instead of the shield.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.height = 34, this.onDark = false});

  final double height;

  /// When true the mark is flattened to white so it reads on dark surfaces.
  final bool onDark;

  static const String asset = 'assets/images/logo_horizontal.png';

  @override
  Widget build(BuildContext context) {
    // Decode at the size actually painted instead of the 1254px source.
    final cacheWidth = (height * MediaQuery.devicePixelRatioOf(context) * 4)
        .round();

    final image = Image.asset(
      asset,
      height: height,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.medium,
      fit: BoxFit.contain,
      semanticLabel: 'TapVerify',
      errorBuilder: (context, error, stack) => Text(
        'TapVerify',
        style: TextStyle(
          fontSize: height * 0.62,
          fontWeight: FontWeight.w800,
          color: onDark ? Colors.white : kBrandInk,
        ),
      ),
    );

    if (!onDark) return image;
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      child: image,
    );
  }
}
