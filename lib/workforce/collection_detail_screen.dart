import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_models.dart';
import '../workforce/workforce_service.dart';

/// Collection detail — the proof center. Shows the 9-state lifecycle, how much
/// is in, who paid (with rail evidence + transfer reference), and lets the
/// foreman remind, simulate a payment and verify proof.
class CollectionDetailScreen extends StatefulWidget {
  const CollectionDetailScreen({required this.collection});

  final WfCollection collection;

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  final _query = TextEditingController();
  String _filter = 'All';

  static const _filters = ['All', 'Paid', 'Pending', 'Notified', 'Created'];

  WfCollection get c => widget.collection;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<WfPaymentTask> _visible() {
    final q = _query.text.trim().toLowerCase();
    return c.tasks.values.where((t) {
      if (q.isNotEmpty) {
        final w = WorkforceService.workerById(t.workerId);
        if (w == null) return false;
        if (!w.name.toLowerCase().contains(q) &&
            !w.code.toLowerCase().contains(q) &&
            !w.department.toLowerCase().contains(q)) {
          return false;
        }
      }
      switch (_filter) {
        case 'Paid':
          return t.state.index >= WfPaymentState.completed.index;
        case 'Pending':
          return t.state == WfPaymentState.pending;
        case 'Notified':
          return t.state == WfPaymentState.notified;
        case 'Created':
          return t.state == WfPaymentState.created;
      }
      return true;
    }).toList()..sort((a, b) => a.workerId.compareTo(b.workerId));
  }

  void _simulatePayment() {
    final target = c.tasks.values
        .where((t) => t.state.index < WfPaymentState.completed.index)
        .toList();
    if (target.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Everyone has paid in this collection',
              style: GoogleFonts.inter()),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() {
      for (final t in target.take(1)) {
        WorkforceService.payNow(c, t.workerId);
        WorkforceService.verify(c, t.workerId);
      }
    });
  }

  void _remindPending() {
    var n = 0;
    setState(() {
      for (final t in c.tasks.values) {
        if (t.state == WfPaymentState.pending ||
            t.state == WfPaymentState.created) {
          t.state = WfPaymentState.notified;
          n++;
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('SMS reminder sent to $n workers',
            style: GoogleFonts.inter()),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _close() {
    setState(() => c.closed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Collection archived', style: GoogleFonts.inter()),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = c.tasks.length;
    final paid = c.paidCount;
    final pct = total == 0 ? 0.0 : (paid / total) * 100;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text(
          c.title,
          style: GoogleFonts.inter(
              fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _summaryCard(pct, paid, total),
                const SizedBox(height: 16),
                const _LifecycleStrip(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'WHO PAID · ${c.tasks.length} WORKERS',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.muted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${paid} paid',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _query,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search worker, code or department',
                    prefixIcon: Icon(Icons.search_rounded),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final f in _filters) ...[
                        ChoiceChip(
                          label: Text(f),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                          selectedColor: AppColors.primary,
                          labelStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: _filter == f ? Colors.white : AppColors.text,
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
                if (_visible().isEmpty)
                  _emptyResult()
                else
                  for (final t in _visible()) ...[
                    _workerRow(t),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          ),
          _actionBar(pct),
        ],
      ),
    );
  }

  Widget _summaryCard(double pct, int paid, int total) {
    final daysLeft = c.due.difference(DateTime.now()).inDays;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  c.type.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                daysLeft <= 0 ? 'Due today' : '$daysLeft days left',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Ksh ${_fmt(c.collected)} collected',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'of Ksh ${_fmt(c.amount * total)} expected · ${pct.toStringAsFixed(0)}% · ${c.railName}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _workerRow(WfPaymentTask t) {
    final w = WorkforceService.workerById(t.workerId);
    if (w == null) return const SizedBox.shrink();
    final st = t.state;
    final paid = st.index >= WfPaymentState.completed.index;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: HSLColor.fromAHSL(1, w.avatarHue, 0.55, 0.62)
                .toColor(),
            child: Text(
              w.name.split(' ').map((e) => e[0]).take(2).join(),
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
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
                  '${w.code} · ${w.department}',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.muted),
                ),
                if (paid) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${t.rail} · ${t.txnRef}'
                    '${t.paidAt != null ? ' · ${t.paidAt!.hour.toString().padLeft(2, '0')}:${t.paidAt!.minute.toString().padLeft(2, '0')}' : ''}',
                    style: GoogleFonts.inter(
                        fontSize: 10.5, color: AppColors.text, height: 1.3),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: st.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(st.icon, size: 12, color: st.color),
                    const SizedBox(width: 4),
                    Text(
                      st.label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: st.color,
                      ),
                    ),
                  ],
                ),
              ),
              if (!paid)
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    setState(() {
                      if (t.state == WfPaymentState.pending ||
                          t.state == WfPaymentState.created) {
                        t.state = WfPaymentState.notified;
                      }
                    });
                  },
                  child: Text(
                    'Remind',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBar(double pct) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _remindPending,
                icon: const Icon(Icons.notifications_active_rounded, size: 18),
                label: const Text('Remind all'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: pct >= 100 ? _close : _simulatePayment,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent),
                icon: Icon(
                    pct >= 100 ? Icons.archive_rounded : Icons.bolt_rounded,
                    size: 18),
                label: Text(pct >= 100 ? 'Archive' : 'Record a payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyResult() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 30, color: AppColors.muted),
          const SizedBox(height: 8),
          Text(
            'No workers match this filter.',
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
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

/// Horizontal 9-state lifecycle strip — the product's trust contract.
class _LifecycleStrip extends StatelessWidget {
  const _LifecycleStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              const Icon(Icons.route_rounded, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                'TRANSACTION LIFECYCLE',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < WfPaymentState.values.length; i++) ...[
                  if (i > 0)
                    Container(
                      width: 14,
                      height: 2,
                      color: AppColors.border,
                    ),
                  _stateDot(WfPaymentState.values[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Every payment is an obligation that can be tracked from creation to proof. In production the proof layer is a signed webhook / Avalanche attestation.',
            style: GoogleFonts.inter(
                fontSize: 10.5, color: AppColors.muted, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _stateDot(WfPaymentState st) {
    return Tooltip(
      message: '${st.label} — ${st.desc}',
      child: Container(
        width: 44,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: st.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: st.color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Icon(st.icon, size: 16, color: st.color),
            const SizedBox(height: 3),
            Text(
              st.label,
              style: GoogleFonts.inter(
                fontSize: 7.5,
                fontWeight: FontWeight.w800,
                color: st.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
