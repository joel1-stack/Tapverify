import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'workforce_login_screen.dart';
import 'revenue_report_screen.dart';
import 'credit_profile_screen.dart';
import 'evidence_console_screen.dart';

/// Settings + Evidence — standalone screen (accessible from drawer).
class WorkforceMoreScreen extends StatelessWidget {
  const WorkforceMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text('Settings',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Revenue tools
          _section('REVENUE TOOLS'),
          const SizedBox(height: 8),
          _tile(Icons.bar_chart_rounded, 'Revenue Report',
              'Monthly breakdown', AppColors.primary, () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RevenueReportScreen()));
          }),
          const SizedBox(height: 8),
          _tile(Icons.credit_score_rounded, 'Credit Profile',
              'Lender-ready proof', AppColors.deep, () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CreditProfileScreen()));
          }),
          const SizedBox(height: 8),
          _tile(Icons.verified_rounded, 'Evidence Console',
              'Technical proof', AppColors.accent, () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EvidenceConsoleScreen()));
          }),
          const SizedBox(height: 24),

          // Business
          _section('BUSINESS'),
          const SizedBox(height: 8),
          _tile(Icons.business_rounded, "Peter's Metal Works",
              'Manufacturer · Westlands', AppColors.muted, null),
          const SizedBox(height: 24),

          // Account
          _section('ACCOUNT'),
          const SizedBox(height: 8),
          _tile(Icons.person_outline_rounded, 'Profile',
              'Peter Kaunda · Owner', AppColors.muted, null),
          const SizedBox(height: 8),
          _tile(Icons.lock_outline_rounded, 'Change password',
              'Update your PIN', AppColors.muted, null),
          const SizedBox(height: 24),

          // Sign out
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WorkforceLoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded),
              label: Text('Sign out',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('TapVerify v2.0.0',
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted)),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Text(title,
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w800,
            color: AppColors.muted, letterSpacing: 0.6));
  }

  Widget _tile(IconData icon, String title, String subtitle, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                  Text(subtitle,
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
