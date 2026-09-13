import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../constants.dart';
import '../workforce/workforce_models.dart';

class PersonScreen extends StatelessWidget {
  final WfMember member;
  const PersonScreen({super.key, required this.member});

  void _sendReminder(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Reminder SMS sent to ${member.name}',
          style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _shareReceipt(BuildContext context) {
    HapticFeedback.lightImpact();
    final msg = 'Payment receipt for ${member.name}\n'
        'Amount: Ksh ${_fmt(member.amount)}\n'
        'Group: Kamau Welfare\n'
        'Date: ${_formatDate(member.paidDate!)}\n'
        'TapVerify — Verified payment';
    Share.share(msg);
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = member.status == 'PAID';
    final badge = _getBadge(member.streakMonths);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text(member.name,
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
        actions: [
          if (isPaid)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: () => _shareReceipt(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                          isPaid
                              ? AppColors.success.withValues(alpha: 0.7)
                              : AppColors.danger.withValues(alpha: 0.7),
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
                  const SizedBox(height: 14),
                  Text(member.name,
                      style: GoogleFonts.inter(
                          fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
                  const SizedBox(height: 4),
                  Text(member.phone,
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.muted)),
                  const SizedBox(height: 16),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
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
                    const SizedBox(height: 10),
                    Text('${member.daysLate} days late',
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.danger)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment info (if paid)
            if (isPaid) ...[
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Ksh ${_fmt(member.amount)}',
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ),
                    const SizedBox(width: 12),
                    Text('Paid on ${_formatDate(member.paidDate!)}',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Streak card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDBA74)),
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
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFB45309))),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Badge card
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
                    Text(badge['emoji']!, style: const TextStyle(fontSize: 36)),
                    const SizedBox(height: 8),
                    Text(badge['name']!,
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
                    const SizedBox(height: 4),
                    Text('Payer Badge',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Tx: ${badge['tx']}',
                          style: GoogleFonts.inter(
                              fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.gold)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Action button
            if (!isPaid) ...[
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _sendReminder(context),
                  icon: const Icon(Icons.sms_rounded, size: 20),
                  label: Text('SEND REMINDER SMS',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
            if (isPaid) ...[
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _shareReceipt(context),
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: Text('SHARE RECEIPT',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
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
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
