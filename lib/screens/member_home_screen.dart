import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../models/member.dart';
import '../services/hive_service.dart';
import '../services/contribution_service.dart';
import 'login_screen.dart';
import 'payments_ledger_screen.dart';
import 'loan_eligibility_screen.dart';

/// Member-side home.
///
/// The member signs in by phone + OTP (no password) and lands here to see
/// **every group they belong to in one app** — a chama, a school, a burial
/// group, a SACCO — each with its due amount, a LOOP request-to-pay button,
/// receipts, statements and a notification feed covering the member
/// notification matrix (new contribution, reminder, receipt, suspension,
/// reinstatement, loan decision).
class MemberHomeScreen extends StatefulWidget {
  final String phone;
  final String name;

  const MemberHomeScreen({super.key, required this.phone, required this.name});

  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _Membership {
  final Map ws;
  final Member member;
  _Membership(this.ws, this.member);
}

class _MemberHomeScreenState extends State<MemberHomeScreen> {
  int _tab = 0;

  List<_Membership> get _memberships {
    final workspaces = HiveService.getWorkspaces().map((w) => w['id']).toSet();
    final out = <_Membership>[];
    for (final m in HiveService.getCachedMembers()) {
      if (m.phone != widget.phone) continue;
      if (!workspaces.contains(m.workspaceId)) continue;
      Map? ws;
      for (final w in HiveService.getWorkspaces()) {
        if (w['id'] == m.workspaceId) ws = w;
      }
      if (ws != null) out.add(_Membership(ws, m));
    }
    out.sort((a, b) => a.ws['name'].compareTo(b.ws['name']));
    return out;
  }

  List<Map> get _dueCampaigns {
    final out = <Map>[];
    for (final ws in HiveService.getWorkspaces()) {
      final wsId = ws['id'];
      for (final c in HiveService.getCampaignsForWorkspace(wsId)) {
        if (c['status'] != 'active') continue;
        final deadline = DateTime.tryParse(c['deadline']?.toString() ?? '');
        if (deadline != null && deadline.isBefore(DateTime.now())) continue;
        // Only show campaigns this member is part of and hasn't fully paid.
        for (final ms in _memberships) {
          if (ms.ws['id'] != wsId) continue;
          final payments =
              List<Map<String, dynamic>>.from(c['payments'] ?? []).where(
                  (p) => p['member_id'] == ms.member.id);
          final paid =
              payments.fold<double>(0, (s, p) => s + (p['paid'] as num));
          final amount = (c['amount'] as num? ?? 0).toDouble();
          if (paid < amount) {
            out.add({...c, 'ws': ws, '_remaining': amount - paid});
            break;
          }
        }
      }
    }
    out.sort((a, b) => (b['deadline'] ?? '')
        .toString()
        .compareTo(a['deadline']?.toString() ?? ''));
    return out;
  }

  List<Map<String, dynamic>> get _receipts {
    final ids = _memberships.map((m) => m.member.id).toSet();
    final all = <Map>[];
    for (final ws in HiveService.getWorkspaces()) {
      all.addAll(HiveService.getCampaignsForWorkspace(ws['id']));
    }
    return ContributionService.flattenPayments(all)
        .where((p) => ids.contains(p['member_id']))
        .toList();
  }

  Future<void> _logout() async {
    await HiveService.clearAuth();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _payNow(_Membership sub) async {
    final ws = sub.ws;
    final member = sub.member;
    if (HiveService.isMemberSession && !member.canContribute) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            member.status == 'suspended'
                ? 'Your membership is suspended. Contact your treasurer.'
                : 'You can no longer contribute to this group.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final wsId = ws['id'] as String;
    var campaigns = HiveService.getCampaignsForWorkspace(wsId)
        .where((c) => c['status'] == 'active')
        .toList()
      ..sort((a, b) => (b['deadline'] ?? '').toString().compareTo(a['deadline']?.toString() ?? ''));
    Map? campaign = campaigns.isNotEmpty ? campaigns.first : null;

    double remaining = 0;
    if (campaign != null) {
      final amount = (campaign['amount'] as num? ?? 0).toDouble();
      final paid = List<Map<String, dynamic>>.from(campaign['payments'] ?? [])
          .where((p) => p['member_id'] == member.id)
          .fold<double>(0, (s, p) => s + (p['paid'] as num));
      remaining = (amount - paid).clamp(0, double.infinity);
    }
    var target = remaining > 0 ? remaining : member.balanceDue;
    if (target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No outstanding amount for ${ws['name']}',
              style: GoogleFonts.inter()),
          backgroundColor: AppColors.deep,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // No open campaign yet — pin this payment to a general contribution so it
    // lands in the ledger and the member's receipt history.
    if (campaign == null) {
      campaign = ContributionService.create(
        title: 'Contribution — ${ws['name']}',
        contribType: 'Regular',
        amount: target,
        frequency: 'monthly',
        deadline: DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        message: 'Monthly contribution for ${ws['name']}',
        paymentMethod: {
          'rail': 'loop',
          'label': 'LOOP (NCBA) Request-to-Pay',
        },
        allowPartial: true,
        minPartial: 0,
        workspaceId: wsId,
      );
    }

    // LOOP Request-to-Pay (NCBA sandbox). Live builds hit the gateway via the
    // board's LOOP connection; the demo resolves instantly with an order id.
    final loopRail = ws?['rails']?['loop'] == true;
    final method = loopRail
        ? 'LOOP (NCBA) Request-to-Pay'
        : (ws?['rails']?['till'] == true ? 'M-PESA Till' : 'Paybill');
    final payment = ContributionService.recordPayment(
      campaign,
      member.id,
      member.name,
      member.memberCode,
      member.phone,
      target,
      method,
    );

    await HiveService.addMember(
      member.copyWith(
        balanceDue:
            member.balanceDue - target > 0 ? member.balanceDue - target : 0,
      ),
    );

    final millis = DateTime.now().millisecondsSinceEpoch.toString();
    final transferOrderId = 'TAM${millis.padLeft(19, '0')}';

    if (!mounted) return;
    setState(() {});
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _ReceiptSheet(
        groupName: ws['name'],
        amount: target,
        ref: payment['ref'].toString(),
        pin: payment['pin'].toString(),
        transferOrderId: transferOrderId,
        method: method,
      ),
    );
  }

  void _requestReinstate(_Membership sub) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reinstatement request sent to the ${sub.ws['name']} board',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: AppColors.deep,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subs = _memberships;
    final suspended = subs.where((s) => s.member.isSuspended).toList();
    final due = _dueCampaigns;
    final receipts = _receipts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 210,
              pinned: true,
              backgroundColor: AppColors.deep,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.deep, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.person_rounded,
                                color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, ${widget.name}',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.phone_rounded,
                                        size: 13,
                                        color: Colors.white.withOpacity(0.7)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${widget.phone} · OTP secured',
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          color:
                                              Colors.white.withOpacity(0.75),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _logout,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withOpacity(0.15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.logout_rounded, size: 16),
                            label: Text('Logout',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _badge('${subs.length} groups', Icons.groups_rounded),
                          const SizedBox(width: 8),
                          _badge(
                              'Ksh ${_fmt(_totalDue(subs))} due',
                              Icons.payments_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: AppColors.deep,
                  child: const TabBar(
                    indicatorColor: Color(0xFFFFB066),
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13.5),
                    tabs: [
                      Tab(text: 'My Groups'),
                      Tab(text: 'Receipts'),
                    ],
                  ),
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _buildGroupsTab(subs, due),
              _buildReceiptsTab(receipts),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(text,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ],
      ),
    );
  }

  double _totalDue(List<_Membership> subs) =>
      subs.fold(0.0, (s, m) => s + m.member.balanceDue);

  Widget _buildGroupsTab(List<_Membership> subs, List<Map> due) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final s in subs)
          _groupCard(s, due.where((d) => d['ws']?['id'] == s.ws['id']).map(
              (d) => (d['_remaining'] as num?)?.toDouble() ?? 0).fold(0.0,
                  (a, b) => a + b)),
        const SizedBox(height: 12),

        if (due.isNotEmpty) ...[
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text('Due now',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text)),
            ],
          ),
          const SizedBox(height: 10),
          for (final c in due) _dueCard(c),
          const SizedBox(height: 12),
        ],

        // Notification matrix
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text('Notifications',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text)),
          ],
        ),
        const SizedBox(height: 10),
        ..._notifications(subs, due),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _groupCard(_Membership sub, double due) {
    final ws = sub.ws;
    final m = sub.member;
    final image = ws?['image']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: image.isEmpty
                      ? Container(
                          width: 46,
                          height: 46,
                          color: AppColors.deep.withOpacity(0.1),
                          child: const Icon(Icons.groups_rounded,
                              color: AppColors.deep, size: 24),
                        )
                      : Image.network(
                          image,
                          width: 46,
                          height: 46,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 46,
                            height: 46,
                            color: AppColors.deep.withOpacity(0.1),
                            child: const Icon(Icons.groups_rounded,
                                color: AppColors.deep, size: 24),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ws['name'] ?? 'Group',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text)),
                      const SizedBox(height: 2),
                      Text(
                        '${ws['type'] ?? ''} · ${m.memberCode}',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                _statusChip(m.status),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Outstanding',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.muted)),
                      Text(
                        'Ksh ${_fmt(due > 0 ? due : m.balanceDue)}',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: m.isSuspended ? AppColors.muted : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
                if (m.isSuspended)
                  OutlinedButton.icon(
                    onPressed: () => _requestReinstate(sub),
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: Text('Request reinstatement',
                        style: GoogleFonts.inter(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                else
                  FilledButton.icon(
                    onPressed: () => _payNow(sub),
                    icon: const Icon(Icons.swap_vert_circle_rounded, size: 18),
                    label: Text(
                      'Pay now  ·  Ksh ${_fmt(due > 0 ? due : m.balanceDue)}',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final (label, color, icon) = switch (status) {
      'suspended' => ('Suspended', AppColors.danger, Icons.pause_circle_rounded),
      'invited' => ('Invited', AppColors.gold, Icons.mark_email_unread_rounded),
      'left' => ('Left', AppColors.muted, Icons.exit_to_app_rounded),
      'banned' => ('Banned', AppColors.danger, Icons.block_rounded),
      _ => ('Active', AppColors.primary, Icons.check_circle_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }

  Widget _dueCard(Map c) {
    final ws = c['ws'];
    final remaining = (c['_remaining'] as num?)?.toDouble() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.campaign_rounded,
              color: AppColors.accent, size: 20),
        ),
        title: Text(c['title'] ?? 'Contribution',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: AppColors.text)),
        subtitle: Text(
          '${ws?['name'] ?? ''} · ${_fmt(remaining)} left',
          style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.muted),
        ),
        trailing: Text(
          '${c['payment_method']?['label'] ?? 'LOOP'}',
          style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primary),
        ),
      ),
    );
  }

  List<Widget> _notifications(List<_Membership> subs, List<Map> due) {
    final items = <(IconData, Color, String, String)>[];
    if (subs.any((s) => s.member.isSuspended)) {
      items.add((
        Icons.pause_circle_rounded,
        AppColors.danger,
        'You were suspended from ${subs.firstWhere((s) => s.member.isSuspended).ws['name']}',
        'Tap request reinstatement on the group card to appeal.',
      ));
    }
    if (due.isNotEmpty) {
      items.add((
        Icons.campaign_rounded,
        AppColors.accent,
        'New contribution: ${due.last['title']}',
        'Ksh ${_fmt(due.last['_remaining'])} remaining in ${due.last['ws']?['name']}.',
      ));
      items.add((
        Icons.alarm_rounded,
        AppColors.gold,
        'Reminder — you haven\u2019t paid yet',
        '${due.last['ws']?['name'] ?? 'Your group'} deadline is approaching. Pay via your payment link.',
      ));
    }
    if (_receipts.isNotEmpty) {
      items.add((
        Icons.check_circle_rounded,
        AppColors.primary,
        'Receipt ${_receipts.first['ref']} confirmed',
        'Ksh ${_fmt(_receipts.first['paid'])} to ${_receipts.first['campaign_title']}. SMS sent.',
      ));
    }
    items.add((
      Icons.badge_rounded,
      AppColors.deep,
      'Welcome to TapVerify',
      'Your number is registered. You now see every group you belong to in one app.',
    ));
    items.add((
      Icons.savings_rounded,
      AppColors.gold,
      'Loan decisions arrive here',
      'Once your group turns on lending, eligibility checks and approvals show up as notifications.',
    ));

    return items.map((n) {
      final (icon, color, title, body) = n;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(title,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.text)),
          subtitle:
              Text(body, style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.muted)),
        ),
      );
    }).toList();
  }

  Widget _buildReceiptsTab(List<Map<String, dynamic>> receipts) {
    if (receipts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_rounded,
                size: 52, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text('No receipts yet',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted)),
            const SizedBox(height: 4),
            Text('Your payments will appear here',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: receipts.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PaymentsLedgerScreen()),
                    ),
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: Text('Full statement & export',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.deep,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LoanEligibilityScreen()),
                  ),
                  icon: const Icon(Icons.savings_rounded),
                  tooltip: 'Loan eligibility',
                  style: IconButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white),
                ),
              ],
            ),
          );
        }
        final p = receipts[i - 1];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
            ),
            title: Text(p['campaign_title'] ?? 'Payment',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppColors.text)),
            subtitle: Text(
              '${p['ref']} · ${p['method'] ?? 'LOOP'} · ${_when(p['paid_at'])}',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
            ),
            trailing: Text('Ksh ${_fmt(p['paid'])}',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.primary)),
          ),
        );
      },
    );
  }

  String _when(dynamic ts) {
    final d = DateTime.tryParse(ts?.toString() ?? '');
    if (d == null) return '';
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}min ago';
  }

  String _fmt(dynamic value) {
    final n = value is num ? value : double.tryParse(value.toString()) ?? 0;
    return n.round().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

/// Success receipt shown after a member pays via LOOP request-to-pay.
class _ReceiptSheet extends StatelessWidget {
  final String groupName;
  final double amount;
  final String ref;
  final String pin;
  final String transferOrderId;
  final String method;

  const _ReceiptSheet({
    required this.groupName,
    required this.amount,
    required this.ref,
    required this.pin,
    required this.transferOrderId,
    required this.method,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 12),
          Text('Payment received',
              style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text)),
          const SizedBox(height: 4),
          Text(
            'Ksh ${amount.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} · $groupName',
            style: GoogleFonts.inter(fontSize: 15, color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _row('Method', method),
                _row('Receipt ref', ref),
                _row('Proof PIN', pin),
                _row('LOOP order', transferOrderId),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.sms_rounded, size: 15, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SMS receipt sent to your phone — keep it as your proof.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Done',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12.5, color: AppColors.muted)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
        ],
      ),
    );
  }
}