import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_models.dart';
import '../workforce/workforce_service.dart';
import 'create_collection_screen.dart';
import 'collection_detail_screen.dart';

/// Treasurer landing tab — live overview of the group's obligations.
class TreasurerDashboardScreen extends StatefulWidget {
  const TreasurerDashboardScreen({super.key});

  @override
  TreasurerDashboardState createState() => TreasurerDashboardState();
}

class TreasurerDashboardState extends State<TreasurerDashboardScreen> {
  void reload() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final stats = WorkforceService.stats();
    final active = WorkforceService.activeCollections;
    return RefreshIndicator(
      onRefresh: () async => reload(),
      color: AppColors.accent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            const SizedBox(height: 16),
            _statRow(stats),
            const SizedBox(height: 16),
            _rateCard(stats),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'ACTIVE COLLECTIONS',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.muted,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                Text(
                  '${active.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (active.isEmpty)
              _emptyState()
            else
              ...active.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _collectionCard(c),
                  )),
            const SizedBox(height: 12),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CreateCollectionScreen()),
                  ).then((_) {
                    if (mounted) setState(() {});
                  });
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Raise a new collection'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Image.network(
            AppImages.saccoGroup,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 150,
              color: AppColors.deep,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome back,',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 6),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        WorkforceService.currentUser?.name ??
                            WorkforceService.collectorDisplay(),
                        style: GoogleFonts.inter(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 8),
                            Shadow(color: Colors.black38, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded,
                                size: 13, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              '${WorkforceService.currentUser?.position ?? 'Treasurer'} · ${WorkforceService.currentUser?.orgName ?? WorkforceService.orgName}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 92,
                  child: Image.asset(AppAssets.logoFull,
                      fit: BoxFit.contain),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(Map<String, dynamic> s) {
    final cards = [
      ('${s['members']}', 'Members', Icons.people_rounded, AppColors.primary),
      ('Ksh ${_fmt(s['collected'])}', 'Collected', Icons.payments_rounded,
          AppColors.accent),
      ('${s['paidMembers']}/${s['members']}', 'Paid in', Icons.check_circle_rounded,
          AppColors.gold),
      ('${s['activeCollections']}', 'Active', Icons.receipt_long_rounded,
          AppColors.secondary),
    ];
    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _statCard(cards[i].$1, cards[i].$2, cards[i].$3, cards[i].$4)),
        ],
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _rateCard(Map<String, dynamic> s) {
    final rate = (s['rate'] as num).clamp(0, 100).toDouble();
    final reminders = s['pendingReminders'] as int;
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
                child: Text(
                  'Collection rate',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              Text(
                '${rate.toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: rate / 100,
              minHeight: 8,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$reminders members are still waiting on reminders — resend them from any collection.',
            style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _collectionCard(WfCollection c) {
    final paid = c.paidCount;
    final total = c.tasks.length;
    final pct = total == 0 ? 0.0 : (paid / total) * 100;
    final daysLeft = c.due.difference(DateTime.now()).inDays;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => CollectionDetailScreen(collection: c)),
        ).then((_) {
          if (mounted) setState(() {});
        });
      },
      child: Container(
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    c.type.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  daysLeft <= 0 ? 'Due today' : '$daysLeft days left',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: daysLeft <= 2 ? AppColors.danger : AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              c.title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ksh ${_fmt(c.amount)} · ${c.railName}',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 6,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$paid/$total paid',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_rounded, size: 34, color: AppColors.muted),
          const SizedBox(height: 8),
          Text(
            'No active collections yet.',
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
          ),
          const SizedBox(height: 4),
          Text(
            'Raise a welfare levy, medical top-up or emergency to get started.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }

  static String _fmt(num n) {
    final s = n.toStringAsFixed(n == n.roundToDouble() ? 0 : 2);
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }
}
