import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../models/member.dart';
import '../services/hive_service.dart';
import '../services/contribution_service.dart';
import '../services/api_service.dart';
import '../services/payment_report_service.dart';

/// Single contribution campaign — the treasurer's working view.
///
/// Header with target/progress, deadline, per-member payment status
/// (PAID / PARTIAL / NOT PAID), a reminder send action, an "Export N paid
/// members as PDF" button (share or print via [PaymentReportService]) and the
/// receipts recorded for this campaign.
class CampaignDetailScreen extends StatefulWidget {
  final Map campaign;
  const CampaignDetailScreen({super.key, required this.campaign});

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  Map get campaign => widget.campaign;
  List<Member> get members =>
      HiveService.getMembersForWorkspace(campaign['workspace_id'] ?? '');

  String _fmt(dynamic value) {
    final n = value is num ? value : double.tryParse(value.toString()) ?? 0;
    return n.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  Map<String, dynamic> _payFor(Member m) {
    final payments =
        List<Map<String, dynamic>>.from(campaign['payments'] ?? []);
    final found = payments.where((p) => p['member_id'] == m.id).toList();
    if (found.isEmpty) return {'paid': 0.0};
    final total = found.fold(0.0, (s, p) => s + (p['paid'] as num));
    return {'paid': total, 'method': found.last['method']};
  }

  void _recordPayment(Member m, double amount, String method) {
    ContributionService.recordPayment(
      campaign,
      m.id,
      m.name,
      m.memberCode,
      m.phone,
      amount,
      method,
    );
    setState(() {});
  }

  void _showPaymentSheet(Member m) {
    final amount = (campaign['amount'] as num).toDouble();
    final balance = amount - (_payFor(m)['paid'] as double);
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.name,
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text)),
              const SizedBox(height: 4),
              Text(
                'Amount due: Ksh ${_fmt(amount)} · Paid: Ksh ${_fmt(_payFor(m)['paid'])} · Balance: Ksh ${_fmt(balance)}',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount paid now (Ksh)',
                  labelStyle: GoogleFonts.inter(color: AppColors.muted),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _miniChip(ctx, m, controller, 'Full (${_fmt(amount)})',
                      amount, 'M-PESA Till'),
                  _miniChip(ctx, m, controller, 'Half (${_fmt(amount / 2)})',
                      amount / 2, 'M-PESA Till'),
                  _miniChip(ctx, m, controller, 'Loop',
                      balance > 0 ? balance : amount, 'LOOP (NCBA)'),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    final v = double.tryParse(controller.text);
                    if (v == null || v <= 0) return;
                    _recordPayment(m, v, 'M-PESA Till');
                    Navigator.pop(ctx);
                  },
                  child: Text('RECORD PAYMENT',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniChip(BuildContext ctx, Member m, TextEditingController c,
      String label, double v, String method) {
    return Material(
      color: AppColors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          _recordPayment(m, v, method);
          Navigator.pop(ctx);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
        ),
      ),
    );
  }

  Future<void> _sync() async {
    await ApiService.syncPending();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Synced — SMS receipts sent to paid members',
              style: GoogleFonts.inter()),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _exportPdf() async {
    final payments = ContributionService.flattenPayments([campaign]);
    final ws = HiveService.getActiveWorkspace();
    final orgName = ws?['name']?.toString() ?? 'Organization';
    final title = 'PAID MEMBERS — ${campaign['title'] ?? 'Contribution'}';
    final collected =
        payments.fold<double>(0, (s, p) => s + ((p['paid'] as num?) ?? 0));
    final share = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Export paid members',
                  style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text)),
              const SizedBox(height: 4),
              Text('${payments.length} payments · Ksh ${_fmt(collected)}',
                  style:
                      GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: Text('SHARE PDF',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: BorderSide(
                        color: const Color(0xFF2563EB).withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx, false),
                  icon: const Icon(Icons.print_rounded, size: 18),
                  label: Text('PRINT PDF',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (share == null || !mounted) return;
    try {
      if (share) {
        await PaymentReportService.share(
          orgName: orgName,
          reportTitle: title,
          payments: payments,
        );
      } else {
        await PaymentReportService.printPdf(
          orgName: orgName,
          reportTitle: title,
          payments: payments,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e', style: GoogleFonts.inter()),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _sendReminders(int count) {
    final unpaid =
        members.where((m) => (_payFor(m)['paid'] as double) <= 0).toList();
    final names = unpaid.take(3).map((m) => m.name.split(' ').first).join(', ');
    final more = unpaid.length > 3 ? ' +${unpaid.length - 3} more' : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Reminder with payment link sent to ${names.isEmpty ? count : names}$more',
            style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = (campaign['amount'] as num).toDouble();
    final payments =
        List<Map<String, dynamic>>.from(campaign['payments'] ?? []);
    final collected = payments.fold(0.0, (s, p) => s + (p['paid'] as num));
    final fullPaid =
        members.where((m) => (_payFor(m)['paid'] as double) >= amount).length;
    final ws = HiveService.getActiveWorkspace();
    final cover = OrgRules.categoryImageFor(
        campaign['contrib_type']?.toString() ?? 'Monthly');
    final unpaid =
        members.where((m) => (_payFor(m)['paid'] as double) <= 0).length;
    final partialPaid = members.where((m) {
      final paid = _payFor(m)['paid'] as double;
      return paid > 0 && paid < amount;
    }).length;
    final expected = campaign['target_amount'] != null
        ? (campaign['target_amount'] as num).toDouble()
        : amount * members.length;
    final target = expected;
    final pct = target > 0 ? ((collected / target) * 100).clamp(0, 100) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text(campaign['title'] ?? 'Contribution',
            style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.text)),
        actions: [
          IconButton(
            onPressed: _sync,
            icon: const Icon(Icons.cloud_upload_rounded,
                color: AppColors.primary),
            tooltip: 'Sync & send receipts',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              cover,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 150,
                color: AppColors.primary.withOpacity(0.15),
                child: const Center(
                    child: Icon(Icons.campaign_rounded,
                        color: AppColors.primary, size: 48)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ksh ${_fmt(collected)} collected of Ksh ${_fmt(expected)}',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.text),
                      ),
                    ),
                    Text('${pct.toStringAsFixed(0)}%',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stat('$fullPaid', 'PAID'),
                    _stat('$partialPaid', 'PARTIAL'),
                    _stat('$unpaid', 'UNPAID'),
                    _stat('${members.length}', 'TOTAL'),
                  ],
                ),
                const SizedBox(height: 12),
                if (unpaid > 0)
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => _sendReminders(unpaid),
                      icon: const Icon(Icons.sms_rounded, size: 18),
                      label: Text('Send reminder to $unpaid unpaid',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.primary)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                            color: AppColors.primary.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                if (payments.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => _exportPdf(),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: Text(
                          'Export ${fullPaid} paid members as PDF · Ksh ${_fmt(collected)}',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: const Color(0xFF2563EB))),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: BorderSide(
                            color: const Color(0xFF2563EB).withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppColors.accent.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sms_rounded,
                          color: AppColors.accent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          campaign['message'] ?? '',
                          style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text('Deadline: ${_deadlineLabel()}',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600)),
                    ),
                    Text(
                      '${campaign['contrib_type'] ?? 'Regular'} · ${(campaign['frequency'] ?? '').toString().replaceAll('_', ' ')}',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('By ${ws?['name'] ?? 'Treasurer'}',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.muted,
                        fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('MEMBERS — WHO PAID',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                  letterSpacing: 0.6)),
          const SizedBox(height: 8),
          ...members.map((m) {
            final info = _payFor(m);
            final paid = info['paid'] as double;
            final method = info['method']?.toString() ?? '';
            final full = paid >= amount;
            final partial = paid > 0 && !full;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: full
                      ? AppColors.primary.withOpacity(0.15)
                      : partial
                          ? AppColors.warning.withOpacity(0.15)
                          : Colors.grey.shade100,
                  child: Text(
                    m.name[0].toUpperCase(),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: full
                          ? AppColors.primary
                          : partial
                              ? AppColors.warning
                              : AppColors.muted,
                    ),
                  ),
                ),
                title: Text(m.name,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(
                  '$full ${partial ? '· Partial' : ''} ${method.isNotEmpty ? '· $method' : ''}',
                  style:
                      GoogleFonts.inter(fontSize: 11.5, color: AppColors.muted),
                ),
                trailing: paid > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: full
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Ksh ${_fmt(paid)}',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color:
                                  full ? AppColors.primary : AppColors.warning),
                        ),
                      )
                    : const SizedBox(),
                onTap: () => _showPaymentSheet(m),
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _deadlineLabel() {
    final d = DateTime.tryParse(campaign['deadline']?.toString() ?? '');
    if (d == null) return '—';
    return '${d.day}/${d.month}/${d.year}';
  }

  Widget _stat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.text)),
        Text(label,
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.muted)),
      ],
    );
  }
}
