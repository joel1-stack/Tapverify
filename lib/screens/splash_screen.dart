import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../widgets/app_feedback.dart';
import '../widgets/auth_shell.dart';

/// First screen on mobile, matching the splash mockup: full photo, deep
/// green panel with the three-line promise, "Get Started" into Login, and
/// the stored session checked while it is on screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
      ),
    );
    _controller.forward();
    _advance();
  }

  /// Holds the splash until the session check finishes. A surviving session
  /// swaps Home in through the gate by itself; otherwise the buttons decide
  /// when to move on to Login.
  Future<void> _advance() async {
    while (!AuthState.ready.value) {
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
  }

  void _goLogin() {
    AuthState.splashDone.value = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/screns photos/splash-bg-woman.jpg',
            fit: BoxFit.cover,
            alignment: const Alignment(0.1, -0.1),
            cacheWidth: (1400 * dpr).round(),
            errorBuilder: (context, error, stack) =>
                const ColoredBox(color: kDarkGreen),
          ),
          // Photo fading into the deep green panel that holds the message.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x33005F3C),
                  Color(0xCC003D28),
                  Color(0xF2003D28),
                  Color(0xF2003D28),
                ],
                stops: [0.0, 0.42, 0.66, 0.85, 1.0],
              ),
            ),
          ),
          const RepaintBoundary(
            child: CustomPaint(painter: _SplashDecorPainter()),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 14, 28, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeTransition(
                    opacity: _textFade,
                    child: const AppLogo(height: 38, onDark: true),
                  ),
                  const Spacer(),
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Secure payments.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              height: 1.18,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Real people.',
                            style: TextStyle(
                              color: Color(0xFF6FE7AE),
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              height: 1.18,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Total peace of mind.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              height: 1.18,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 14),
                          Text(
                            "For Kenya's chamas & savings groups.",
                            style: TextStyle(
                              color: Color(0xFFC8E6D7),
                              fontSize: 15.5,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeTransition(
                    opacity: _textFade,
                    child: PrimaryPill(label: 'Get Started', onPressed: _goLogin),
                  ),
                  const SizedBox(height: 18),
                  FadeTransition(
                    opacity: _textFade,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: Colors.white70, fontSize: 14.5),
                        ),
                        GestureDetector(
                          onTap: _goLogin,
                          child: const Text(
                            'Log in',
                            style: TextStyle(
                              color: Color(0xFF6FE7AE),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The mockup's green corner swoosh plus the two faint curves layered into
/// the deep green panel at the foot of the screen.
class _SplashDecorPainter extends CustomPainter {
  const _SplashDecorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Top-left green leaf over the photo.
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(w * 0.46, 0)
        ..quadraticBezierTo(w * 0.18, h * 0.05, 0, h * 0.12)
        ..close(),
      Paint()..color = kPrimary,
    );

    // Two faint lighter sweeps in the panel.
    final sweep1 = Paint()..color = Colors.white.withValues(alpha: 0.05);
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.78)
        ..quadraticBezierTo(w * 0.5, h * 0.66, w, h * 0.76)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      sweep1,
    );
    final sweep2 = Paint()..color = Colors.white.withValues(alpha: 0.05);
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.88)
        ..quadraticBezierTo(w * 0.45, h * 0.82, w, h * 0.90)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      sweep2,
    );
  }

  @override
  bool shouldRepaint(covariant _SplashDecorPainter oldDelegate) => false;
}
