import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_models.dart';
import '../workforce/workforce_service.dart';

/// Workers tab — the 47-strong Kamau Metalworks roster grouped by department,
/// with on-time records and streaks.
class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  final _query = TextEditingController();
  String _dept = 'All';

  static const _departments = [
    'All',
    'Foundry',
    'Machining',
    'Assembly',
    'Fabrication',
    'Admin',
  ];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<WfWorker> _visible() {
    final q = _query.text.trim().toLowerCase();
    return WorkforceService.workers.where((w) {
      if (_dept != 'All' && w.department != _dept) return false;
      if (q.isNotEmpty &&
          !w.name.toLowerCase().contains(q) &&
          !w.code.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _visible();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: TextField(
            controller: _query,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search member or code',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (final d in _departments) ...[
                ChoiceChip(
                  label: Text(d),
                  selected: _dept == d,
                  onSelected: (_) => setState(() => _dept = d),
                  selectedColor: AppColors.primary,
                  labelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: _dept == d ? Colors.white : AppColors.text,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppColors.border),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => setState(() {}),
            color: AppColors.accent,
            child: list.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Icon(Icons.person_search_rounded,
                            size: 40, color: AppColors.muted),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: Text('No members found',
                            style: TextStyle(color: AppColors.muted)),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: list.length,
                    itemBuilder: (context, i) => _workerRow(list[i]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _workerRow(WfWorker w) {
    final activeDue = WorkforceService.tasksForWorker(w.id)
        .where((e) => e.task.state.index < WfPaymentState.completed.index)
        .length;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                HSLColor.fromAHSL(1, w.avatarHue, 0.55, 0.62).toColor(),
            child: Text(
              w.name.split(' ').map((e) => e[0]).take(2).join(),
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.name,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${w.code} · ${w.department} · since ${w.memberSince}',
                  style:
                      GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          if (activeDue > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '$activeDue due',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.warning,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withOpacity(0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                'CLEAR',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    size: 12, color: AppColors.gold),
                const SizedBox(width: 3),
                Text(
                  '${w.currentStreak}',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
