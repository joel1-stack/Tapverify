import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart';
import '../services/contribution_service.dart';
import '../services/payment_report_service.dart';
import '../models/member.dart';
import '../models/pending_event.dart';
import 'campaign_detail_screen.dart';

/// Activity tab — the printable contributions register.
///
/// Shows every contribution of the active workspace with a type filter
/// (All / Regular / Trip / Emergency / Loan ...), a summary strip (total
/// collected + members not yet paid), per-contribution cards carrying paid /
/// partial / unpaid counts and an EXPORT button, plus a "PRINT / SHARE FULL
/// REGISTER" action that renders the whole register PDF via
/// [PaymentReportService]. Also lists the pending offline events.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  List<PendingEvent> _pending = [];
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<Map> get _campaigns {
    final cs = ContributionService.campaigns();
    cs.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
    if (_typeFilter == null) return cs;
    return cs.where((c) => c['contrib_type'] == _typeFilter).toList();
  }

  Future<void> _load() async {
    final staff = HiveService.getStaff();
    final wsId = staff?['workspace']?['id'];
    if (wsId != null) {
      try {
        final stats = await ApiService.fetchStats(wsId);
        setState(() => _stats = stats);
      } catch (e) {}
    }
    setState(() {
      _pending = HiveService.getPendingEvents();
      _loading = false;
    });
  }

  Future<void> _sync() async {
    setState(() => _loading = true);
    final synced = await ApiService.syncPending();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('$synced payments synced', style: GoogleFonts.inter()),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    await _load();
  }

  // ---- summary across all campaigns ----
  double get _totalCollected {
    double s = 0;
    for (final c in ContributionService.campaigns()) {
      for (final p in List<Map<String, dynamic>>.from(c['payments'] ?? [])) {
        s += (p['paid'] as num);
      }
    }
    return s;
  }

  int get _unpaidAcross {
    var n = 0;
    for (final c in ContributionService.campaigns()) {
      final wsId = c['workspace_id'];
      final members = HiveService.getMembersForWorkspace(wsId);
      final amount = (c['amount'] as num).toDouble();
      final payments = List<Map<String, dynamic>>.from(c['payments'] ?? []);
      for (final m in members) {
        final paid = payments
            .where((p) => p['member_id'] == m.id)
            .fold<double>(0, (s, p) => s + (p['paid'] as num));
        if (paid < amount) n++;
      }
    }
    return n;
  }

  Map<String, int> get _typeCounts {
    final counts = <String, int>{};
    for (final c in ContributionService.campaigns()) {
      final t = c['contrib_type']?.toString() ?? 'Regular';
      counts[t] = (counts[t] ?? 0) + 1;
    }
    return counts;
  }

  String _fmt(num n) {
    return n
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  String _dl(Map c) {
    final d = DateTime.tryParse(c['deadline']?.toString() ?? '');
    if (d == null) return '';
    return '${d.day}/${d.month}/${d.year}';
  }

  Future<void> _exportRegister() async {
    final ws = HiveService.getActiveWorkspace();
    final orgName = ws?['name']?.toString() ?? 'Organization';
    final orgType = ws?['type']?.toString() ?? 'Group';

    // Build the structured register: one entry per contribution with its
    // per-member status table, ready for the printable PDF.
    final contributions = <Map<String, dynamic>>[];
    for (final c in _campaigns) {
      final wsId = c['workspace_id']?.toString() ?? '';
      final members = HiveService.getMembersForWorkspace(wsId);
      final amount = (c['amount'] as num?)?.toDouble() ?? 0;
      final payments = List<Map<String, dynamic>>.from(c['payments'] ?? []);
      final memberRows = <Map<String, dynamic>>[];
      var collected = 0.0;
      var paidCount = 0;
      var partialCount = 0;
      var unpaidCount = 0;
      for (final m in members) {
        var paid = 0.0;
        for (final p in payments.where((p) => p['member_id'] == m.id)) {
          paid += (p['paid'] as num);
        }
        collected += paid;
        final due = amount > paid ? amount - paid : 0.0;
        final status = paid >= amount && amount > 0
            ? 'PAID'
            : (paid > 0 ? 'PARTIAL' : 'NOT PAID');
        if (status == 'PAID') {
          paidCount++;
        } else if (status == 'PARTIAL') {
          partialCount++;
        } else {
          unpaidCount++;
        }
        memberRows.add({
          'name': m.name,
          'member_code': m.memberCode,
          'phone': m.phone,
          'paid': paid,
          'due': due,
          'status': status,
        });
      }
      contributions.add({
        'title': c['title']?.toString() ?? 'Contribution',
        'contrib_type': c['contrib_type']?.toString() ?? 'Regular',
        'frequency': (c['frequency'] ?? '').toString().replaceAll('_', ' '),
        'deadline': _dl(c),
        'amount': amount,
        'collected': collected,
        'target': amount * members.length,
        'paid_count': paidCount,
        'partial_count': partialCount,
        'unpaid_count': unpaidCount,
        'borrower': c['contrib_type'] == 'Loan'
            ? members.isEmpty
                ? '—'
                : members.first.name
            : null,
        'members': memberRows,
      });
    }

    if (contributions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contributions to print yet')),
      );
      return;
    }

    try {
      await PaymentReportService.printRegister(
        orgName: orgName,
        orgType: orgType,
        contributions: contributions,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                    'Register opened in print preview — use the share icon to send as PDF',
                    style: GoogleFonts.inter(fontSize: 12.5)),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print failed: $e', style: GoogleFonts.inter()),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _exportCampaign(Map campaign) async {
    final payments = ContributionService.flattenPayments([campaign]);
    final ws = HiveService.getActiveWorkspace();
    final orgName = ws?['name']?.toString() ?? 'Organization';
    final title = campaign['title']?.toString() ?? 'Contribution';

    // Build unpaid list for this campaign
    final amount = (campaign['amount'] as num).toDouble();
    final members =
        HiveService.getMembersForWorkspace(campaign['workspace_id'] ?? '');
    final unpaidMembers = <Map<String, dynamic>>[];
    for (final m in members) {
      final paid = payments
          .where((p) => p['member_id'] == m.id)
          .fold<double>(0, (s, p) => s + (p['paid'] as num));
      if (paid < amount) {
        unpaidMembers.add({
          'name': m.name,
          'member_code': m.memberCode,
          'phone': m.phone,
          'due': (amount - paid),
        });
      }
    }

    final choice = await showModalBottomSheet<String>(
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
              Text('Export $title',
                  style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text)),
              const SizedBox(height: 4),
              Text('${payments.length} paid · ${unpaidMembers.length} not paid',
                  style:
                      GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 16),
              _exportTile(
                  ctx,
                  Icons.check_circle_rounded,
                  'PAID members (PDF)',
                  '${payments.length} payments with receipt refs',
                  AppColors.primary,
                  'paid'),
              const SizedBox(height: 8),
              _exportTile(
                  ctx,
                  Icons.error_outline_rounded,
                  'UNPAID members (PDF)',
                  '${unpaidMembers.length} members who have not paid for follow-up',
                  AppColors.danger,
                  'unpaid'),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;

    try {
      if (choice == 'paid' && payments.isNotEmpty) {
        await PaymentReportService.share(
          orgName: orgName,
          reportTitle: 'PAID MEMBERS — $title',
          payments: payments,
        );
      } else if (choice == 'paid') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No payments to export yet')),
        );
      } else if (choice == 'unpaid' && unpaidMembers.isNotEmpty) {
        await PaymentReportService.shareOutstanding(
          orgName: orgName,
          reportTitle: title,
          members: unpaidMembers,
        );
      } else if (choice == 'unpaid') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Everyone has paid 🎉')),
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

  Widget _exportTile(BuildContext ctx, IconData icon, String title,
      String subtitle, Color color, String value) {
    return Material(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pop(ctx, value),
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

  (IconData, Color) _typeMeta(String type) {
    switch (type) {
      case 'Emergency':
        return (Icons.emergency_rounded, const Color(0xFFDC2626));
      case 'Trip':
        return (Icons.flight_takeoff_rounded, const Color(0xFF2563EB));
      case 'School trip':
        return (Icons.school_rounded, const Color(0xFF7C3AED));
      case 'Loan':
        return (Icons.account_balance_rounded, const Color(0xFFD97706));
      case 'Project':
        return (Icons.handyman_rounded, const Color(0xFF0D9488));
      case 'One-Time':
        return (Icons.event_available_rounded, const Color(0xFFDB2777));
      default:
        return (Icons.currency_exchange_rounded, AppColors.primary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = _campaigns;
    final ws = HiveService.getActiveWorkspace();
    final allMembers = HiveService.getMembersForWorkspace(ws?['id'] ?? '');

    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // Offline Pending Queue
          if (_pending.isNotEmpty) ...[
            _PendingCard(
              count: _pending.length,
              total: _pending.fold(0.0, (s, e) => s + e.amount),
              onSync: _sync,
            ),
            const SizedBox(height: 24),
          ],

          // Summary strip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.deep, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ksh ${_fmt(_totalCollected)}',
                          style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      Text(
                          'Total collected · ${ContributionService.campaigns().length} contributions',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$_unpaidAcross',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFFDE68A))),
                    Text('members not yet paid',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _exportRegister,
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
            label: Text('PRINT / SHARE FULL REGISTER',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    color: const Color(0xFF2563EB))),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              side: BorderSide(color: const Color(0xFF2563EB).withOpacity(0.4)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),

          // Type filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip(null, 'All'),
                ..._typeCounts.keys.map((t) => _chip(t, t)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Contributions',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (campaigns.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  Icon(Icons.campaign_outlined,
                      size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('No contributions yet',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                  const SizedBox(height: 4),
                  Text('Create one from the Home tab and members get notified.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.muted)),
                ],
              ),
            )
          else
            ...campaigns.map((c) => _ContributionCard(
                  campaign: c,
                  onOpen: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CampaignDetailScreen(campaign: c)),
                    );
                    if (mounted) setState(() {});
                  },
                  onExport: () => _exportCampaign(c),
                )),

          const SizedBox(height: 28),

          // All members roster
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'All members · ${allMembers.length}',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (campaigns.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Paid status for latest: ${campaigns.first['title']}',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
              ),
            ),
          if (allMembers.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Text('No members in this group yet.',
                  style:
                      GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
            )
          else
            ..._memberRows(
                allMembers, campaigns.isNotEmpty ? campaigns.first : null),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _chip(String? value, String label) {
    final selected = value == _typeFilter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _typeFilter = selected ? null : value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? AppColors.primary : Colors.grey.shade200),
          ),
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.text)),
        ),
      ),
    );
  }

  List<Widget> _memberRows(List<Member> members, Map? campaign) {
    final amount = (campaign?['amount'] as num?)?.toDouble() ?? 0;
    final payments =
        List<Map<String, dynamic>>.from(campaign?['payments'] ?? []);
    return members.map((m) {
      double paid = 0;
      String? method;
      for (final p in payments.where((p) => p['member_id'] == m.id)) {
        paid += (p['paid'] as num);
        method = p['method']?.toString();
      }
      final full = amount > 0 && paid >= amount;
      final partial = paid > 0 && !full;
      final none = paid <= 0;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: full
                ? AppColors.primary.withOpacity(0.15)
                : partial
                    ? AppColors.warning.withOpacity(0.15)
                    : Colors.grey.shade100,
            child: Text(m.name[0].toUpperCase(),
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: full
                        ? AppColors.primary
                        : partial
                            ? AppColors.warning
                            : AppColors.muted)),
          ),
          title: Text(m.name,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, fontSize: 13.5)),
          subtitle: Text(
              '${m.memberCode} · ${m.phone.replaceFirst('254', '0')}${method != null ? ' · $method' : ''}',
              style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.muted)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: full
                  ? AppColors.primary.withOpacity(0.1)
                  : partial
                      ? AppColors.warning.withOpacity(0.1)
                      : AppColors.danger.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              full
                  ? 'PAID'
                  : partial
                      ? 'PARTIAL · Ksh ${_fmt(paid)}'
                      : 'NOT PAID',
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: full
                      ? AppColors.primary
                      : partial
                          ? AppColors.warning
                          : AppColors.danger),
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _ContributionCard extends StatelessWidget {
  final Map campaign;
  final VoidCallback onOpen;
  final VoidCallback onExport;

  const _ContributionCard({
    required this.campaign,
    required this.onOpen,
    required this.onExport,
  });

  String _fmt(num n) {
    return n
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  String _dl() {
    final d = DateTime.tryParse(campaign['deadline']?.toString() ?? '');
    if (d == null) return '';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final type = campaign['contrib_type']?.toString() ?? 'Regular';
    final amount = (campaign['amount'] as num).toDouble();
    final payments =
        List<Map<String, dynamic>>.from(campaign['payments'] ?? []);
    final collected =
        payments.fold<double>(0, (s, p) => s + (p['paid'] as num));
    final members =
        HiveService.getMembersForWorkspace(campaign['workspace_id'] ?? '');
    final target = amount * members.length;
    final pct =
        target > 0 ? ((collected / target) * 100).clamp(0, 100) / 100 : 0.0;

    var fullCount = 0;
    var partialCount = 0;
    var noneCount = 0;
    for (final m in members) {
      final paid = payments
          .where((p) => p['member_id'] == m.id)
          .fold<double>(0, (s, p) => s + (p['paid'] as num));
      if (paid >= amount) {
        fullCount++;
      } else if (paid > 0) {
        partialCount++;
      } else {
        noneCount++;
      }
    }

    final ws = HiveService.getWorkspaces()
        .where((w) => w['id'] == campaign['workspace_id'])
        .toList();
    final orgType = ws.isNotEmpty ? ws.first['type']?.toString() : null;

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
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _typeColor(type).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_typeIcon(type),
                          color: _typeColor(type), size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(campaign['title'] ?? 'Contribution',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.text)),
                          Text(
                            '${campaign['contrib_type'] ?? 'Regular'}'
                            '${orgType != null ? ' · $orgType' : ''}'
                            ' · ${_dl()}',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _typeColor(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(type.toUpperCase(),
                          style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: _typeColor(type))),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: AppColors.primary.withOpacity(0.08),
                    color: _typeColor(type),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                          'Ksh ${_fmt(collected)} of Ksh ${_fmt(target)}',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text)),
                    ),
                    Text(
                        '$fullCount paid · $partialCount partial · $noneCount unpaid',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: noneCount > 0
                                ? AppColors.danger
                                : AppColors.muted)),
                  ],
                ),
                if (noneCount > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: AppColors.danger.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.danger, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('$noneCount members have not paid yet',
                              style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.danger, size: 16),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                        'Deadline ${_dl()} · ${(campaign['frequency'] ?? '').toString().replaceAll('_', ' ')}',
                        style: GoogleFonts.inter(
                            fontSize: 10, color: AppColors.muted)),
                    const Spacer(),
                    Text('Ksh ${_fmt(amount)}/member',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ],
                ),
                if (payments.isNotEmpty || members.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: onExport,
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: Text(
                          'EXPORT · paid ${_fmt(collected)} · $noneCount unpaid',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: const Color(0xFF2563EB))),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: BorderSide(
                            color: const Color(0xFF2563EB).withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
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

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Emergency':
        return Icons.emergency_rounded;
      case 'Trip':
        return Icons.flight_takeoff_rounded;
      case 'School trip':
        return Icons.school_rounded;
      case 'Loan':
        return Icons.account_balance_rounded;
      case 'Project':
        return Icons.handyman_rounded;
      case 'One-Time':
        return Icons.event_available_rounded;
      default:
        return Icons.currency_exchange_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Emergency':
        return const Color(0xFFDC2626);
      case 'Trip':
        return const Color(0xFF2563EB);
      case 'School trip':
        return const Color(0xFF7C3AED);
      case 'Loan':
        return const Color(0xFFD97706);
      case 'Project':
        return const Color(0xFF0D9488);
      case 'One-Time':
        return const Color(0xFFDB2777);
      default:
        return AppColors.primary;
    }
  }
}

class _PendingCard extends StatelessWidget {
  final int count;
  final double total;
  final VoidCallback onSync;

  const _PendingCard({
    required this.count,
    required this.total,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.cloud_upload_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count payments saved offline',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ksh ${total.toStringAsFixed(0)} — tap to sync',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onSync,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  'SYNC',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
