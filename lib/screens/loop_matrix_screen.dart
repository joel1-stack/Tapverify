import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../services/hive_service.dart';
import 'member_list_screen.dart';
import 'payments_ledger_screen.dart';
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
              'Treasurer taps a contribution → TapVerify fires the LOOP gateway M-Pesa Prompt to every member. Their phone buzzes with the M-Pesa popup — no till number to memorize, no screenshot to send. Money moves, proof is born.',
          flow: 'Create contribution → POST /gateway/mpesa-prompt/2.0 → STK Push to member → PIN → IPN → SMS + green receipt',
          request:
              'POST {base}/gateway/mpesa-prompt/2.0/services/process-request\n{\n  "serviceCode": "MRCHNT_SENDMONEY",\n  "requestParameters": {\n    "recipientMobileNo": "254712345678",\n    "amount": "500.00",\n    "purposeOfPayment": "TV-20260813-001",\n    "signature": "hmac-sha256(till|ts|nonce)"\n  }\n}',
          vision:
              'This is not a payment — it is a collection campaign. 200 members, one tap, 200 prompts.',
          launchLabel: 'Start a collection',
          launch: (ctx, ws) => _openCollect(ctx),
        ),
        _ApiCard(
          id: 'Pay to M-Pesa Till',
          api: 'payments/till',
          icon: Icons.storefront_rounded,
          color: const Color(0xFFF97316),
          status: 'LIVED IN APP',
          story:
              'The chama already has a Till. We don\'t change it — we embed it. Members pay the same Till they always have, and every payment is auto-matched to the member with a receipt.',
          flow: 'Member picks "Pay via Till" → POST /gateway/pay-to-paybill/1.0 → money lands in the Till → IPN auto-matches → SMS',
          request:
              'POST {base}/gateway/pay-to-paybill/1.0/services/process-request\n{\n  "serviceCode": "MRCHNT_SENDMONEY",\n  "requestParameters": {\n    "merchantTill": "${_ws?['till_number'] ?? '9415678'}",\n    "recipientMobileNo": "254712345678",\n    "amount": "500.00",\n    "signature": "hmac-sha256(till|ts|nonce)"\n  }\n}',
          vision:
              'The Till is the door; TapVerify is the bookkeeper. Disrupting nobody, digitizing everything.',
          launchLabel: 'Start a collection',
          launch: (ctx, ws) => _openCollect(ctx),
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
              'POST {base}/gateway/pay-to-paybill/1.0/services/process-request\n{\n  "serviceCode": "MRCHNT_SENDMONEY",\n  "requestParameters": {\n    "paybillNumber": "${_ws?['paybill_number'] ?? '890123'}",\n    "accountNumber": "JOHN-047",\n    "amount": "10000.00",\n    "signature": "hmac-sha256(till|ts|nonce)"\n  }\n}',
          vision:
              'Regulated finance needs audit trails — not WhatsApp screenshots. Paybill gives SACCOs official reconciled records.',
          launchLabel: 'Start a collection',
          launch: (ctx, ws) => _openCollect(ctx),
        ),
        _ApiCard(
          id: 'Transaction Inquiry',
          api: 'transactions/inquiry',
          icon: Icons.fact_check_rounded,
          color: const Color(0xFF7C3AED),
          status: 'STATUS CHECK',
          story:
              '"Did this payment complete?" The treasurer taps Check Status; TapVerify shows the synchronized loop response — green SUCCESS or red FAILED. No calling 200 people.',
          flow: 'Open a contribution → Check Status → sync transaction status COMPLETED / FAILED → dashboard refreshes',
          request:
              'GET {base}/gateway/send-money-mpesa/1.0\n→ statusCode 200 · serviceTransactionStatus COMPLETED · transferStatus "S"',
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
              'End of month, the chairman wants proof. TapVerify pulls the reconciled loop transaction log and prints a PDF: who paid, every transfer order ID, every timestamp. The notebook is dead.',
          flow: 'This month\'s report → aggregated ledger of sync loop responses → PDF for the chairman',
          request:
              'Aggregate ledger: transferStatus "S" · transferOrderId TAM… per member → PDF register',
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
              'Funeral welfare pool of Ksh 400,000 — the family needs it tomorrow. The treasurer disburses Ksh 350,000 to the recipient\'s M-Pesa in 30 seconds via Send Money. Everything logged.',
          flow: 'Send Money → recipient + amount + reason → POST /gateway/send-money-mpesa/1.0 → money lands → SMS to recipient',
          request:
              'POST {base}/gateway/send-money-mpesa/1.0/services/process-request\n{\n  "serviceCode": "MRCHNT_SENDMONEY",\n  "requestParameters": {\n    "recipientMobileNo": "254798765432",\n    "amount": "350000.00",\n    "purposeOfPayment": "Funeral support - Mama Jane",\n    "signature": "hmac-sha256(till|ts|nonce)"\n  }\n}',
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
          flow: 'Member taps "Pay via Loop" → POST /gateway/mpesa-prompt/2.0 (channel LOOP) → Loop app confirm → instant settlement → IPN',
          request:
              'POST {base}/gateway/mpesa-prompt/2.0/services/process-request\n{\n  "serviceCode": "MRCHNT_SENDMONEY",\n  "requestParameters": {\n    "channel": "LOOP",\n    "recipientMobileNo": "254712345678",\n    "amount": "500.00",\n    "signature": "hmac-sha256(till|ts|nonce)"\n  }\n}',
          vision:
              'M-Pesa takes 1.5% per transaction — Ksh 4.5 billion a year. Loop internal is free. TapVerify is the bridge that brings chamas there.',
          launchLabel: 'Start a collection',
          launch: (ctx, ws) => _openCollect(ctx),
        ),
        _ApiCard(
          id: 'Send Money - Loop',
          api: 'send-money/loop',
          icon: Icons.account_balance_rounded,
          color: const Color(0xFF0F766E),
          status: 'INTERNAL',
          story:
              'The chairman transfers Ksh 50,000 to the youth group — instant, free, both parties get SMS confirmation. Chamas become a financial network.',
          flow: 'Admin → Transfer Between Groups → dest Loop ID + amount → send-money rail → instant → both SMS',
          request:
              'POST {base}/gateway/send-money-mpesa/1.0/services/process-request\n{\n  "serviceCode": "MRCHNT_SENDMONEY",\n  "requestParameters": {\n    "recipientMobileNo": "254700000000",\n    "amount": "50000.00",\n    "purposeOfPayment": "Youth group transfer",\n    "signature": "hmac-sha256(till|ts|nonce)"\n  }\n}',
          vision:
              'This is where TapVerify stops being a tool and becomes infrastructure: chamas, churches, schools — all verified, all visible.',
          launchLabel: 'Send disbursement',
          launch: (ctx, ws) => _openDisburse(ctx),
        ),
      ];

  void _openCollect(BuildContext ctx) {
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => const MemberListScreen()),
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