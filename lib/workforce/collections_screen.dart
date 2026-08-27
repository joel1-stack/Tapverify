import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_models.dart';
import '../workforce/workforce_service.dart';
import 'collection_detail_screen.dart';

/// Orders List — clean list of all orders.
class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});
  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  @override
  Widget build(BuildContext context) {
    final active = WorkforceService.activeCollections;
    final closed = WorkforceService.closedCollections;
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          if (active.isEmpty && closed.isEmpty)
            _emptyState()
          else ...[
            ...active.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _orderCard(c),
                )),
            if (closed.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('ARCHIVED',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted,
                      letterSpacing: 0.6)),
              const SizedBox(height: 8),
              ...closed.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _orderCard(c, archived: true),
                  )),
            ],
          ],
        ],
      ),
    );
  }

  Widget _orderCard(WfCollection c, {bool archived = false}) {
    final paid = c.paidCount;
    final total = c.tasks.length;
    final pct = total == 0 ? 0.0 : (paid / total) * 100;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CollectionDetailScreen(collection: c)),
      ).then((_) => setState(() {})),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: archived ? AppColors.border : AppColors.primary.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: archived
                        ? AppColors.muted.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(c.type.toUpperCase(),
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: archived ? AppColors.muted : AppColors.primary)),
                ),
                const Spacer(),
                if (archived)
                  Text('ARCHIVED',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted))
                else
                  Text(
                    c.due.difference(DateTime.now()).inDays <= 0
                        ? 'Due today'
                        : '${c.due.difference(DateTime.now()).inDays} days',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(c.title,
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(height: 4),
            Text('Ksh ${_fmt(c.amount)} · $paid/$total paid',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 5,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(
                    archived ? AppColors.muted : AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_rounded, size: 40, color: AppColors.muted),
          const SizedBox(height: 12),
          Text('No orders yet',
              style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 4),
          Text('Tap + on Dashboard to record a payment.',
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
