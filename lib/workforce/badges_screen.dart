import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';

/// My Badges — Bronze/Silver/Gold/Avalanche attestation badges.
class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text('My Badges',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Score summary
          Container(
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
              children: [
                Text('UNIVERSAL PAYER SCORE', style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white60, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text('847 / 1000', style: GoogleFonts.inter(
                    fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Silver Payer II', style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white70)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: 0.847,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text('53 points to Gold Payer I', style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Streak
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Text('🔥', style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('6-Month Consistency Streak', style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
                      Text('You paid on time for 6 months straight', style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('ACTIVE', style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text('BADGE COLLECTION', style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.6)),
          const SizedBox(height: 12),

          // Gold badge
          _badgeCard(
            emoji: '🥇',
            name: '6-Month Payer',
            tier: 'Silver',
            color: AppColors.gold,
            date: 'Minted: Aug 15, 2026',
            tx: '0x7e8b...c4d2',
            status: 'MINTED ON-CHAIN',
            verified: true,
          ),
          const SizedBox(height: 12),

          // Silver badge
          _badgeCard(
            emoji: '🥈',
            name: '3-Month Payer',
            tier: 'Bronze',
            color: AppColors.muted,
            date: 'Minted: May 15, 2026',
            tx: '0x3f2a...b91c',
            status: 'MINTED ON-CHAIN',
            verified: true,
          ),
          const SizedBox(height: 12),

          // Locked badge
          _badgeCard(
            emoji: '⬜',
            name: '12-Month Payer',
            tier: 'Gold',
            color: AppColors.border,
            date: '6 months to unlock',
            tx: '',
            status: 'LOCKED',
            verified: false,
          ),
          const SizedBox(height: 20),

          // Agentic console
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.smart_toy_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text('AGENTIC ENGINE', style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 10),
                _consoleLine('Auto-evaluation', 'ACTIVE', true),
                _consoleLine('Next evaluation', 'Aug 29, 2026', true),
                _consoleLine('Eligibility', '6-Month Badge MINTED', true),
                _consoleLine('Next unlock', 'Gold at 12 months', true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeCard({
    required String emoji, required String name, required String tier,
    required Color color, required String date, required String tx,
    required String status, required bool verified,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: verified ? color.withOpacity(0.4) : AppColors.border, width: verified ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
                    Text(tier, style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: verified ? AppColors.success.withOpacity(0.1) : AppColors.border.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(status, style: GoogleFonts.inter(
                    fontSize: 9, fontWeight: FontWeight.w800, color: verified ? AppColors.success : AppColors.muted)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(date, style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
          if (tx.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.link_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(tx, style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                const Spacer(),
                Text('View on Snowtrace', style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _consoleLine(String label, String value, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle_outline_rounded : Icons.radio_button_unchecked,
              size: 14, color: ok ? AppColors.success : AppColors.muted),
          const SizedBox(width: 6),
          Text('$label: ', style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
          Text(value, style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
        ],
      ),
    );
  }
}
