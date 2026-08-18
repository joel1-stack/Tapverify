import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_models.dart';
import '../workforce/workforce_service.dart';
import 'collection_detail_screen.dart';

/// Collections tab — every obligation, active and archived.
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
      color: AppColors.accent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          for (final c in active) ...[
            _card(c),
            const SizedBox(height: 10),
          ],
          if (closed.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'ARCHIVED',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.muted,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            for (final c in closed) ...[
              _card(c, archived: true),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }

  Widget _card(WfCollection c, {bool archived = false}) {
    final paid = c.paidCount;
    final total = c.tasks.length;
    final pct = total == 0 ? 0.0 : (paid / total) * 100;
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
                  child: Text(
                    c.type.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: archived ? AppColors.muted : AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  archived
                      ? 'ARCHIVED'
                      : c.due.difference(DateTime.now()).inDays <= 0
                          ? 'Due today'
                          : '${c.due.difference(DateTime.now()).inDays} days left',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: archived ? AppColors.muted : AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              c.title,
              style: GoogleFonts.inter(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ksh ${c.amount} · ${c.railName} · ${c.tasks.length} workers',
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
                      valueColor: AlwaysStoppedAnimation(
                          archived ? AppColors.muted : AppColors.accent),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  archived ? '${pct.toStringAsFixed(0)}% closed' : '$paid/$total paid',
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
}
