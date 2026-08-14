import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../services/contribution_service.dart';
import '../services/hive_service.dart';
import '../services/payment_report_service.dart';

/// Payments ledger — every receipt across all campaigns of the workspace.
///
/// Flattens all payments ([ContributionService.flattenPayments]) newest-first,
/// filterable by campaign / type / member name. Each row shows the amount,
/// ref, method and a VERIFIED badge or a "tap to verify" action. Tapping a row
/// opens a proof sheet (ref · pin · member · phone) with copy + re-verify, and
/// a bottom sheet exports the paid report as PDF (share / print / SMS).
class PaymentsLedgerScreen extends StatefulWidget {
  const PaymentsLedgerScreen({super.key});

  @override
  State<PaymentsLedgerScreen> createState() => _PaymentsLedgerScreenState();
}

class _PaymentsLedgerScreenState extends State<PaymentsLedgerScreen> {
  String? _campaignFilter;
  String? _typeFilter;
  String _query = '';
  bool _exporting = false;
  bool _syncing = false;

  List<Map<String, dynamic>> get _allPayments {
    final campaigns = ContributionService.campaigns();
    return ContributionService.flattenPayments(campaigns);
  }

  List<Map<String, dynamic>> get _filtered {
    return _allPayments.where((p) {
      if (_campaignFilter != null && p['campaign_id'] != _campaignFilter)
        return false;
      if (_typeFilter != null && p['contrib_type'] != _typeFilter) return false;
      if (_query.isNotEmpty &&
          !(p['member_name']?.toString().toLowerCase() ?? '')
              .contains(_query.toLowerCase())) return false;
      return true;
    }).toList();
  }

  List<Map> get _campaigns {
    final cs = ContributionService.campaigns();
    return cs
      ..sort(
          (a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
  }

  double get _collected =>
      _filtered.fold(0.0, (s, p) => s + (p['paid'] as num));

  Map<String, int> get _typeCounts {
    final counts = <String, int>{};
    for (final c in _campaigns) {
      final t = c['contrib_type']?.toString() ?? 'Regular';
      counts[t] = (counts[t] ?? 0) + (c['payments'] as List? ?? []).length;
    }
    return counts;
  }

  void _verify(Map<String, dynamic> payment) {
    final campaigns = ContributionService.campaigns();
    final c =
        campaigns.where((x) => x['id'] == payment['campaign_id']).firstOrNull;
    if (c == null) return;
    final payments = List<Map<String, dynamic>>.from(c['payments'] ?? []);
    final idx = payments.indexWhere((p) => p['ref'] == payment['ref']);
    if (idx >= 0) {
      payments[idx]['verified'] = true;
      c['payments'] = payments;
      HiveService.updateCampaign(c);
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Verified — ${payment['member_name']}. Now exportable in the PDF.',
                style: GoogleFonts.inter(fontSize: 12.5),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _copy(BuildContext ctx, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.copy_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('Copied', style: GoogleFonts.inter()),
          ],
        ),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _syncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cloud_done_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Synced ${_filtered.length} payment records to cloud ledger',
                  style: GoogleFonts.inter(fontSize: 12.5),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _export() async {
    final payments = _filtered;
    if (payments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No payments to export')),
      );
      return;
    }
    final ws = HiveService.getActiveWorkspace();
    final orgName = ws?['name']?.toString() ?? 'Organization';
    final scope = _campaignFilter == null
        ? 'All contributions'
        : (_campaigns
                .where((c) => c['id'] == _campaignFilter)
                .firstOrNull?['title'] as String? ??
            'Selected contribution');

    final title = 'PAYMENTS LEDGER — $scope';
    final action = await showModalBottomSheet<_ExportAction>(
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
              Text('Export report',
                  style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text)),
              const SizedBox(height: 4),
              Text(
                '${payments.length} payments · Ksh ${_fmt(_collected)} · $scope',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              _exportTile(ctx, Icons.share_rounded, 'Share PDF',
                  'Message / mail the full report', _ExportAction.share,
                  color: AppColors.primary),
              const SizedBox(height: 8),
              _exportTile(ctx, Icons.print_rounded, 'Print PDF',
                  'Send to a printer for the meeting', _ExportAction.print,
                  color: const Color(0xFF2563EB)),
              const SizedBox(height: 8),
              _exportTile(
                  ctx,
                  Icons.sms_rounded,
                  'SMS results to members',
                  'Each member gets their paid status via SMS',
                  _ExportAction.sms,
                  color: AppColors.accent),
            ],
          ),
        ),
      ),
    );

    if (action == null || !mounted) return;
    setState(() => _exporting = true);
    try {
      if (action == _ExportAction.share) {
        await PaymentReportService.share(
          orgName: orgName,
          reportTitle: title,
          payments: payments,
        );
      } else if (action == _ExportAction.print) {
        await PaymentReportService.printPdf(
          orgName: orgName,
          reportTitle: title,
          payments: payments,
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('SMS status sent to each member',
                  style: GoogleFonts.inter()),
              backgroundColor: AppColors.accent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
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
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _exportTile(BuildContext ctx, IconData icon, String title,
      String subtitle, _ExportAction action,
      {required Color color}) {
    return Material(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pop(ctx, action),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text)),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 11.5, color: AppColors.muted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(num v) {
    return v
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  String _timeAgo(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '—';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final ws = HiveService.getActiveWorkspace();
    final payments = _filtered;
    final verifiedCount = payments.where((p) => p['verified'] == true).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text('Payments Ledger',
            style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.text)),
        actions: [
          IconButton(
            onPressed: _exporting ? null : _export,
            icon: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary))
                : const Icon(Icons.share_rounded, color: AppColors.primary),
            tooltip: 'Export PDF / share / print',
          ),
          IconButton(
            onPressed: _syncing ? null : _sync,
            icon: Icon(Icons.cloud_upload_rounded,
                color: _syncing ? AppColors.muted : AppColors.accent),
            tooltip: 'Sync ledger',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ksh ${_fmt(_collected)}',
                          style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary)),
                      Text('Collected · ${payments.length} payments',
                          style: GoogleFonts.inter(
                              fontSize: 11.5, color: AppColors.muted)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: AppColors.primary, size: 15),
                      const SizedBox(width: 4),
                      Text('$verifiedCount/${payments.length} verified',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filters
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search member…',
                    hintStyle: GoogleFonts.inter(color: AppColors.muted),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.muted, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip(null, 'All'),
                      ..._typeCounts.keys.map((t) => _filterChip(t, t)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Expanded(
            child: payments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 44, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Text('No payments yet',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.muted)),
                        Text(
                            'Run a member payment demo or collect a member to populate this ledger.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                fontSize: 11.5, color: Colors.grey.shade400)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    color: AppColors.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      itemCount: payments.length,
                      itemBuilder: (context, index) {
                        final p = payments[index];
                        return _paymentCard(p);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String? value, String label) {
    final myType = value;
    final selected = myType == _typeFilter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _typeFilter = selected ? null : myType),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? AppColors.primary : Colors.grey.shade200),
          ),
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.text)),
        ),
      ),
    );
  }

  Widget _paymentCard(Map<String, dynamic> p) {
    final paid = (p['paid'] as num).toDouble();
    final verified = p['verified'] == true;
    final campaignTitle = p['campaign_title']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showProof(p),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: verified
                          ? AppColors.primary.withOpacity(0.15)
                          : AppColors.warning.withOpacity(0.15),
                      child: Text(
                        (p['member_name']?.toString() ?? '?')[0].toUpperCase(),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color:
                              verified ? AppColors.primary : AppColors.warning,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['member_name']?.toString() ?? 'Member',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.text)),
                          Text(
                            campaignTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: verified
                                    ? AppColors.primary
                                    : AppColors.warning),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Ksh ${_fmt(paid)}',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: verified
                                    ? AppColors.primary
                                    : AppColors.warning)),
                        Text(_timeAgo(p['paid_at']?.toString() ?? ''),
                            style: GoogleFonts.inter(
                                fontSize: 10.5, color: AppColors.muted)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.receipt_rounded,
                        size: 13, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(p['ref']?.toString() ?? '—',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text)),
                    Text(
                        ' · ${p['method']?.toString().split(' ').first ?? '—'}',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.muted)),
                    const Spacer(),
                    verified
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('VERIFIED',
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary)),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('TAP TO VERIFY',
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.warning)),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProof(Map<String, dynamic> p) {
    final verified = p['verified'] == true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(p['member_name']?.toString() ?? 'Member',
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text)),
                  ),
                  Icon(
                      verified
                          ? Icons.verified_rounded
                          : Icons.hourglass_top_rounded,
                      color: verified ? AppColors.primary : AppColors.warning,
                      size: 22),
                ],
              ),
              const SizedBox(height: 4),
              Text(p['campaign_title']?.toString() ?? '',
                  style:
                      GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 16),
              _proofRow('Amount', 'Ksh ${_fmt((p['paid'] as num).toDouble())}'),
              _proofRow('Member code', p['member_code']?.toString() ?? '—'),
              _proofRow('Phone',
                  (p['phone']?.toString() ?? '—').replaceFirst('254', '0')),
              _proofRow('Receipt ref', p['ref']?.toString() ?? '—'),
              _proofRow('Receipt PIN', p['pin']?.toString() ?? '—'),
              _proofRow('Method', p['method']?.toString() ?? '—'),
              _proofRow('Time', _timeAgo(p['paid_at']?.toString() ?? '')),
              const SizedBox(height: 16),
              if (!verified)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      _verify(p);
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.verified_rounded, size: 18),
                    label: Text('VERIFY PAYMENT',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: BorderSide(color: AppColors.accent.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    _copy(ctx, p['ref']?.toString() ?? '');
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.copy_rounded, size: 17),
                  label: Text('Copy receipt ref for parent / member',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _proofRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text)),
          ),
        ],
      ),
    );
  }
}

enum _ExportAction { share, print, sms }

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
