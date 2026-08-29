import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_service.dart';

/// Proof page - Group attestation for SACCO officers
class ProofScreen extends StatelessWidget {
  const ProofScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = WorkforceService.stats();
    final members = WorkforceService.members();
    final groupName = 'Kamau Welfare';
    final totalCollected = stats['collected'] as int;
    final totalMembers = members.length;
    final paidCount = members.where((m) => m.status == 'PAID').length;
    final streakMonths = 12;
    final badgeLevel = _getGroupBadgeLevel(totalCollected, streakMonths);
    final txHash = '0x3f2a1b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text('Group Proof',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {},
            tooltip: 'Share to WhatsApp',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Group info card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.deep, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text('KW',
                          style: GoogleFonts.inter(
                              fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(groupName,
                      style: GoogleFonts.inter(
                          fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Verified by TapVerify',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.white.withOpacity(0.8))),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Verification checks
            Text('VERIFICATION',
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    color: AppColors.muted, letterSpacing: 0.6)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _checkRow(Icons.check_circle_rounded, 'Ksh ${_fmt(totalCollected)} total verified', true),
                  const SizedBox(height: 8),
                  _checkRow(Icons.check_circle_rounded, '$paidCount/$totalMembers members paid', true),
                  const SizedBox(height: 8),
                  _checkRow(Icons.check_circle_rounded, '${(paidCount / totalMembers * 100).toStringAsFixed(0)}% consistency rate', true),
                  const SizedBox(height: 8),
                  _checkRow(Icons.check_circle_rounded, '$streakMonths months · Zero disputes', true),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Badge
            Text('GROUP BADGE',
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    color: AppColors.muted, letterSpacing: 0.6)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold, width: 2),
              ),
              child: Column(
                children: [
                  Text(badgeLevel['emoji']!, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(badgeLevel['name']!, 
                      style: GoogleFonts.inter(
                          fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.gold)),
                  const SizedBox(height: 4),
                  Text('GROUP',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
                  const SizedBox(height: 12),
                  Text('Attested on Avalanche',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.muted)),
                  const SizedBox(height: 4),
                  Text(txHash.substring(0, 6) + '...' + txHash.substring(txHash.length - 4),
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.text)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.link_rounded, size: 16),
                      label: Text('View on Snowtrace',
                          style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Share info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text('📤 Share this proof with your SACCO officer',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  Text('They can verify instantly at:',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.muted)),
                  Text('tapverify.co.ke/verify/kamau-welfare',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share_rounded),
              label: Text('📤 SHARE TO WHATSAPP',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _getGroupBadgeLevel(int collected, int streakMonths) {
    if (collected >= 1000000 && streakMonths >= 12) {
      return {'emoji': '🥇', 'name': 'GOLD GROUP'};
    } else if (collected >= 500000 && streakMonths >= 6) {
      return {'emoji': '🥈', 'name': 'SILVER GROUP'};
    } else if (collected >= 100000 && streakMonths >= 3) {
      return {'emoji': '🥉', 'name': 'BRONZE GROUP'};
    }
    return {'emoji': '⬜', 'name': 'NEW GROUP'};
  }

  Widget _checkRow(IconData icon, String text, bool verified) {
    return Row(
      children: [
        Icon(icon, size: 20, color: verified ? AppColors.success : AppColors.muted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
        ),
        if (verified) ...[
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Icon(Icons.check_rounded, size: 14, color: Colors.white)),
          ),
        ],
      ],
    );
  }

  String _fmt(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
