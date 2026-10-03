import 'package:flutter/material.dart';

/// The TapVerify product screens are built phone-first. On a desktop browser a
/// full-bleed list or form stretched across 1400px looks broken, so every
/// screen passes its body through [AppConstrained], which centres a sane
/// column: full width on phones, a readable measure on wide screens.
double appContentWidth(BuildContext context, {double wide = 640}) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < 600) return double.infinity; // phone: full bleed
  if (w < 900) return 560; // small tablet / narrow browser
  return wide; // desktop: centred column
}

class AppConstrained extends StatelessWidget {
  const AppConstrained({
    super.key,
    required this.child,
    this.wide,
  });

  final Widget child;

  /// Override the desktop max width (e.g. 760 for the member table).
  final double? wide;

  @override
  Widget build(BuildContext context) {
    final max = appContentWidth(context, wide: wide ?? 640);
    if (max == double.infinity) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: max),
        child: child,
      ),
    );
  }
}

/// True when the display is wide enough that a modal reads better as a centred
/// dialog than as a bottom sheet.
bool isWideDisplay(BuildContext context) => MediaQuery.sizeOf(context).width >= 700;
