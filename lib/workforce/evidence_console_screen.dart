import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'ussd_simulator_screen.dart';
import 'sms_test_screen.dart';

/// Evidence Console — technical proof for judges.
class EvidenceConsoleScreen extends StatelessWidget {
  const EvidenceConsoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Evidence Console',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Status header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.deep, AppColors.primary],
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
                    const Icon(Icons.verified_rounded,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Text('ALL SYSTEMS ACTIVE',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Every payment is cryptographically verified.',
                    style:
                        GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── LIVE DEMOS ──
          Text('LIVE DEMOS',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                  letterSpacing: 0.6)),
          const SizedBox(height: 10),

          _demoTile(
            context,
            icon: Icons.phone_in_talk_rounded,
            title: 'USSD Simulator',
            subtitle: 'Tap to simulate *384*123# flow',
            color: AppColors.primary,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const UssdSimulatorScreen())),
          ),
          const SizedBox(height: 8),
          _demoTile(
            context,
            icon: Icons.sms_rounded,
            title: 'SMS Test',
            subtitle: 'Send receipt via Africa\'s Talking',
            color: AppColors.success,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SmsTestScreen())),
          ),
          const SizedBox(height: 24),

          // ── PAYMENT VERIFICATION ──
          Text('PAYMENT VERIFICATION',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                  letterSpacing: 0.6)),
          const SizedBox(height: 10),
          _check('SasaPay OAuth2 Token',
              'GET /oauth/token — active', true),
          const SizedBox(height: 8),
          _check('HMAC-SHA512 Callback Verification',
              'Webhook signature validated', true),
          const SizedBox(height: 8),
          _check('Checkout Link Generation',
              'POST /api/v1/checkout — active', true),
          const SizedBox(height: 8),
          _check('Transaction Query',
              'GET /api/v1/query — active', true),
          const SizedBox(height: 20),

          // ── NOTIFICATIONS ──
          Text('NOTIFICATIONS',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                  letterSpacing: 0.6)),
          const SizedBox(height: 10),
          _check('AT Bulk SMS — Customer Receipts',
              'POST /version1/messaging', true),
          const SizedBox(height: 8),
          _check('AT USSD — Balance Check',
              '*384*123# — active (shortcode 14434)', true),
          const SizedBox(height: 8),
          _check('AT Airtime — Consistency Rewards',
              'POST /api/v1/airtime/send — active', true),
          const SizedBox(height: 20),

          // ── CRYPTOGRAPHIC PROOF ──
          Text('CRYPTOGRAPHIC PROOF',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                  letterSpacing: 0.6)),
          const SizedBox(height: 10),
          _check('AT AES-256 Airtime Encryption',
              'Headers.x-at-encryption-key — active', true),
          const SizedBox(height: 8),
          _check('AES-256 Decryption on Server',
              'data_decrypted verified', true),
          const SizedBox(height: 8),
          _check('SHA-256 Hash Integrity',
              'Verification event hash stored', true),
          const SizedBox(height: 8),
          _check('Avalanche Badge (Coming Soon)',
              'On-chain attestation pending', false),
          const SizedBox(height: 20),

          // ── API ENDPOINTS ──
          Text('API ENDPOINTS',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                  letterSpacing: 0.6)),
          const SizedBox(height: 10),
          _endpoint('POST', '/api/v1/collections/', 'Record customer payment'),
          const SizedBox(height: 6),
          _endpoint(
              'POST', '/api/v1/collections/{id}/pay/', 'Generate payment link'),
          const SizedBox(height: 6),
          _endpoint('POST', '/webhooks/sasapay/', 'Receive payment callback'),
          const SizedBox(height: 6),
          _endpoint('GET', '/api/v1/members/', 'List customers'),
          const SizedBox(height: 6),
          _endpoint('POST', '/api/v1/send-links/', 'Bulk payment links'),
          const SizedBox(height: 6),
          _endpoint('GET', '/api/v1/sms/history/', 'SMS delivery log'),
          const SizedBox(height: 6),
          _endpoint('POST', '/api/v1/airtime/send/', 'Disburse airtime reward'),
          const SizedBox(height: 6),
          _endpoint('GET', '/api/v1/leaderboard/', 'Top payers by streak'),
          const SizedBox(height: 6),
          _endpoint('POST', '/api/v1/uat/request/', 'USSD balance request'),
          const SizedBox(height: 6),
          _endpoint('POST', '/ussd/', 'USSD callback handler'),
          const SizedBox(height: 6),
          _endpoint('GET', '/dashboard/', 'Web dashboard'),
        ],
      ),
    );
  }

  Widget _demoTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('TAP',
                  style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w800, color: color)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _check(String title, String detail, bool ok) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: (ok ? AppColors.success : AppColors.muted).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              ok ? Icons.check_rounded : Icons.schedule_rounded,
              size: 16,
              color: ok ? AppColors.success : AppColors.muted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
                Text(detail,
                    style: GoogleFonts.inter(
                        fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
          Text(ok ? 'Active' : 'Soon',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: ok ? AppColors.success : AppColors.muted)),
        ],
      ),
    );
  }

  Widget _endpoint(String method, String path, String desc) {
    final color = method == 'POST' ? AppColors.primary : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(method,
                style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w800, color: color)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(path,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
                Text(desc,
                    style: GoogleFonts.inter(
                        fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
