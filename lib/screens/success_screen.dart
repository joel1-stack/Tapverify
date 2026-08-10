import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart';

class SuccessScreen extends StatelessWidget {
  final String memberName;
  final double amount;
  final String receiptUrl;
  final String pin;
  final bool queued;

  const SuccessScreen({
    super.key,
    required this.memberName,
    required this.amount,
    required this.receiptUrl,
    required this.pin,
    this.queued = false,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                // Success Icon
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: queued
                        ? [const Color(0xFFD97706), const Color(0xFFB45309)]
                        : [const Color(0xFF059669), const Color(0xFF047857)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: (queued ? const Color(0xFFD97706) : const Color(0xFF059669)).withOpacity(0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    queued ? Icons.cloud_upload_rounded : Icons.check_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  queued ? 'SAVED OFFLINE' : 'PAYMENT APPROVED',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0f172a),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ksh ${amount.toStringAsFixed(0)} from $memberName',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!queued) ...[
                  const SizedBox(height: 28),
                  // Receipt Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf0fdf4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFbbf7d0)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'RECEIPT PIN',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pin,
                          style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 12,
                            color: const Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: receiptUrl));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Receipt link copied', style: GoogleFonts.inter()),
                                  backgroundColor: const Color(0xFF059669),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: Text('Copy Receipt Link', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF059669),
                              side: const BorderSide(color: Color(0xFF059669)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                // Next Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const DashboardScreen()),
                      (route) => false,
                    ),
                    child: Text(
                      'COLLECT NEXT MEMBER',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: 0.5),
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
