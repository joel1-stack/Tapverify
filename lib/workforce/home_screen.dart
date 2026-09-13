import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_models.dart';
import '../workforce/workforce_service.dart';
import 'collect_screen.dart';
import 'person_screen.dart';
import 'proof_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _remindMember(WfMember member) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Reminder SMS sent to ${member.name}',
          style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      action: SnackBarAction(
        label: 'VIEW',
        textColor: Colors.white,
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => PersonScreen(member: member))),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final stats = WorkforceService.stats();
    final members = WorkforceService.members();
    final totalCollected = stats['collected'] as int;
    final totalMembers = members.length;
    final paidCount = members.where((m) => m.status == 'PAID').length;
    final unpaidCount = totalMembers - paidCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          // Hero card
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.deep, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kamau Welfare Group',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('Ksh ${_fmt(totalCollected)}',
                      style: GoogleFonts.inter(
                          fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Collected this month',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _heroStat('🔥', '12mo streak', Colors.white),
                      const SizedBox(width: 16),
                      _heroStat('✅', '$paidCount paid', Colors.white),
                      const SizedBox(width: 16),
                      _heroStat('🔴', '$unpaidCount unpaid', Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Section header + Ask for Payment
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Text('MEMBERS',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w800,
                          color: AppColors.muted, letterSpacing: 0.8)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CollectScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text('ASK FOR PAYMENT',
                              style: GoogleFonts.inter(
                                  fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Member list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final member = members[index];
                final isPaid = member.status == 'PAID';
                return GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => PersonScreen(member: member))),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    padding: const EdgeInsets.all(14),
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
                      children: [
                        // Avatar circle
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: isPaid
                                ? AppColors.success.withValues(alpha: 0.12)
                                : AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              member.name.substring(0, 1).toUpperCase(),
                              style: GoogleFonts.inter(
                                  fontSize: 17, fontWeight: FontWeight.w800,
                                  color: isPaid ? AppColors.success : AppColors.danger),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(member.name,
                                  style: GoogleFonts.inter(
                                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                              const SizedBox(height: 2),
                              Text('Ksh ${_fmt(member.amount)} · ${member.phone}',
                                  style: GoogleFonts.inter(
                                      fontSize: 11, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        // Right side: status + remind
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isPaid
                                    ? AppColors.success.withValues(alpha: 0.12)
                                    : AppColors.danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isPaid ? 'PAID ✓' : 'NOT PAID',
                                style: GoogleFonts.inter(
                                    fontSize: 10, fontWeight: FontWeight.w700,
                                    color: isPaid ? AppColors.success : AppColors.danger),
                              ),
                            ),
                            if (!isPaid) ...[
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () => _remindMember(member),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('REMIND',
                                      style: GoogleFonts.inter(
                                          fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                                ),
                              ),
                            ],
                            if (isPaid && member.daysLate == 0) ...[
                              const SizedBox(height: 4),
                              Text('✓ Paid',
                                  style: GoogleFonts.inter(
                                      fontSize: 10, color: AppColors.success)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: members.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _heroStat(String emoji, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(text,
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  String _fmt(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
