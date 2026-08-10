import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/hive_service.dart';
import '../services/api_service.dart';
import 'member_list_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final staff = HiveService.getStaff();
    final wsId = staff?['workspace']?['id'];
    if (wsId != null) {
      try {
        final stats = await ApiService.fetchStats(wsId);
        setState(() => _stats = stats);
      } catch (e) {}
    }
    setState(() {
      _pendingCount = HiveService.pendingCount();
      _loading = false;
    });
  }

  Future<void> _sync() async {
    setState(() => _loading = true);
    final synced = await ApiService.syncPending();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$synced events synced', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    await _loadData();
  }

  Future<void> _logout() async {
    await HiveService.clearAuth();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = HiveService.getStaff();
    final ws = staff?['workspace'];

    return Scaffold(
      appBar: AppBar(
        title: Text(ws?['name'] ?? 'TapVerify'),
        actions: [
          if (_pendingCount > 0)
            GestureDetector(
              onTap: _sync,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sync, size: 16),
                    const SizedBox(width: 4),
                    Text('$_pendingCount', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
        : RefreshIndicator(
            onRefresh: _loadData,
            color: const Color(0xFF059669),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Stats Grid
                  Row(
                    children: [
                      _StatCard(
                        label: 'Today',
                        value: _stats?['today']?['collections']?.toString() ?? '0',
                        subtitle: 'Ksh ${_stats?['today']?['revenue'] ?? 0}',
                        icon: Icons.today_rounded,
                        color: const Color(0xFF059669),
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'This Week',
                        value: _stats?['this_week']?['collections']?.toString() ?? '0',
                        subtitle: 'Ksh ${_stats?['this_week']?['revenue'] ?? 0}',
                        icon: Icons.date_range_rounded,
                        color: const Color(0xFFD97706),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatCard(
                        label: 'Members',
                        value: _stats?['total_members']?.toString() ?? '0',
                        subtitle: 'Active',
                        icon: Icons.groups_rounded,
                        color: const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Pending',
                        value: 'Ksh ${_stats?['pending_balance'] ?? 0}',
                        subtitle: 'Due',
                        icon: Icons.pending_actions_rounded,
                        color: const Color(0xFFDC2626),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Collect Payment Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF047857)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MemberListScreen()),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.8), size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Recent Activity
                  if (_stats?['recent_events'] != null) ...[
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Recent Activity',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0f172a),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...(_stats!['recent_events'] as List).take(5).map((e) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF059669).withOpacity(0.1),
                          child: Text(
                            (e['member_name'] ?? '?')[0].toUpperCase(),
                            style: GoogleFonts.inter(
                              color: const Color(0xFF059669),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          e['member_name'] ?? 'Unknown',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${e['event_type']?.toString().replaceAll('_', ' ')}',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Ksh ${e['amount']}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ),
                      ),
                    )),
                  ],
                ],
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
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 8),
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
