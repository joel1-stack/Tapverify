import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_service.dart';
import '../workforce/workforce_models.dart';
import 'treasurer_dashboard_screen.dart';
import 'collections_screen.dart';
import 'members_screen.dart';
import 'workforce_more_screen.dart';
import 'workforce_login_screen.dart';
import 'notification_bell.dart';

/// 3-tab shell: Dashboard / Collections / Members.
/// Drawer holds: Settings, Sign out.
class TreasurerHomeShell extends StatefulWidget {
  const TreasurerHomeShell({super.key, this.user});

  final TapVerifyUser? user;

  @override
  State<TreasurerHomeShell> createState() => _TreasurerHomeShellState();
}

class _TreasurerHomeShellState extends State<TreasurerHomeShell> {
  int _index = 0;
  final _dashKey = GlobalKey<TreasurerDashboardState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  TapVerifyUser? get user => widget.user ?? WorkforceService.currentUser;

  String get _greeting {
    final u = user;
    if (u == null) return 'Dashboard';
    return 'Hi, ${u.name.split(' ').first}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_index == 0 ? _greeting : _titles[_index],
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
            if (_index == 0)
              Text(
                user != null ? '${user!.position} · ${user!.orgName}' : WorkforceService.orgName,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted),
              ),
          ],
        ),
        actions: [const NotificationBell(), const SizedBox(width: 4)],
      ),
      drawer: _drawer(),
      body: IndexedStack(
        index: _index,
        children: [
          TreasurerDashboardScreen(key: _dashKey),
          const CollectionsScreen(),
          const MembersScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primary.withOpacity(0.12),
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primary),
              label: 'Collections',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded, color: AppColors.primary),
              label: 'Members',
            ),
          ],
        ),
      ),
    );
  }

  static const _titles = ['Dashboard', 'Collections', 'Members'];

  Widget _drawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
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
                  Image.asset(AppAssets.logoFull, width: 100, fit: BoxFit.contain),
                  const SizedBox(height: 14),
                  Text(user?.name ?? 'Collector',
                      style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(user?.phone ?? '',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      '${user?.position ?? 'Treasurer'} · ${user?.orgName ?? WorkforceService.orgName}',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _drawerItem(Icons.settings_rounded, 'Settings', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkforceMoreScreen()));
            }),
            _drawerItem(Icons.info_outline_rounded, 'About TapVerify', () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'TapVerify',
                applicationVersion: '2.0.0',
                children: [Text('Group Collection Operating System', style: GoogleFonts.inter())],
              );
            }),
            const Spacer(),
            const Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const WorkforceLoginScreen()));
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text('Sign out', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.text, size: 22),
      title: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
