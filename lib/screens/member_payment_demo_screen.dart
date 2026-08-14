import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../models/member.dart';
import '../services/contribution_service.dart';
import '../services/hive_service.dart';
import '../widgets/loop_value_strip.dart';
import 'success_screen.dart';

/// Animated demo of a member's payment journey, mirroring the LOOP demo style:
/// SMS reminder -> payment link -> PIN entry -> amount confirm -> pays via the
/// org rail -> instant receipt with ref. The payment is actually recorded so
/// it flows into the ledger + PDF.
class MemberPaymentDemoScreen extends StatefulWidget {
  final Map campaign;
  final Member member;

  const MemberPaymentDemoScreen({
    super.key,
    required this.campaign,
    required this.member,
  });

  @override
  State<MemberPaymentDemoScreen> createState() =>
      _MemberPaymentDemoScreenState();
}

class _MemberPaymentDemoScreenState extends State<MemberPaymentDemoScreen> {
  int _step = 0;
  bool _loading = false;
  bool _recorded = false;
  String _rail = 'M-PESA Till';
  Map<String, dynamic>? _receipt;
  Timer? _timer;

  static const _steps = [
    'SMS reminder delivered to member',
    'Member taps the payment link',
    'Member enters M-PESA PIN',
    'Amount confirmed · paying via rail',
    'Receipt SMS with ref sent',
  ];

  @override
  void initState() {
    super.initState();
    _pickDefaultRail();
    _advance();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> get _railOptions {
    final ws = HiveService.getActiveWorkspace();
    final rails = ws?['rails'];
    final options = <Map<String, dynamic>>[];
    if (rails is Map) {
      if (rails['loop'] == true) {
        options.add(
            {'label': 'LOOP Request-to-Pay', 'icon': Icons.swap_vert_rounded});
      }
      if (rails['till'] == true) {
        options.add({
          'label': 'M-PESA Till ${ws?['till_number'] ?? ''}',
          'icon': Icons.storefront_rounded,
        });
      }
      if (rails['paybill'] == true) {
        options.add({
          'label': 'Paybill ${ws?['paybill_number'] ?? ''}',
          'icon': Icons.receipt_long_rounded,
        });
      }
      if (rails['bank'] == true) {
        options.add({
          'label': 'Bank ${ws?['account_number'] ?? ''}',
          'icon': Icons.account_balance_rounded,
        });
      }
    }
    if (options.isEmpty) {
      options.add(
          {'label': 'LOOP Request-to-Pay', 'icon': Icons.swap_vert_rounded});
    }
    return options;
  }

  void _pickDefaultRail() {
    final method = widget.campaign['payment_method'];
    if (method is Map && method['rail'] == 'loop')
      _rail = 'LOOP Request-to-Pay';
    if (method is Map && method['rail'] == 'till') {
      final ws = HiveService.getActiveWorkspace();
      _rail = 'M-PESA Till ${ws?['till_number'] ?? ''}';
    }
    if (method is Map && method['rail'] == 'paybill') {
      final ws = HiveService.getActiveWorkspace();
      _rail = 'Paybill ${ws?['paybill_number'] ?? ''}';
    }
  }

  void _advance() {
    if (_step < _steps.length - 1) {
      _timer = Timer(const Duration(milliseconds: 1700), () {
        if (mounted) setState(() => _step++);
        _advance();
      });
    } else {
      _timer = Timer(const Duration(milliseconds: 1400), _recordPayment);
    }
  }

  Future<void> _recordPayment() async {
    setState(() => _loading = true);
    final amount = (widget.campaign['amount'] as num).toDouble();
    final payment = ContributionService.recordPayment(
      widget.campaign,
      widget.member.id,
      widget.member.name,
      widget.member.memberCode,
      widget.member.phone,
      amount,
      _rail,
      verified: false,
    );
    if (mounted) {
      setState(() {
        _loading = false;
        _recorded = true;
        _receipt = payment;
      });
    }
  }

  void _openReceipt() {
    final p = _receipt!;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => SuccessScreen(
          memberName: widget.member.name,
          memberPhone: widget.member.phone,
          amount: (p['paid'] as num).toDouble(),
          receiptUrl: 'https://tverify.co.ke/r/${p['ref']}',
          pin: p['pin'] ?? '',
          queued: false,
          smsSent: true,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _chooseRail(String label) {
    setState(() => _rail = label);
  }

  String _deadlineLabel() {
    final d = DateTime.tryParse(widget.campaign['deadline']?.toString() ?? '');
    if (d == null) return 'soon';
    return '${d.day}/${d.month}/${d.year}';
  }

  /// The LOOP product powering the currently selected payment rail.
  String _railApi() {
    final r = _rail;
    if (r.contains('LOOP')) return 'LOOP Prompt';
    if (r.contains('Paybill')) return 'Pay to Paybill';
    if (r.contains('Till')) return 'Pay to M-Pesa Till';
    if (r.contains('Bank')) return 'Send Money · M-Pesa';
    return 'Mpesa Prompt';
  }

  Widget _apiChip() {
    final api = _railApi();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, size: 14, color: AppColors.accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text('LOOP API IN ACTION · $api',
                style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orgName =
        HiveService.getActiveWorkspace()?['name']?.toString() ?? 'your group';
    final amount = (widget.campaign['amount'] as num).toDouble();

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text('Member Payment Demo',
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17)),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: AppColors.text,
          leading: _loading
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _PhoneMockup(
                        step: _step,
                        recorded: _recorded,
                        campaign: widget.campaign,
                        member: widget.member,
                        orgName: orgName,
                        rail: _rail,
                        rails: _railOptions,
                        onRail: _chooseRail,
                        deadlineLabel: _deadlineLabel(),
                        receipt: _receipt,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _apiChip(),
                            const SizedBox(height: 10),
                            ...List.generate(_steps.length, (i) {
                            final done =
                                _recorded ? i < _steps.length : i < _step;
                            final active = !_recorded && i == _step;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  Icon(
                                    done
                                        ? Icons.check_circle_rounded
                                        : active
                                            ? Icons.radio_button_checked_rounded
                                            : Icons.radio_button_off_rounded,
                                    size: 18,
                                    color: done
                                        ? AppColors.primary
                                        : active
                                            ? const Color(0xFFC9A227)
                                            : const Color(0xFFCBD5E1),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _steps[i],
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        fontWeight: active
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: done || active
                                            ? AppColors.text
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.accent.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_rounded,
                                color: AppColors.accent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _recorded
                                    ? 'Payment recorded with a receipt ref. It now sits in your Payments Ledger — tap to verify, then export the PDF.'
                                    : 'This is how every member sees it: SMS → link → PIN → pays via ${_rail}. No app to install, no paperwork.',
                                style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const LoopValueStrip(title: 'HOW THIS PAYMENT USES LOOP'),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_recorded)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _openReceipt,
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: Text('VIEW RECEIPT',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                )
              else if (_loading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneMockup extends StatelessWidget {
  final int step;
  final bool recorded;
  final Map campaign;
  final Member member;
  final String orgName;
  final String rail;
  final List<Map<String, dynamic>> rails;
  final ValueChanged<String> onRail;
  final String deadlineLabel;
  final Map<String, dynamic>? receipt;

  const _PhoneMockup({
    required this.step,
    required this.recorded,
    required this.campaign,
    required this.member,
    required this.orgName,
    required this.rail,
    required this.rails,
    required this.onRail,
    required this.deadlineLabel,
    required this.receipt,
  });

  String _fmt(double v) {
    return v
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    final amount = (campaign['amount'] as num).toDouble();

    return Container(
      width: 250,
      height: 430,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.grey.shade300, width: 3),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 12)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Container(
                color: const Color(0xFF0F172A),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Text('19:04',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const Spacer(),
                    const Icon(Icons.signal_cellular_alt,
                        size: 12, color: Colors.white),
                    const SizedBox(width: 3),
                    const Icon(Icons.wifi, size: 12, color: Colors.white),
                    const SizedBox(width: 3),
                    const Icon(Icons.battery_full,
                        size: 12, color: Colors.white),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: recorded
                      ? const Color(0xFFF0FDF4)
                      : step >= 2
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFAF9F6),
                  padding: const EdgeInsets.all(14),
                  child: _body(amount),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(double amount) {
    if (recorded) {
      final ref = receipt?['ref']?.toString() ?? 'TV-XXXXXX';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          const Center(
            child: Icon(Icons.check_circle_rounded,
                color: AppColors.accent, size: 44),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text('Payment received',
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF9A3412))),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text('Ksh ${_fmt(amount)} · via ${rail.split(' ').first}',
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.accent)),
          ),
          const SizedBox(height: 16),
          _receiptRow('Ref', ref),
          _receiptRow('Member', member.name),
          _receiptRow('To', orgName),
          _receiptRow('Status', 'SMS receipt sent ✓'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDD5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.sms_rounded,
                    size: 13, color: AppColors.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                      'SMS: TapVerify — ${member.name.split(' ').first} paid Ksh ${_fmt(amount)} to $orgName. Ref $ref.',
                      style: GoogleFonts.inter(
                          fontSize: 8.5, color: const Color(0xFF9A3412))),
                ),
              ],
            ),
          ),
        ],
      );
    }

    switch (step) {
      case 0:
        return _smsStep(amount);
      case 1:
        return _linkStep(amount);
      case 2:
        return _pinStep(amount);
      default:
        return _confirmStep(amount);
    }
  }

  Widget _smsStep(double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.sms_rounded, size: 16, color: Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text('Messages',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B))),
            const Spacer(),
            const Icon(Icons.more_vert, size: 14, color: Color(0xFF64748B)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded,
                      size: 13, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('TapVerify',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'REMINDER: $orgName — ${campaign['title']}. Ksh ${_fmt(amount)} due by $deadlineLabel. Tap to pay → tverify.co.ke/pay/${(member.memberCode ?? 'TV').substring(0, (member.memberCode?.length ?? 4) < 4 ? 4 : 4).toUpperCase()}',
                style: GoogleFonts.inter(
                    fontSize: 10.5,
                    height: 1.45,
                    color: const Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('PAY NOW',
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 12, color: Colors.white),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text('now',
                      style: GoogleFonts.inter(
                          fontSize: 9, color: const Color(0xFF94A3B8))),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        Text('TAPVERIFY · SMS reminders & receipts',
            style:
                GoogleFonts.inter(fontSize: 8, color: const Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _linkStep(double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(AppAssets.logoFull, fit: BoxFit.contain),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TapVerify Payment',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    Text(orgName,
                        style: GoogleFonts.inter(
                            fontSize: 9.5, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text('Amount due',
            style: GoogleFonts.inter(
                fontSize: 9.5, color: const Color(0xFF64748B))),
        Text('Ksh ${_fmt(amount)}',
            style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A))),
        const SizedBox(height: 4),
        Text('${campaign['title']} · due by $deadlineLabel',
            style:
                GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
        const SizedBox(height: 12),
        Text('Pay with',
            style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: rails.map((r) {
            final selected = r['label'] == rail;
            return GestureDetector(
              onTap: () => onRail(r['label'] as String),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        selected ? AppColors.primary : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(r['icon'] as IconData,
                        size: 12,
                        color:
                            selected ? Colors.white : const Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(r['label'] as String,
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF334155))),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const Spacer(),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('PAY NOW',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ),
        const Spacer(),
        Text('Secure payment link · tverify.co.ke/pay/',
            style:
                GoogleFonts.inter(fontSize: 8, color: const Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _pinStep(double amount) {
    return Column(
      children: [
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF00A651),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text('M-PESA',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5)),
        ),
        const SizedBox(height: 12),
        Text('Enter PIN',
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A))),
        const SizedBox(height: 2),
        Text('Pay Ksh ${_fmt(amount)} to ${orgName.split(' ').first}',
            style: GoogleFonts.inter(
                fontSize: 9.5, color: const Color(0xFF64748B))),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    i == 0 ? const Color(0xFF00A651) : const Color(0xFFCBD5E1),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Text('${rail.split(' ').first} · Ksh ${_fmt(amount)}',
            style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B))),
        const Spacer(),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF00A651),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('OK',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('CANCEL',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B))),
        ),
        const Spacer(),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0), width: 3),
          ),
        ),
      ],
    );
  }

  Widget _confirmStep(double amount) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(
              strokeWidth: 3, color: AppColors.primary),
        ),
        const SizedBox(height: 14),
        Text('Confirming via ${rail.split(' ').first}…',
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155))),
        const SizedBox(height: 6),
        Text('Ksh ${_fmt(amount)} to $orgName',
            style: GoogleFonts.inter(
                fontSize: 9.5, color: const Color(0xFF64748B))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEDD5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sms_rounded, size: 12, color: AppColors.accent),
              const SizedBox(width: 4),
              Text('SMS receipt will be sent instantly',
                  style: GoogleFonts.inter(
                      fontSize: 8.5,
                      color: const Color(0xFF9A3412),
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }
}
