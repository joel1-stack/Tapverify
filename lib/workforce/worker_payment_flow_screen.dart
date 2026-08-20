import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../services/receipt_pdf.dart';
import '../workforce/workforce_models.dart';
import '../workforce/workforce_service.dart';
import 'notification_center.dart';

/// Worker payment flow — simulates the rail checkout and animates the task
/// through CREATED → NOTIFIED → PENDING → COMPLETED → VERIFIED, ending in a
/// proof receipt. Real rails replace the simulation later, same UI contract.
class WorkerPaymentFlowScreen extends StatefulWidget {
  const WorkerPaymentFlowScreen({
    required this.collection,
    required this.worker,
  });

  final WfCollection collection;
  final WfWorker worker;

  @override
  State<WorkerPaymentFlowScreen> createState() => _WorkerPaymentFlowScreenState();
}

class _WorkerPaymentFlowScreenState extends State<WorkerPaymentFlowScreen> {
  int _step = 0;
  bool _running = false;
  Timer? _timer;
  WfPaymentTask? _paid;

  static const _journey = [
    WfPaymentState.created,
    WfPaymentState.notified,
    WfPaymentState.pending,
    WfPaymentState.completed,
    WfPaymentState.verified,
  ];

  WfCollection get c => widget.collection;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _running = true;
      _step = 0;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (_step >= _journey.length - 1) {
        t.cancel();
        setState(() {
          _paid = WorkforceService.payNow(c, widget.worker.id);
          WorkforceService.verify(c, widget.worker.id);
        });
        NotificationCenter.instance.notify(
          title: 'Payment verified',
          body:
              '${widget.worker.name} paid Ksh ${_fmt(c.amount)} for ${c.title}.',
          icon: Icons.verified_rounded,
          color: AppColors.success,
        );
        return;
      }
      setState(() => _step++);
    });
  }

  Future<void> _shareReceipt() async {
    final task = _paid!;
    final u = WorkforceService.currentUser;
    await shareReceiptPdf(
      ReceiptData(
        receiptNo: 'RCP-${task.txnRef}',
        timestamp: task.paidAt != null
            ? '${task.paidAt!.day}/${task.paidAt!.month}/${task.paidAt!.year} ${task.paidAt!.hour.toString().padLeft(2, '0')}:${task.paidAt!.minute.toString().padLeft(2, '0')}'
            : DateTime.now().toString().substring(0, 16),
        collectorName: u?.name ?? WorkforceService.demoForemanName,
        collectorRole: u?.position ?? 'Collector',
        collectorOrg: u?.orgName ?? WorkforceService.orgName,
        memberName: '${widget.worker.name} · ${widget.worker.code}',
        obligation: c.title,
        amount: 'Ksh ${_fmt(task.amount)}',
        rail: task.rail,
        transferId: task.txnRef,
        state: '${task.state.label} · ${task.state.desc}',
      ),
      filename: 'TapVerify_receipt_${widget.worker.code}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final done = _paid != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text(
          done ? 'Proof of payment' : 'Pay',
          style: GoogleFonts.inter(
              fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text),
        ),
      ),
      body: done ? _receipt() : _checkout(),
    );
  }

  Widget _checkout() {
    final railIcon = c.railId == 'sasapay'
        ? Icons.link_rounded
        : c.railId == 'paybill'
            ? Icons.receipt_rounded
            : Icons.bolt_rounded;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            c.title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${c.type} · due ${_date(c.due)}',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Container(
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
              children: [
                Text(
                  'Ksh ${_fmt(c.amount)}',
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.worker.name} · ${widget.worker.code}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(railIcon, color: AppColors.secondary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.railName,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.railId == 'sasapay'
                            ? 'Checkout link opens your bank/M-PESA app'
                            : 'M-PESA prompt pushed to your phone',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_running) ...[
            const _JourneyCard(step: 5),
            const SizedBox(height: 16),
          ],
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _running ? null : _start,
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              icon: Icon(_running
                  ? Icons.hourglass_top_rounded
                  : Icons.lock_open_rounded),
              label: Text(
                  _running ? 'Processing payment...' : 'Pay Ksh ${_fmt(c.amount)}'),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Payment is verified end-to-end. A signed receipt is generated the moment the rail confirms the transfer.',
            textAlign: TextAlign.center,
            style:
                GoogleFonts.inter(fontSize: 11, color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _receipt() {
    final task = _paid!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        const Icon(Icons.check_circle_rounded,
            size: 72, color: Color(0xFF16A34A)),
        const SizedBox(height: 12),
        Text(
          'Payment verified',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your proof is recorded. The foreman sees this in real time.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _receiptRow('Obligation', c.title),
              _receiptRow('Worker', widget.worker.name),
              _receiptRow('Amount', 'Ksh ${_fmt(task.amount)}'),
              _receiptRow('Rail', task.rail),
              _receiptRow('Transfer ID', task.txnRef),
              _receiptRow('State', '${task.state.label} · ${task.state.desc}'),
              _receiptRow('Timestamp',
                  '${task.paidAt!.day}/${task.paidAt!.month} ${task.paidAt!.hour.toString().padLeft(2, '0')}:${task.paidAt!.minute.toString().padLeft(2, '0')}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _JourneyCard(step: 5),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.accent, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Obligation → Payment → Proof. Your ${_streakBump()} streak continues.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _shareReceipt,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('Share PDF receipt'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }

  String _streakBump() {
    final s = widget.worker.currentStreak + 1;
    return s == 3 || s == 6 || s == 12 ? '$s-month' : '${s}-month';
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }

  static String _date(DateTime d) =>
      '${d.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]}';

  static String _fmt(num n) {
    final s = n.toStringAsFixed(n == n.roundToDouble() ? 0 : 2);
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }
}

/// Animated/static journey card reused by the flow and the receipt.
class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    const states = [
      WfPaymentState.created,
      WfPaymentState.notified,
      WfPaymentState.pending,
      WfPaymentState.completed,
      WfPaymentState.verified,
    ];
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
              const Icon(Icons.route_rounded, size: 15, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                'JOURNEY TO PROOF',
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
          for (int i = 0; i < states.length; i++) ...[
            _row(states[i], i),
            if (i < states.length - 1)
              Container(
                margin: const EdgeInsets.only(left: 16),
                width: 2,
                height: 14,
                color: i < step ? const Color(0xFF16A34A) : AppColors.border,
              ),
          ],
        ],
      ),
    );
  }

  Widget _row(WfPaymentState st, int i) {
    final done = i < step;
    final active = i == step;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: done
                ? const Color(0xFF16A34A)
                : active
                    ? st.color
                    : AppColors.muted.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            done
                ? Icons.check_rounded
                : active
                    ? st.icon
                    : st.icon,
            size: 16,
            color: done || active ? Colors.white : AppColors.muted,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${st.label} — ${st.desc}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: done || active
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: done || active ? AppColors.text : AppColors.muted,
            ),
          ),
        ),
      ],
    );
  }
}
