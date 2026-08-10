import 'package:flutter/material.dart';
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
      } catch (e) {
        // Use cached
      }
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
        SnackBar(content: Text('$synced events synced successfully')),
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
            Badge(
              label: Text('$_pendingCount'),
              child: IconButton(
                icon: const Icon(Icons.sync),
                onPressed: _sync,
              ),
            ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)))
        : RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _StatCard(
                        label: 'Today',
                        value: _stats?['today']?['collections']?.toString() ?? '0',
                        subtitle: 'Ksh ${_stats?['today']?['revenue']?.toString() ?? '0'}',
                        icon: Icons.today,
                        color: const Color(0xFF2D6A4F),
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'This Week',
                        value: _stats?['this_week']?['collections']?.toString() ?? '0',
                        subtitle: 'Ksh ${_stats?['this_week']?['revenue']?.toString() ?? '0'}',
                        icon: Icons.calendar_view_week,
                        color: const Color(0xFF8B6914),
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
                        icon: Icons.people,
                        color: const Color(0xFF1B4332),
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Pending',
                        value: _stats?['pending_balance']?.toString() ?? '0',
                        subtitle: 'Ksh due',
                        icon: Icons.pending_actions,
                        color: Colors.red.shade700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MemberListScreen()),
                    ),
                    icon: const Icon(Icons.add_circle, size: 28),
                    label: const Text('COLLECT PAYMENT', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: const Color(0xFF2D6A4F),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_stats?['recent_events'] != null) ...[
                    const Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...(_stats!['recent_events'] as List).take(5).map((e) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2D6A4F),
                          child: Text(e['member_name']?[0] ?? '?', style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(e['member_name'] ?? 'Unknown'),
                        subtitle: Text('${e['event_type']} • ${e['verification_method']}'),
                        trailing: Text('Ksh ${e['amount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  const _StatCard({required this.label, required this.value, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 6),
                  Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
