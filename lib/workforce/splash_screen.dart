import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'workforce_login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<double> _scale;
  double _progress = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
    _c.forward();

    _timer = Timer.periodic(const Duration(milliseconds: 30), (t) {
      setState(() => _progress += 0.015);
      if (_progress >= 1.0) {
        t.cancel();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (_, __, ___) => const WorkforceLoginScreen(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  AppAssets.logoFull,
                  width: 280,
                  errorBuilder: (_, __, ___) => Text('TapVerify',
                      style: GoogleFonts.inter(
                          fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.deep)),
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: 180,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progress.clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _progress < 0.3
                            ? 'Connecting to SasaPay...'
                            : _progress < 0.6
                                ? 'Verifying Africa\'s Talking...'
                                : _progress < 0.9
                                    ? 'Loading your revenue...'
                                    : 'Ready',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
