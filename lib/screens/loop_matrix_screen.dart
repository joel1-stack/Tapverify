import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../models/member.dart';
import '../services/hive_service.dart';
import '../services/contribution_service.dart';
import 'confirm_screen.dart';
import 'create_contribution_screen.dart';
import 'payments_ledger_screen.dart';
import 'member_payment_demo_screen.dart';
import 'loop_demo_screen.dart';
import 'disburse_screen.dart';

/// The LOOP Matrix — a judge-facing map of the 8 selected LOOP APIs.
///
/// Each of the 8 products is a card with: the money story it powers, the
/// request/response shape, whether it's selectable in this workspace, and a
/// launch action into the real TapVerify screen that uses it. Built so a judge
/// can scan "collect → reconcile → disburse → future rail" and see that
/// TapVerify is collection infrastructure, not a payment app.
class LoopMatrixScreen extends StatefulWidget {
  const LoopMatrixScreen({super.key});

  @override
  State<LoopMatrixScreen> createState() => _LoopMatrixScreenState();
}

class _LoopMatrixScreenState extends State<LoopMatrixScreen> {
  final List<int> _expanded = [];

  Map? _ws;

  @override
  void initState() {
    super.initState();
    _ws = HiveService.getActiveWorkspace();
  }

  List<_ApiCard> get _apis => [
        _ApiCard(
          id: 'Mpesa Prompt',
          api: 'mpesa/prompt',
          icon: Icons.notifications_active_rounded,
          color: const Color(0xFF059669),
          status: 'HERO · LIVE',
          story:
              'Treasurer taps a contribution → TapVerify fires an STK Push to every member. Their phone buzzes with the M-Pesa popup — no till number to memorize, no screenshot to send. Money moves, proof is born.',
          flow: 'Create contribution → STK Push to member → enter PIN → IPN → SMS + green receipt',
          request:
              'POST /sandbox/v1/mpesa/prompt\n{\n  "phoneNumber": "254712345678",\n  "amount": 500,\n  "currency": "KES",\n  "reference": "TV-20260813-001"\n}',
          vision:
              'This is not a payment — it is a collection campaign. 200 members, one tap, 200 prompts.',
          launchLabel: 'Play the STK demo',
          launch: (ctx, ws) => _openLoopDemo(ctx),
        ),
        _ApiCard(
          id: 'Pay to M-Pesa Till',
          api: 'payments/till',
          icon: Icons.storefront_rounded,
          color: const Color(0xFFF97316),
          status: 'LIVED IN APP',
          story:
              'The chama already has a Till. We don\'t change it — we embed it. Members pay the same Till they always have, and every payment is auto-matched to the member with a receipt.',
          flow: 'Member picks "Pay via Till" → TapVerify POST /payments/till → money lands in the Till → IPN auto-matches → SMS',
          request:
              'POST /sandbox/v1/payments/till\n{\n  "tillNumber": "${_ws?['till_number'] ?? '9415678'}",\n  "phoneNumber": "254712345678",\n  "amount": 500,\n  "currency": "KES"\n}',
          vision:
              'The Till is the door; TapVerify is the bookkeeper. Disrupting nobody, digitizing everything.',
          launchLabel: 'Member payment flow',
          launch: (ctx, ws) => _openMemberDemo(ctx),
        ),
        _ApiCard(
          id: 'Pay To Paybill',
          api: 'payments/paybill',
          icon: Icons.account_balance_wallet_rounded,
          color: const Color(0xFF2563EB),
          status: 'SACCO / CHURCH',
          story:
              'SACCOs and churches use Paybills with per-member account numbers. TapVerify pre-fills the Paybill and account — members just pay, and the IPN auto-matches to the right person.',
          flow: 'Treasurer sets Paybill + Acc in org → member pays pre-filled → IPN matched by account → SMS',
          request:
              'POST /sandbox/v1/payments/paybill\n{\n  "paybillNumber": "${_ws?['paybill_number'] ?? '890123'}",\n  "accountNumber": "JOHN-047",\n  "amount": 10000,\n  "currency": "KES"\n}',
          vision:
              'Regulated finance needs audit trails — not WhatsApp screenshots. Paybill gives SACCOs official reconciled records.',
          launchLabel: 'Member payment flow',
          launch: (ctx, ws) => _openMemberDemo(ctx),
        ),
        _ApiCard(
          id: 'Transaction Inquiry',
          api: 'transactions/inquiry',
          icon: Icons.fact_check_rounded,
          color: const Color(0xFF7C3AED),
          status: 'STATUS CHECK',
          story:
              '"Did this payment complete?" The treasurer taps Check Status; TapVerify asks Loop what happened to the reference; the app shows green SUCCESS or red FAILED. No calling 200 people.',
          flow: 'Open a contribution → Check Status → Loop replies SUCCESS / FAILED / PENDING → dashboard refreshes',
          request:
              'GET /sandbox/v1/transactions/inquiry?reference=TV-20260813-001',
          vision:
              'The reconciliation layer. One tap instead of Sunday-evening phone calls. 10 hours saved per treasurer per week.',
          launchLabel: 'See reconciled ledger',
          launch: (ctx, ws) => _openLedger(ctx),
        ),
        _ApiCard(
          id: 'Transaction History',
          api: 'transactions/history',
          icon: Icons.insert_drive_file_rounded,
          color: const Color(0xFF059669),
          status: 'PDF + LEDGER',
          story:
              'End of month, the chairman wants proof. TapVerify pulls the Loop transaction log and prints a PDF: who paid, every M-Pesa reference, every timestamp. The notebook is dead.',
          flow: 'This month\'s report → GET /transactions/history → aggregate by member/channel → PDF for the chairman',
          request:
              'GET /sandbox/v1/transactions/history?fromDate=2026-08-01&toDate=2026-08-31&limit=100',
          vision:
              'This is not a report — it is trust made visible. Dispute over, proof wins.',
          launchLabel: 'Export register / PDF',
          launch: (ctx, ws) => _openLedger(ctx),
        ),
        _ApiCard(
          id: 'Send Money - M-Pesa',
          api: 'send-money/mpesa',
          icon: Icons.send_rounded,
          color: const Color(0xFFDC2626),
          status: 'DISBURSE',
          story:
              'Funeral welfare pool of Ksh 400,000 — the family needs it tomorrow. The treasurer disbursees Ksh 350,000 to the recipient\'s M-Pesa in 30 seconds. Everything logged.',
          flow: 'Send Money → recipient + amount + reason → POST /send-money/mpesa → money lands → SMS to recipient',
          request:
              'POST /sandbox/v1/send-money/mpesa\n{\n  "phoneNumber": "254798765432",\n  "amount": 350000,\n  "currency": "KES",\n  "reason": "Funeral support - Mama Jane"\n}',
          vision:
              'Collection is half the story. Disbursement is the other half. Chamas don\'t just save — they support, they build.',
          launchLabel: 'Send disbursement',
          launch: (ctx, ws) => _openDisburse(ctx),
        ),
        _ApiCard(
          id: 'LOOP Prompt',
          api: 'loop/prompt',
          icon: Icons.swap_vert_rounded,
          color: const Color(0xFFC9A227),
          status: 'FUTURE RAIL',
          story:
              'Tomorrow the chama opens a Loop wallet. Members pay Loop-to-Loop in 2 seconds with zero fees. TapVerify records it the same way — because we are rail-agnostic.',
          flow: 'Member taps "Pay via Loop" → POST /loop/prompt → Loop app confirm → instant settlement → IPN',
          request:
              'POST /sandbox/v1/loop/prompt\n{\n  "loopId": "LOOP-USER-12345",\n  "amount": 500,\n  "currency": "KES"\n}',
          vision:
              'M-Pesa takes 1.5% per transaction — Ksh 4.5 billion a year. Loop internal is free. TapVerify is the bridge that brings chamas there.',
          launchLabel: 'Play LOOP demo',
          launch: (ctx, ws) => _openLoopDemo(ctx),
        ),
        _ApiCard(
          id: 'Send Money - Loop',
          api: 'send-money/loop',
          icon: Icons.account_balance_rounded,
          color: const Color(0xFF0F766E),
          status: 'INTERNAL',
          story:
              'The chairman transfers Ksh 50,000 to the youth group\'s Loop ID — instant, free, both parties get SMS confirmation. Chamas become a financial network.',
          flow: 'Admin → Transfer Between Groups → dest Loop ID + amount → POST /send-money/loop → instant → both SMS',
          request:
              'POST /sandbox/v1/send-money/loop\n{\n  "destinationLoopId": "LOOP-ORG-67890",\n  "amount": 50000,\n  "currency": "KES"\n}',
          vision:
              'This is where TapVerify stops being a tool and becomes infrastructure: chamas, churches, schools — all verified, all visible.',
          launchLabel: 'Send disbursement',
          launch: (ctx, ws) => _openDisburse(ctx),
        ),
      ];

  void _openMemberDemo(BuildContext ctx) {
    final campaigns = ContributionService.campaigns();
    if (campaigns.isEmpty) {
      _snack(ctx, 'Create a contribution first, then play the demo');
      return;
    }
    final wsId = HiveService.activeWorkspaceId ?? '';
    for (final c in campaigns.reversed) {
      if (c['workspace_id'] != wsId) continue;
      final members = HiveService.getMembersForWorkspace(wsId);
      final payments = List<Map<String, dynamic>>.from(c['payments'] ?? []);
      final amount = (c['amount'] as num? ?? 0).toDouble();
      Member? unpaid;
      for (final m in members) {
        final paid = payments
            .where((p) => p['member_id'] == m.id)
            .fold<double>(0, (s, p) => s + (p['paid'] as num));
        if (paid < amount) {
          unpaid = m;
          break;
        }
      }
      final member = unpaid ?? (members.isNotEmpty ? members.first : null);
      if (member == null) continue;
      Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) =>
              MemberPaymentDemoScreen(campaign: c, member: member),
        ),
      );
      return;
    }
    _snack(ctx, 'No members in this org yet');
  }

  void _openLoopDemo(BuildContext ctx) {
    final campaigns = ContributionService.campaigns();
    if (campaigns.isEmpty) {
      _snack(ctx, 'Create a contribution first, then run the demo');
      return;
    }
    final wsId = HiveService.activeWorkspaceId ?? '';
    final members = HiveService.getMembersForWorkspace(wsId);
    Member? member;
    for (final c in campaigns.reversed) {
      if (c['workspace_id'] != wsId) continue;
      final payments = List<Map<String, dynamic>>.from(c['payments'] ?? []);
      final amount = (c['amount'] as num? ?? 0).toDouble();
      for (final m in members) {
        final paid = payments
            .where((p) => p['member_id'] == m.id)
            .fold<double>(0, (s, p) => s + (p['paid'] as num));
        if (paid < amount) {
          member = m;
          break;
        }
      }
      if (member != null) break;
    }
    member ??= (members.isNotEmpty ? members.first : null);
    if (member == null) {
      _snack(ctx, 'No members to run the demo against');
      return;
    }
    final amount = campaigns.cast<Map>().lastWhere(
              (c) => c['workspace_id'] == wsId,
              orElse: () => <String, dynamic>{},
            )['amount'] as num? ??
        500;
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => LoopDemoScreen(
          member: member!,
          amount: amount.toDouble(),
          eventType: 'payment_loop',
        ),
      ),
    );
  }

  void _openLedger(BuildContext ctx) {
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => const PaymentsLedgerScreen()),
    );
  }

  void _openDisburse(BuildContext ctx) {
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => const DisburseScreen()),
    );
  }

  void _snack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wsName = _ws?['name']?.toString() ?? 'your organization';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text('LOOP Matrix',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.developer_board_rounded,
                    color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('The 8 APIs powering $wsName',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                        'Collect · Reconcile · Disburse · Future rail. Every card below maps a LOOP product to the screen inside TapVerify that already uses it.',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _apis.length; i++) _card(i),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _card(int i) {
    final api = _apis[i];
    final open = _expanded.contains(i);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() {
            if (open) {
              _expanded.remove(i);
            } else {
              _expanded.add(i);
            }
          }),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: api.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(api.icon, color: api.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${i + 1}. ${api.id}',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text)),
                          const SizedBox(height: 2),
                          Text(api.api,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.muted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: api.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(api.status,
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: api.color)),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      open
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppColors.muted,
                    ),
                  ],
                ),
                if (open) ...[
                  const SizedBox(height: 12),
                  _story('THE STORY', api.story, api.color),
                  const SizedBox(height: 10),
                  _flow(api.flow),
                  const SizedBox(height: 10),
                  _request(api.request),
                  const SizedBox(height: 10),
                  _story('THE VISION', api.vision, const Color(0xFF0F766E)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: api.color,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(api.icon, size: 18),
                      label: Text(api.launchLabel,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      onPressed: () => api.launch(context, _ws),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _story(String label, String text, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: color)),
        const SizedBox(height: 4),
        Text(text,
            style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.text)),
      ],
    );
  }

  Widget _flow(String flow) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.route_rounded, size: 15, color: AppColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(flow,
                style:
                    GoogleFonts.inter(fontSize: 11.5, color: AppColors.text)),
          ),
        ],
      ),
    );
  }

  Widget _request(String request) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(request,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, color: Color(0xFFA7F3D0))),
    );
  }
}

class _ApiCard {
  final String id;
  final String api;
  final IconData icon;
  final Color color;
  final String status;
  final String story;
  final String flow;
  final String request;
  final String vision;
  final String launchLabel;
  final void Function(BuildContext ctx, Map? ws) launch;

  const _ApiCard({
    required this.id,
    required this.api,
    required this.icon,
    required this.color,
    required this.status,
    required this.story,
    required this.flow,
    required this.request,
    required this.vision,
    required this.launchLabel,
    required this.launch,
  });
}