import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_service.dart';

/// Credit Profile — shows verified revenue, consistency, and creditworthiness.
class CreditProfileScreen extends StatelessWidget {
  const CreditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Credit Profile',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.verified_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text('CREDITWORTHY',
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.w800,
                              color: Colors.white, letterSpacing: 1)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Verified Revenue (6 months)',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text('Ksh 2,350,000',
                      style: GoogleFonts.inter(
                          fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _metric('Average Transaction', 'Ksh 49,000', Icons.receipt_rounded, AppColors.primary),
            const SizedBox(height: 10),
            _metric('Total Transactions', '47 verified', Icons.check_circle_rounded, AppColors.success),
            const SizedBox(height: 10),
            _metric('Consistency Score', '94%', Icons.speed_rounded, AppColors.gold),
            const SizedBox(height: 10),
            _metric('Dispute Rate', '0%', Icons.shield_rounded, AppColors.success),
            const SizedBox(height: 10),
            _metric('On-Time Payments', '96%', Icons.schedule_rounded, AppColors.primary),
            const SizedBox(height: 24),
            Text('VERIFICATION SOURCES',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w800,
                    color: AppColors.muted, letterSpacing: 0.6)),
            const SizedBox(height: 12),
            _source('SasaPay', 'OAuth2 + HMAC-SHA512 signed callbacks', true),
            const SizedBox(height: 8),
            _source('Africa\'s Talking SMS', 'Customer receipts sent', true),
            const SizedBox(height: 8),
            _source('Africa\'s Talking USSD', 'Feature-phone balance checks', true),
            const SizedBox(height: 8),
            _source('Africa\'s Talking Airtime', 'Consistency rewards active', true),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                label: Text('Share Credit Profile',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
          ),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text)),
        ],
      ),
    );
  }

  Widget _source(String name, String detail, bool active) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 20,
            color: active ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                Text(detail,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
