import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_models.dart';
import '../workforce/workforce_service.dart';

/// Customers — clean list with streak and status.
class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});
  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<WfMember> _visible() {
    final q = _query.text.trim().toLowerCase();
    return WorkforceService.activeCollections
        .expand((c) => c.tasks.values)
        .map((t) => WorkforceService.memberById(t.workerId))
        .whereType<WfMember>()
        .where((w) {
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
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Search customers...',
              hintStyle: GoogleFonts.inter(color: AppColors.muted.withOpacity(0.5)),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => setState(() {}),
            color: AppColors.primary,
            child: list.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                          child: Icon(Icons.person_search_rounded,
                              size: 40, color: AppColors.muted)),
                      SizedBox(height: 8),
                      Center(
                          child: Text('No customers found',
                              style: TextStyle(color: AppColors.muted))),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: list.length,
                    itemBuilder: (context, i) => _customerCard(list[i]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _customerCard(WfMember w) {
    final activeDue = WorkforceService.tasksForMember(w.id)
        .where((e) => e.task.state.index < WfPaymentState.completed.index)
        .length;
    final isClear = activeDue == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
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
                Text(w.name,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                const SizedBox(height: 2),
                Text(w.code,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isClear ? AppColors.success : AppColors.warning)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isClear ? 'CLEAR' : '$activeDue DUE',
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isClear ? AppColors.success : AppColors.warning),
            ),
          ),
          const SizedBox(width: 8),
          // Streak
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    size: 12, color: AppColors.gold),
                const SizedBox(width: 3),
                Text('${w.currentStreak}',
                    style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
