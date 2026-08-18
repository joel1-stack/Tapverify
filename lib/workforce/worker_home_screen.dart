import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_models.dart';
import '../workforce/workforce_service.dart';
import 'worker_payment_flow_screen.dart';

/// Worker side — what the app serves each factory worker: due obligations,
/// paid history, streak and badges. This is the experience the web demo plays.
class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  late WfWorker _worker;

  @override
  void initState() {
    super.initState();
    _worker = WorkforceService.workerById('w-47') ??
        WorkforceService.workers.first;
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final due = WorkforceService.tasksForWorker(_worker.id)
        .where((e) => e.task.state.index < WfPaymentState.completed.index)
        .toList();
    final paid = WorkforceService.tasksForWorker(_worker.id)
        .where((e) => e.task.state.index >= WfPaymentState.completed.index)
        .toList();
    final dueTotal =
        due.fold<double>(0, (s, e) => s + e.task.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text(
          'Worker',
          style: GoogleFonts.inter(
              fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        color: AppColors.accent,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _profileCard(),
            const SizedBox(height: 16),
            if (due.isNotEmpty) ...[
              Row(
                children: [
                  Text(
                    'DUE · Ksh ${_fmt(dueTotal)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${due.length}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final e in due) ...[
                _dueCard(e.collection, e.task),
                const SizedBox(height: 10),
              ],
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'YOUR BADGES',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.muted,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                Text(
                  '${WorkforceService.badges.where((b) => b.earned).length}/${WorkforceService.badges.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _badgesCard(),
            if (paid.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'PAID HISTORY · PROOF',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              for (final e in paid.reversed.take(4)) ...[
                _paidCard(e.collection, e.task),
                const SizedBox(height: 8),
              ],
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _profileCard() {
    final earned = WorkforceService.badges.where((b) => b.earned).length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.deep, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 22,
              backgroundColor:
                  HSLColor.fromAHSL(1, _worker.avatarHue, 0.55, 0.62).toColor(),
              child: Text(
                _worker.name.split(' ').map((e) => e[0]).take(2).join(),
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _worker.name,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_worker.code} · ${_worker.department} · ${WorkforceService.orgName}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _chip(
                        Icons.local_fire_department_rounded,
                        '${_worker.currentStreak}-month streak',
                        Colors.white,
                        AppColors.gold),
                    const SizedBox(width: 8),
                    _chip(Icons.workspace_premium_rounded,
                        '$earned badges earned', Colors.white,
                        AppColors.primaryLight),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bg.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: bg),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _dueCard(WfCollection c, WfPaymentTask t) {
    final daysLeft = c.due.difference(DateTime.now()).inDays;
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
                daysLeft <= 0
                    ? 'Due today'
                    : '$daysLeft days left',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: daysLeft <= 2 ? AppColors.danger : AppColors.muted,
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
            'Ksh ${_fmt(c.amount)} via ${c.railName}',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: t.state.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.state.icon, size: 12, color: t.state.color),
                    const SizedBox(width: 4),
                    Text(
                      t.state.label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: t.state.color,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkerPaymentFlowScreen(
                        collection: c,
                        worker: _worker,
                      ),
                    ),
                  ).then((_) {
                    if (mounted) setState(() {});
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
                child: const Text('Pay now'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badgesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final b in WorkforceService.badges) ...[
            if (b != WorkforceService.badges.first) const SizedBox(width: 10),
            Expanded(
              child: Tooltip(
                message: '${b.title} — ${b.desc}',
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: (b.earned ? b.color : AppColors.muted)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: (b.earned ? b.color : AppColors.muted)
                            .withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        b.earned ? b.icon : Icons.lock_rounded,
                        size: 20,
                        color: b.earned ? b.color : AppColors.muted,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        b.earned ? b.title : 'Locked',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: b.earned ? b.color : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _paidCard(WfCollection c, WfPaymentTask t) {
    final w = _worker;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: t.state.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(t.state.icon, color: t.state.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.title,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ksh ${_fmt(t.amount)} · ${t.rail}',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  'ref ${t.txnRef} · ${t.paidAt != null ? _time(t.paidAt!) : ''}',
                  style: GoogleFonts.inter(
                      fontSize: 10.5, color: AppColors.text, height: 1.3),
                ),
              ],
            ),
          ),
          Icon(Icons.verified_rounded, color: w.onTimePct >= 90
              ? const Color(0xFF16A34A)
              : AppColors.muted, size: 22),
        ],
      ),
    );
  }

  static String _time(DateTime d) =>
      '${d.day}/${d.month} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static String _fmt(num n) {
    final s = n.toStringAsFixed(n == n.roundToDouble() ? 0 : 2);
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }
}
