import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../constants.dart';
import '../workforce/workforce_models.dart';

/// Person page - Individual member detail
class PersonScreen extends StatelessWidget {
  final WfMember member;
  
  const PersonScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final isPaid = member.status == 'PAID';
    final badge = _getBadge(member.streakMonths);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text(member.name,
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isPaid ? AppColors.success : AppColors.danger,
                          isPaid ? AppColors.success.withValues(alpha: 0.7) : AppColors.danger.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        member.name.substring(0, 1).toUpperCase(),
                        style: GoogleFonts.inter(
                            fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Name and phone
                  Text(member.name,
                      style: GoogleFonts.inter(
                          fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
                  const SizedBox(height: 4),
                  Text(member.phone,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.muted)),
                  const SizedBox(height: 16),
                  
                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isPaid ? AppColors.success.withValues(alpha: 0.12) : AppColors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPaid ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 18,
                          color: isPaid ? AppColors.success : AppColors.danger,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isPaid ? 'PAID ✓' : 'NOT PAID',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w700, 
                              color: isPaid ? AppColors.success : AppColors.danger),
                        ),
                      ],
                    ),
                  ),
                  
                  if (!isPaid && member.daysLate > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${member.daysLate} days late',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.danger),
                    ),
                  ],
                  
                  if (isPaid) ...[
                    const SizedBox(height: 16),
                    // Payment info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Ksh ${_fmt(member.amount)}',
                            style: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Paid on ${_formatDate(member.paidDate!)}',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // If paid, show streak and badge
            if (isPaid) ...[
              Text('PAYMENT HISTORY',
                  style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w800,
                      color: AppColors.muted, letterSpacing: 0.6)),
              const SizedBox(height: 8),
              
              // Streak card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text('${member.streakMonths}-Month Streak',
                            style: GoogleFonts.inter(
                                fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF92400E))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('with Kamau Welfare',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: const Color(0xFFB45309))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('ACTIVE',
                          style: GoogleFonts.inter(
                              fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Badge card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Text(badge['emoji']!, style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 6),
                    Text(badge['name']!, 
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                    const SizedBox(height: 2),
                    Text('Payer Badge',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.muted)),
                    const SizedBox(height: 8),
                    Text('Tx: ${badge['tx']}',
                        style: GoogleFonts.inter(
                            fontSize: 10, color: AppColors.text)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Actions
            if (!isPaid) ...[
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.sms_rounded),
                label: Text('📱 SEND REMINDER SMS',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            
            if (isPaid) ...[
              OutlinedButton.icon(
                onPressed: () => Share.share('Payment receipt for ${member.name}: Ksh ${_fmt(member.amount)}'),
                icon: const Icon(Icons.share_rounded),
                label: Text('📤 SHARE RECEIPT',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, String> _getBadge(int streakMonths) {
    if (streakMonths >= 12) {
      return {'emoji': '🥇', 'name': 'Gold Payer', 'tx': '0x7e8b...c4d2'};
    } else if (streakMonths >= 6) {
      return {'emoji': '🥈', 'name': 'Silver Payer', 'tx': '0x7e8b...c4d2'};
    } else if (streakMonths >= 3) {
      return {'emoji': '🥉', 'name': 'Bronze Payer', 'tx': '0x3f2a...b91c'};
    }
    return {'emoji': '⬜', 'name': 'New Payer', 'tx': 'Pending...'};
  }

  String _fmt(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
