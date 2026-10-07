import 'package:flutter/material.dart';

import '../main.dart';
import 'app_feedback.dart';

/// Shared look for Splash, Login, OTP and Create Account:
/// photo on top, soft green wave curving out of it, white rounded content
/// card holding the form, light green waves at the foot of the screen.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.photo,
    required this.child,
    this.showLogo = true,
  });

  /// Path of the background photo, e.g. 'assets/screns photos/login-bg-woman.jpg'.
  final String photo;

  /// The white card contents.
  final Widget child;

  /// Renders the white TapVerify mark over the photo, top-left.
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final photoHeight = (height * 0.42).clamp(250.0, 380.0);
    return Scaffold(
      backgroundColor: kSurface,
      body: Stack(
        children: [
          // Light green waves at the very bottom of the screen.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 170,
            child: RepaintBoundary(
              child: CustomPaint(painter: _BottomWavesPainter()),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _PhotoHeader(asset: photo, height: photoHeight, showLogo: showLogo),
                Expanded(
                  // The card overlaps the photo by 52px. The negative padding
                  // lives OUTSIDE the scroll view: putting it on the card
                  // instead let the viewport slice the rounded corners and
                  // the icon badge off at the green edge.
                  child: Padding(
                    padding: const EdgeInsets.only(top: -52),
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(36)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.07),
                                  blurRadius: 34,
                                  offset: const Offset(0, -6),
                                ),
                              ],
                            ),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The photo exactly as it is, the logo, and the green wave that separates
/// photo from card. No tint or overlay on the picture itself.
class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({
    required this.asset,
    required this.height,
    required this.showLogo,
  });

  final String asset;
  final double height;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            asset,
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.25),
            cacheWidth: (1400 * dpr).round(),
            errorBuilder: (context, error, stack) =>
                const ColoredBox(color: kPrimaryDark),
          ),
          Positioned(
            top: 14,
            left: 20,
            child: showLogo ? const AppLogo(height: 34, onDark: true) : const SizedBox.shrink(),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _PhotoWavePainter()),
            ),
          ),
        ],
      ),
    );
  }
}

/// The soft green curve rising out of the photo: a bright band over a deeper
/// one, so the edge reads as two layers, exactly like the mockups.
class _PhotoWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    Path band(double offset) => Path()
      ..moveTo(0, h * 0.66 + offset)
      ..cubicTo(w * 0.30, h * 0.86 + offset, w * 0.58, h * 0.52 + offset,
          w, h * 0.60 + offset)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(
      band(26),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kPrimaryDark, Color(0xFF005F3C)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      band(0),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kPrimary, kPrimaryDark],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Two layered light green curves at the foot of the screen.
class _BottomWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    Path wave(double start, double end, double dip) => Path()
      ..moveTo(0, h * start)
      ..quadraticBezierTo(w * 0.5, h * dip, w, h * end)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(
      wave(0.45, 0.20, -0.05),
      Paint()..color = kPrimaryLight,
    );
    canvas.drawPath(
      wave(0.75, 0.52, 0.30),
      Paint()..color = kSoftGreen.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// "Trusted by chamas and savings groups across Kenya" with side rules.
/// [onDark] switches to the light treatment used on the dark login screen.
class TrustLine extends StatelessWidget {
  const TrustLine({
    super.key,
    this.text = 'Trusted by chamas and savings groups across Kenya',
    this.onDark = false,
  });

  final String text;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final rule = onDark ? Colors.white24 : kHairline;
    return Row(
      children: [
        Expanded(child: Divider(color: rule, thickness: 1)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.verified_user_outlined, size: 15, color: kPrimary),
        ),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: onDark ? Colors.white70 : kMuted,
              height: 1.4,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.verified_user_outlined, size: 15, color: kPrimary),
        ),
        Expanded(child: Divider(color: rule, thickness: 1)),
      ],
    );
  }
}

/// The big green pill button every auth screen uses, with arrow and busy
/// spinner built in.
class PrimaryPill extends StatelessWidget {
  const PrimaryPill({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed == null ? kPrimary.withValues(alpha: 0.6) : kPrimary,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: busy ? null : onPressed,
        borderRadius: BorderRadius.circular(30),
        child: SizedBox(
          height: 56,
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Label row with a light green icon circle to its left, used by the form
/// fields on Create Account.
class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: kPrimaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 17, color: kPrimaryDark),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: kBrandInk,
          ),
        ),
      ],
    );
  }
}

/// Red bordered note for a form-level error a secretary can act on.
class ErrorNote extends StatelessWidget {
  const ErrorNote({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDanger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: kDanger),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                message,
                style: const TextStyle(
                    color: kDanger, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Green note used to surface the sandbox OTP code in development builds.
class DevCodeNote extends StatelessWidget {
  const DevCodeNote({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_outlined, size: 16, color: kPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                'Sandbox mode: your code is $code',
                style: const TextStyle(
                    color: kPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard rounded field look that matches the white card.
InputDecoration authInput(BuildContext context, {String? hint, Widget? prefix}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: kMuted),
    prefixIcon: prefix,
    filled: true,
    fillColor: kSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: kHairline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: kHairline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: kPrimary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 17, horizontal: 16),
  );
}
