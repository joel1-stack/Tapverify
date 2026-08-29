import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_models.dart';
import '../workforce/workforce_service.dart';
import 'collect_screen.dart';
import 'person_screen.dart';
import 'proof_screen.dart';

/// Home page - The Notebook
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final stats = WorkforceService.stats();
    final members = WorkforceService.members();
    final totalCollected = stats['collected'] as int;
    final totalMembers = members.length;
    final paidCount = members.where((m) => m.status == 'PAID').length;
    final streakMonths = 12;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text('Kamau Welfare Group',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProofScreen()),
            ),
            tooltip: 'Share Group Proof',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.deep, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ksh ${_fmt(totalCollected)}',
                          style: GoogleFonts.inter(
                              fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Total collected · ${_monthYear(DateTime.now())}',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: Colors.white.withOpacity(0.9))),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text('$streakMonths-month streak',
                                    style: GoogleFonts.inter(
                                        fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('$paidCount/$totalMembers paid',
                              style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Member list
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('MEMBERS',
                      style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w800,
                          color: AppColors.muted, letterSpacing: 0.6)),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final member = members[index];
                final isPaid = member.status == 'PAID';
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PersonScreen(member: member),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: isPaid ? AppColors.success.withValues(alpha: 0.12) : AppColors.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              member.name.substring(0, 1).toUpperCase(),
                              style: GoogleFonts.inter(
                                  fontSize: 16, fontWeight: FontWeight.w800, color: isPaid ? AppColors.success : AppColors.danger),
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
                                      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                              const SizedBox(height: 2),
                              Text('Ksh ${_fmt(member.amount)} · ${member.phone}',
                                  style: GoogleFonts.inter(
                                      fontSize: 11, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isPaid ? AppColors.success.withValues(alpha: 0.12) : AppColors.danger.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isPaid ? 'PAID ✓' : 'NOT PAID',
                                style: GoogleFonts.inter(
                                    fontSize: 10, fontWeight: FontWeight.w700, color: isPaid ? AppColors.success : AppColors.danger),
                              ),
                            ),
                            if (!isPaid && member.daysLate > 0) ...[
                              const SizedBox(height: 4),
                              Text('${member.daysLate}d late',
                                  style: GoogleFonts.inter(
                                      fontSize: 10, color: AppColors.danger)),
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
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CollectScreen()),
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text('Ask for Payment',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
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

  String _monthYear(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }
}
