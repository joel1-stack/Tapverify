import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'home_shell.dart';

/// Animated success screen shown after a payment is verified.
///
/// Confetti-ish scale/fade entrance, displays the member, amount and printable
/// receipt (url + pin) with copy-to-clipboard, and navigates home when done.
/// `queued`/`smsSent` flag whether the verification is synced or offline.
class SuccessScreen extends StatefulWidget {
  final String memberName;
  final String memberPhone;
  final double amount;
  final String receiptUrl;
  final String pin;
  final bool queued;
  final bool smsSent;

  const SuccessScreen({
    super.key,
    required this.memberName,
    required this.memberPhone,
    required this.amount,
    required this.receiptUrl,
    required this.pin,
    this.queued = false,
    this.smsSent = false,
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.3, 1.0, curve: Curves.easeIn)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.receiptUrl));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Receipt link copied', style: GoogleFonts.inter()),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),

                // Success Illustration
                Center(
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        // queued (offline saved) vs approved (payment)
                        widget.queued
                            ? 'https://images.pexels.com/photos/7413888/pexels-photo-7413888.jpeg?auto=compress&cs=tinysrgb&w=800'
                            : 'https://images.pexels.com/photos/8348627/pexels-photo-8348627.jpeg?auto=compress&cs=tinysrgb&w=800',
                        width: 200,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: widget.queued
                                    ? [
                                        const Color(0xFFF59E0B),
                                        const Color(0xFFD97706)
                                      ]
                                    : [
                                        AppColors.primary,
                                        const Color(0xFF047857)
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(
                              widget.queued
                                  ? Icons.cloud_upload_rounded
                                  : Icons.check_rounded,
                              color: Colors.white,
                              size: 50,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(opacity: _fadeAnimation.value, child: child);
                  },
                  child: Text(
                    widget.queued ? 'SAVED OFFLINE' : 'PAYMENT APPROVED',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(opacity: _fadeAnimation.value, child: child);
                  },
                  child: Text(
                    'Ksh ${widget.amount.toStringAsFixed(0)} from ${widget.memberName}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(opacity: _fadeAnimation.value, child: child);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: widget.queued
                          ? const Color(0xFFFFFBEB)
                          : AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.queued
                            ? const Color(0xFFFDE68A)
                            : AppColors.primary.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.queued
                              ? Icons.cloud_upload_rounded
                              : Icons.sms_rounded,
                          size: 16,
                          color: widget.queued
                              ? const Color(0xFFB45309)
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.queued
                              ? 'Saved offline. SMS will send on sync.'
                              : 'SMS receipt sent to ${widget.memberPhone}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.queued
                                ? const Color(0xFF92400E)
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (!widget.queued) ...[
                  const SizedBox(height: 32),

                  // Receipt Card
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                          opacity: _fadeAnimation.value, child: child);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'RECEIPT PIN',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.pin,
                            style: GoogleFonts.inter(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 14,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.primary),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _copyLink,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.copy_rounded,
                                            size: 18, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Copy Receipt Link',
                                          style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Done Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF047857)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pushAndRemoveUntil(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const HomeShell(),
                          transitionsBuilder: (_, animation, __, child) {
                            return FadeTransition(
                                opacity: animation, child: child);
                          },
                        ),
                        (route) => false,
                      ),
                      child: Center(
                        child: Text(
                          'COLLECT NEXT MEMBER',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
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
