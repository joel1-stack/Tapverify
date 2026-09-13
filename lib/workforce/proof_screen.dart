import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../constants.dart';
import '../workforce/workforce_service.dart';

class ProofScreen extends StatelessWidget {
  const ProofScreen({super.key});

  void _shareToWhatsApp(BuildContext context) {
    HapticFeedback.lightImpact();
    final proof = '🏆 Group Proof — Kamau Welfare\n\n'
        '✓ Ksh 288,000 total verified\n'
        '✓ 12 members · 83% consistency\n'
        '✓ 12 months · Zero disputes\n\n'
        '🥇 GOLD GROUP BADGE\n'
        'Attested on Avalanche\n'
        'Tx: 0x3f2a...b91c\n\n'
        'Verified by TapVerify\n'
        'tapverify.co.ke/verify/kamau-welfare';
    Share.share(proof);
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final stats = WorkforceService.stats();
    final members = WorkforceService.members();
    final totalCollected = stats['collected'] as int;
    final totalMembers = members.length;
    final paidCount = members.where((m) => m.status == 'PAID').length;
    final streakMonths = 12;
    final badgeLevel = _getGroupBadgeLevel(totalCollected, streakMonths);
    final txHash = '0x3f2a1b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
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
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text('KW',
                          style: GoogleFonts.inter(
                              fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Kamau Welfare Group',
                      style: GoogleFonts.inter(
                          fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Verified by TapVerify',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Verification checks
            Text('VERIFICATION',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w800,
                    color: AppColors.muted, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _checkRow('Ksh ${_fmt(totalCollected)} total verified'),
                  const SizedBox(height: 10),
                  _checkRow('$paidCount/$totalMembers members paid'),
                  const SizedBox(height: 10),
                  _checkRow('${(paidCount / totalMembers * 100).toStringAsFixed(0)}% consistency rate'),
                  const SizedBox(height: 10),
                  _checkRow('$streakMonths months · Zero disputes'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Badge
            Text('GROUP BADGE',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w800,
                    color: AppColors.muted, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.text.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(txHash.substring(0, 6) + '...' + txHash.substring(txHash.length - 4),
                        style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton.icon(
                      onPressed: () => _showSnack(context, 'Opening Snowtrace...'),
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

            // Verify link
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text('Share this proof with your SACCO officer',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  Text('tapverify.co.ke/verify/kamau-welfare',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Share button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _shareToWhatsApp(context),
                icon: const Icon(Icons.share_rounded, size: 20),
                label: Text('SHARE TO WHATSAPP',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 20),
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

  Widget _checkRow(String text) {
    return Row(
      children: [
        Container(
          width: 22, height: 22,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          child: const Center(child: Icon(Icons.check_rounded, size: 14, color: Colors.white)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
        ),
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
