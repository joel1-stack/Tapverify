import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_models.dart';
import '../workforce/workforce_service.dart';
import 'create_collection_screen.dart';
import 'collection_detail_screen.dart';
import 'revenue_report_screen.dart';
import 'credit_profile_screen.dart';
import 'badges_screen.dart';

/// Dashboard — clean overview with 3 stats, quick actions, and recent orders.
class TreasurerDashboardScreen extends StatefulWidget {
  const TreasurerDashboardScreen({super.key});
  @override
  State<TreasurerDashboardScreen> createState() => _TreasurerDashboardScreenState();
}

class _TreasurerDashboardScreenState extends State<TreasurerDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final stats = WorkforceService.stats();
    final active = WorkforceService.activeCollections;
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero header ──
            _heroHeader(),
            const SizedBox(height: 16),

            // ── 3 stat cards ──
            Row(
              children: [
                _statCard(
                    'Ksh ${_fmt(stats['collected'])}',
                    'Verified revenue',
                    Icons.payments_rounded,
                    AppColors.primary),
                const SizedBox(width: 10),
                _statCard(
                    '${stats['totalTransactions']}',
                    'Verified transactions',
                    Icons.check_circle_rounded,
                    AppColors.success),
                const SizedBox(width: 10),
                _statCard(
                    '${(stats['consistency'] as double).toStringAsFixed(0)}%',
                    'Consistency',
                    Icons.speed_rounded,
                    AppColors.gold),
              ],
            ),
            const SizedBox(height: 16),

            // ── Revenue milestone progress ──
            _milestoneProgress(),
            const SizedBox(height: 12),

            // ── Consistency streak ──
            _streakCard(),
            const SizedBox(height: 12),

            // ── Trust score ──
            _trustScoreCard(),
            const SizedBox(height: 12),

            // ── Lender-ready checklist ──
            _lenderChecklist(),
            const SizedBox(height: 16),

            // ── Quick actions ──
            Row(
              children: [
                Expanded(
                  child: _quickAction(
                    Icons.bar_chart_rounded,
                    'Revenue Report',
                    'Monthly breakdown',
                    AppColors.primary,
                    () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RevenueReportScreen())),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickAction(
                    Icons.credit_score_rounded,
                    'Credit Profile',
                    'Lender-ready proof',
                    AppColors.deep,
                    () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CreditProfileScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _quickAction(
                    Icons.emoji_events_rounded,
                    'My Badges',
                    'On-chain attestation',
                    AppColors.gold,
                    () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const BadgesScreen())),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickAction(
                    Icons.shield_rounded,
                    'Payer Score',
                    'Universal reputation',
                    AppColors.success,
                    () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const BadgesScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Active orders header ──
            Row(
              children: [
                Text('RECENT ORDERS',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.muted,
                        letterSpacing: 0.6)),
                const Spacer(),
                Text('${active.length}',
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 8),

            // ── Order list ──
            if (active.isEmpty)
              _emptyState()
            else
              ...active.take(4).map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _orderCard(c),
                  )),

            const SizedBox(height: 12),

            // ── Create order button ──
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CreateCollectionScreen())),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text('Record customer payment',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroHeader() {
    return Container(
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
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text('PM',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Peter's Metal Works",
                        style: GoogleFonts.inter(
                            fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('Kariobangi, Nairobi',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text('CREDITWORTHY · 6 months verified',
                    style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }

  Widget _milestoneProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('YOUR REVENUE JOURNEY', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.5)),
              const Spacer(),
              Text('💎 Trusted', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.48,
              minHeight: 10,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Ksh 2.4M', style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
              Text(' / 5M', style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.muted)),
              const Spacer(),
              Text('Ksh 2.6M to Champion', style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 4),
          Text('🎯 Next unlock: Credit Profile Export at Ksh 5M', style: GoogleFonts.inter(
              fontSize: 11, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _streakCard() {
    return Container(
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
                Text('12-Day Recording Streak', style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
                Text('Record payments every day to keep it alive', style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('RECORD: 18', style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.muted)),
              Text('🎁 Ksh 50 airtime at 15 days', style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trustScoreCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('TRUST SCORE', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.5)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('EXCELLENT', style: GoogleFonts.inter(
                    fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.success)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('87', style: GoogleFonts.inter(
                  fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.text)),
              Text(' / 100', style: GoogleFonts.inter(
                  fontSize: 16, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _trustBar('Verification', '98%'),
              const SizedBox(width: 12),
              _trustBar('Response', '4.2h'),
              const SizedBox(width: 12),
              _trustBar('Growth', '+23%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trustBar(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.muted)),
          Text(value, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text)),
        ],
      ),
    );
  }

  Widget _lenderChecklist() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('LENDER-READY CHECKLIST', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          _checkItem(true, 'Verified Ksh 100K+ revenue'),
          _checkItem(true, '30+ days of payment history'),
          _checkItem(true, 'Zero disputed payments'),
          _checkItem(false, '6-month consistency streak — 2 months to go'),
          _checkItem(false, 'Connect SACCO account'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.celebration_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text('You are 2 checks away from a Lender-Ready Profile!', style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkItem(bool checked, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 18,
            color: checked ? AppColors.success : AppColors.muted,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: checked ? AppColors.text : AppColors.muted))),
        ],
      ),
    );
  }

  Widget _rateBar(Map<String, dynamic> s) {
    final rate = (s['rate'] as num).clamp(0, 100).toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Fulfillment rate',
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
              ),
              Text('${rate.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: rate / 100,
              minHeight: 8,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderCard(WfCollection c) {
    final paid = c.paidCount;
    final total = c.tasks.length;
    final pct = total == 0 ? 0.0 : (paid / total) * 100;
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => CollectionDetailScreen(collection: c))),
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
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.title,
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                  const SizedBox(height: 2),
                  Text('Ksh ${_fmt(c.amount)} · $paid/$total paid',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
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
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
                  Text(subtitle,
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_rounded, size: 36, color: AppColors.muted),
          const SizedBox(height: 10),
          Text('No orders yet',
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 4),
          Text('Record a customer payment to get started.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    );
  }

  static String _fmt(num n) {
    final s = n.toStringAsFixed(n == n.roundToDouble() ? 0 : 2);
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }
}
