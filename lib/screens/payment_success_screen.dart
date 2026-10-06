import 'package:flutter/material.dart';

import '../main.dart';
import '../widgets/auth_shell.dart';

/// Confirmation shown after a member is marked as paid: green tick, what was
/// received, and a Done button back to the live list.
class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({
    super.key,
    required this.title,
    required this.amountLabel,
    this.memberName = '',
  });

  final String title;
  final String amountLabel;
  final String memberName;

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pop;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _pop = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryLight,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 170,
            child: RepaintBoundary(
              child: CustomPaint(painter: _SuccessWavesPainter()),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _pop,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: const BoxDecoration(
                            color: kPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 64),
                        ),
                      ),
                      const SizedBox(height: 30),
                      FadeTransition(
                        opacity: _fade,
                        child: Column(
                          children: [
                            const Text(
                              'Payment Received',
                              style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                                color: kBrandInk,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              widget.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: kTextDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.amountLabel,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: kPrimary,
                              ),
                            ),
                            if (widget.memberName.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                widget.memberName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: kMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            const Text(
                              'Thank you',
                              style: TextStyle(
                                fontSize: 15.5,
                                color: kMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 34),
                            SizedBox(
                              width: 240,
                              child: PrimaryPill(
                                label: 'Done',
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The same light green foot waves as the auth screens.
class _SuccessWavesPainter extends CustomPainter {
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

    canvas.drawPath(wave(0.45, 0.20, -0.05), Paint()..color = Colors.white);
    canvas.drawPath(
      wave(0.75, 0.52, 0.30),
      Paint()..color = kSoftGreen.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
