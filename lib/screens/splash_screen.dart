import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../widgets/app_feedback.dart';

/// First screen on mobile: the smiling-woman photo, white logo and tagline
/// while the stored session is checked, then Login (or straight to Home for a
/// still-valid token).
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

  /// Holds the splash until both the display time and the session check are
  /// done, then lets the gate move on: Home if a token survived, Login if not.
  Future<void> _advance() async {
    final minDisplay = Future<void>.delayed(const Duration(milliseconds: 1700));
    while (!AuthState.ready.value) {
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
    await minDisplay;
    if (!mounted) return;
    if (!AuthState.signedIn.value) {
      AuthState.splashDone.value = true;
    }
    // When a session exists, AuthState.signedIn is already true and the gate
    // swaps Home in by itself; nothing to do here.
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
          // Soft dark green so the white logo and words stay readable.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x59005F3C),
                  Color(0x1A005F3C),
                  Color(0xE6005F3C),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _textFade,
                    child: const AppLogo(height: 40, onDark: true),
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
                            'Proof of Payment',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Stop asking people if they have paid.\nOpen this and see.',
                            style: TextStyle(
                              color: Color(0xFFC8E6D7),
                              fontSize: 16,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  FadeTransition(
                    opacity: _textFade,
                    child: const Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
