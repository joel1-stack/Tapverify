import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';

/// Full-bleed online background with a bright gradient scrim so content stays
/// readable. Falls back to a pure gradient when offline or the image fails —
/// screens never render blank.
class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.image,
    required this.child,
    this.overlay = const [
      Color(0xE60F766E),
      Color(0xE60D9488),
      Color(0xD914B8A6),
    ],
    this.scrim = const [Color(0x99000000), Color(0x00000000)],
  });

  final String image;
  final Widget child;
  final List<Color> overlay;
  final List<Color> scrim;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: overlay,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            image,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white54),
              );
            },
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: overlay,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: const SizedBox.expand(),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: scrim,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: const SizedBox.expand(),
          ),
          child,
        ],
      ),
    );
  }
}

/// Rounded white card used on auth screens — keeps the form legible above the
/// photo while staying responsive to any screen width.
class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child, this.maxWidth = 440});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Bright brand-gradient call-to-action button used across auth and empty
/// states: mint → teal → sky reads energetic and welcoming.
class BrightButton extends StatelessWidget {
  const BrightButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.height = 54,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.emerald, AppColors.primary, AppColors.sky],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}