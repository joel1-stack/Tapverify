import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../models/member.dart';
import '../services/hive_service.dart';
import '../services/api_service.dart';
import '../services/contribution_service.dart';
import 'member_list_screen.dart';
import 'create_contribution_screen.dart';
import 'campaign_detail_screen.dart';
import 'member_payment_demo_screen.dart';
import 'payments_ledger_screen.dart';

/// Home tab — treasurer's landing page.
///
/// Loads workspace stats (today / week collections, member count, expected
/// monthly, outstanding balances) via [ApiService.fetchStats], renders stat
/// cards, recent events, a Collect Payment CTA plus quick actions for the
/// member payment demo and the payment export.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardState createState() => DashboardState();
}

class DashboardState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _loadData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void reload() {
    if (mounted) {
      setState(() => _loading = true);
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final wsId = HiveService.activeWorkspaceId;
    if (wsId != null) {
      try {
        final stats = await ApiService.fetchStats(wsId);
        setState(() => _stats = stats);
      } catch (e) {}
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final staff = HiveService.getStaff();
    final ws = HiveService.getActiveWorkspace();

    return _loading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary))
        : RefreshIndicator(
            onRefresh: _loadData,
            color: const Color(0xFF059669),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome Header with Illustration
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.deep,
                          AppColors.primary,
                          AppColors.primaryLight
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                staff?['name'] ?? 'Treasurer',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _pendingSync > 0
                                      ? AppColors.accent
                                      : Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _pendingSync > 0
                                          ? Icons.cloud_upload_rounded
                                          : Icons.cloud_done_rounded,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _pendingSync > 0
                                          ? '$_pendingSync to sync'
                                          : 'All synced',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 150,
                          height: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white.withOpacity(0.15),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            'https://images.pexels.com/photos/3184360/pexels-photo-3184360.jpeg?auto=compress&cs=tinysrgb&w=800',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Colors.white,
                                    size: 30),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Rails banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.asset(AppAssets.logoFull,
                              fit: BoxFit.contain),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ws?['name'] ?? 'Organization',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${ws?['type'] ?? ''} · ${_railsLabel(ws)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        if (ws?['contribution'] != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Ksh ${_fmt(ws?['contribution'])}',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary),
                              ),
                              Text('/ member/month',
                                  style: GoogleFonts.inter(
                                      fontSize: 10, color: AppColors.muted)),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Stats Grid
                  Row(
                    children: [
                      _StatCard(
                        label: 'Today',
                        value: 'Ksh ${_fmt(_stats?['today']?['revenue'] ?? 0)}',
                        subtitle: _stats?['today']?['subtitle'] ?? 'today',
                        icon: Icons.today_rounded,
                        color: const Color(0xFFC9A227),
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'This Week',
                        value:
                            'Ksh ${_fmt(_stats?['this_week']?['revenue'] ?? 0)}',
                        subtitle:
                            _stats?['this_week']?['subtitle'] ?? 'this week',
                        icon: Icons.date_range_rounded,
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatCard(
                        label: 'Members',
                        value:
                            '${_stats?['active_members'] ?? _stats?['total_members'] ?? 0}',
                        subtitle: 'Active',
                        icon: Icons.groups_rounded,
                        color: const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Pending',
                        value: 'Ksh ${_fmt(_stats?['pending_balance'] ?? 0)}',
                        subtitle: _stats?['pending_subtitle'] ?? 'Due',
                        icon: Icons.pending_actions_rounded,
                        color: AppColors.danger,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Collect Payment Button
                  ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: 1.03).animate(
                      CurvedAnimation(
                          parent: _pulseController, curve: Curves.easeInOut),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF047857)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  const MemberListScreen(),
                              transitionsBuilder: (_, animation, __, child) {
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(1, 0),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic)),
                                  child: child,
                                );
                              },
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 24),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: Colors.white,
                                      size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'COLLECT PAYMENT',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Tap to select a member',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: Colors.white.withOpacity(0.75),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Demo & Ledger quick actions
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.sms_rounded,
                          color: AppColors.accent,
                          title: 'Member payment demo',
                          subtitle: 'Watch this SMS → link → PIN → pay flow',
                          onTap: _openDemo,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.receipt_long_rounded,
                          color: const Color(0xFF2563EB),
                          title: 'Payments ledger',
                          subtitle: 'Every payment + ref, verify & export',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PaymentsLedgerScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Contributions / Collections section
                  Row(
                    children: [
                      Expanded(
                        child: Row(
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
                            Text(
                              'Contributions',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const CreateContributionScreen()),
                          );
                          if (mounted) setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text('NEW',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._campaignCards(),

                  const SizedBox(height: 28),

                  // Recent Activity
                  if (_stats?['recent_events'] != null) ...[
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
                          'Recent Activity',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...(_stats!['recent_events'] as List)
                        .take(5)
                        .map((e) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppColors.primary.withOpacity(0.1),
                                  child: Text(
                                    (e['member_name'] ?? '?')[0].toUpperCase(),
                                    style: GoogleFonts.inter(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  e['member_name'] ?? 'Unknown',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                ),
                                subtitle: Text(
                                  '${e['event_type']?.toString().replaceAll('_', ' ')}',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey.shade500),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Ksh ${e['amount']}',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            )),
                  ],
                ],
              ),
            ),
          );
  }

  void _openDemo() {
    final campaigns = ContributionService.campaigns();
    if (campaigns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Create a contribution first, then play the demo',
              style: GoogleFonts.inter()),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final ws = HiveService.getActiveWorkspace();
    final wsId = ws?['id'] ?? '';
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
        context,
        MaterialPageRoute(
          builder: (_) => MemberPaymentDemoScreen(campaign: c, member: member),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No members in this org yet', style: GoogleFonts.inter()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  int get _pendingSync => HiveService.pendingCount();

  List<Widget> _campaignCards() {
    final campaigns = ContributionService.campaigns();
    if (campaigns.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              const Icon(Icons.campaign_outlined,
                  color: AppColors.muted, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No contributions yet. Tap NEW to create one — members get notified instantly.',
                  style:
                      GoogleFonts.inter(fontSize: 12.5, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ];
    }
    return campaigns.reversed.map((c) {
      final amount = (c['amount'] as num? ?? 0).toDouble();
      final payments = List<Map<String, dynamic>>.from(c['payments'] ?? []);
      final collected = payments.fold(0.0, (s, p) => s + (p['paid'] as num));
      final members =
          HiveService.getMembersForWorkspace(c['workspace_id'] ?? '');
      final target = amount * members.length;
      final pct =
          target > 0 ? ((collected / target) * 100).clamp(0, 100) / 100 : 0.0;
      final fullPaid = members.where((m) {
        final found = payments.where((p) => p['member_id'] == m.id);
        return found.isNotEmpty &&
            found.fold(0.0, (s, p) => s + (p['paid'] as num)) >= amount;
      }).length;

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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CampaignDetailScreen(campaign: c)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.campaign_rounded,
                            color: AppColors.accent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['title'] ?? 'Contribution',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: AppColors.text)),
                            Text(
                              '${c['contrib_type'] ?? 'Regular'} · ${_dl(c)}',
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$fullPaid/${members.length} paid',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                          Text('Ksh ${_fmt(collected)}',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: AppColors.accent.withOpacity(0.1),
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  String _dl(Map c) {
    final d = DateTime.tryParse(c['deadline']?.toString() ?? '');
    if (d == null) return '';
    return 'Deadline ${d.day}/${d.month}/${d.year}';
  }

  String _railsLabel(Map? ws) {
    if (ws == null) return '';
    final rails = ws['rails'];
    if (rails is! Map) return 'LOOP';
    final parts = <String>[];
    if (rails['loop'] == true) parts.add('LOOP');
    if (rails['till'] == true) parts.add('Till');
    if (rails['paybill'] == true) parts.add('Paybill');
    if (rails['bank'] == true) parts.add('Bank');
    return parts.isEmpty ? 'LOOP' : parts.join(' · ');
  }

  String _fmt(dynamic value) {
    final n = value is num ? value : double.tryParse(value.toString()) ?? 0;
    return n.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 10),
                Text(title,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: AppColors.text)),
                const SizedBox(height: 3),
                Text(subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 10.5, color: AppColors.muted, height: 1.35)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
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
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                color: Colors.grey.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
