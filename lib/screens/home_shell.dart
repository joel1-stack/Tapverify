import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../services/hive_service.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'member_list_screen.dart';
import 'activity_screen.dart';
import 'more_screen.dart';
import 'login_screen.dart';
import 'create_organization_screen.dart';

/// Bottom-navigation shell holding the four main tabs.
///
/// Home / Members / Activity / More. Owns the offline-sync action (uploads the
/// [PendingEvent] queue via [ApiService.syncPending]), shows the pending-count
/// badge on the sync icon and handles logout.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  int _pendingCount = 0;
  final _dashKey = GlobalKey<DashboardState>();

  late final List<Widget> _screens = [
    DashboardScreen(key: _dashKey),
    const MemberListScreen(embedded: true),
    const ActivityScreen(),
    const MoreScreen(),
  ];

  static const _titles = ['Home', 'Members', 'Activity', 'More'];

  @override
  void initState() {
    super.initState();
    _refreshPending();
  }

  void _refreshPending() {
    setState(() => _pendingCount = HiveService.pendingCount());
  }

  Future<void> _sync() async {
    setState(() => _pendingCount = 0);
    final synced = await ApiService.syncPending();
    if (mounted) {
      _refreshPending();
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
  }

  Future<void> _logout() async {
    await HiveService.clearAuth();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = HiveService.getStaff();
    final ws = HiveService.getActiveWorkspace();
    final name = staff?['name'] ?? 'Treasurer';
    final phone = staff?['phone'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Open menu',
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _titles[_index],
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            if (_index == 0 && ws != null)
              Text(
                ws['name'] ?? '',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
          ],
        ),
        actions: [
          if (_pendingCount > 0)
            GestureDetector(
              onTap: _sync,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sync, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '$_pendingCount',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: _buildDrawer(context,
          name: name, phone: phone, wsName: ws?['name'] ?? 'Group', ws: ws),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primary.withOpacity(0.12),
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon:
                  const Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.people_outline_rounded),
              selectedIcon:
                  const Icon(Icons.people_rounded, color: AppColors.primary),
              label: 'Members',
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long_rounded,
                  color: AppColors.primary),
              label: 'Activity',
            ),
            NavigationDestination(
              icon: const Icon(Icons.more_horiz_rounded),
              selectedIcon:
                  const Icon(Icons.more_horiz, color: AppColors.primary),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context,
      {required String name,
      required String phone,
      required String wsName,
      Map? ws}) {
    final wsCover = ws?['image']?.toString();
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.deep, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 60,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                    child: wsCover == null || wsCover.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(6),
                            child: Image.asset(
                              AppAssets.logoFull,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Image.network(
                            wsCover,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Padding(
                              padding: const EdgeInsets.all(6),
                              child: Image.asset(
                                AppAssets.logoFull,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.groups_rounded,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          wsName,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Sync badge row
            if (_pendingCount > 0)
              GestureDetector(
                onTap: _sync,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_upload_rounded,
                          color: AppColors.accent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$_pendingCount payments waiting to sync. Tap to sync now.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Organizations list
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MY ORGANIZATIONS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...HiveService.getMyWorkspaces().map((w) {
                    final active = w['id'] == HiveService.activeWorkspaceId;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                              color: active
                                  ? AppColors.primary
                                  : AppColors.border),
                        ),
                        child: Icon(Icons.groups_rounded,
                            size: 19,
                            color: active ? Colors.white : AppColors.muted),
                      ),
                      title: Text(
                        w['name'] ?? 'Unnamed',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: active ? AppColors.primary : AppColors.text,
                        ),
                      ),
                      subtitle: Text(
                        '${w['type'] ?? 'Group'} · Ksh ${w['contribution'] ?? 0}/mo',
                        style: GoogleFonts.inter(
                            fontSize: 10.5, color: AppColors.muted),
                      ),
                      trailing: active
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary, size: 18)
                          : const Icon(Icons.chevron_right_rounded,
                              size: 18, color: AppColors.muted),
                      onTap: () => _switchWorkspace(w['id']),
                    );
                  }),
                  const Divider(height: 1),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.add_business_rounded,
                          color: AppColors.accent, size: 20),
                    ),
                    title: Text(
                      'Create new organization',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent),
                    ),
                    onTap: _createOrganization,
                  ),
                ],
              ),
            ),
            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    onTap: () => _go(0),
                  ),
                  _drawerItem(
                    icon: Icons.people_rounded,
                    label: 'Members',
                    onTap: () => _go(1),
                  ),
                  _drawerItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Activity',
                    onTap: () => _go(2),
                  ),
                  _drawerItem(
                    icon: Icons.settings_rounded,
                    label: 'More / Settings',
                    onTap: () => _go(3),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _drawerItem(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    onTap: _logout,
                    color: AppColors.danger,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Image.asset(AppAssets.logoFull,
                            fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'TapVerify v1.0.0',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deep,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Proof of Payment \u00b7 Made for Kenya\u2019s groups',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _go(int index) {
    Navigator.pop(context);
    setState(() => _index = index);
  }

  Future<void> _switchWorkspace(String id) async {
    Navigator.pop(context);
    await HiveService.setActiveWorkspace(id);
    if (mounted) setState(() {});
    _dashKey.currentState?.reload();
  }

  void _createOrganization() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateOrganizationScreen()),
    ).then((_) {
      if (mounted) setState(() {});
      _dashKey.currentState?.reload();
    });
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppColors.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color == AppColors.danger
                ? AppColors.danger.withOpacity(0.08)
                : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(label,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, fontSize: 14, color: color)),
        trailing: Icon(Icons.chevron_right_rounded,
            size: 18, color: color.withOpacity(0.3)),
        onTap: onTap,
      ),
    );
  }
}
