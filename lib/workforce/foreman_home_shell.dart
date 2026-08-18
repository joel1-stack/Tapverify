import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_service.dart';
import 'foreman_dashboard_screen.dart';
import 'collections_screen.dart';
import 'workers_screen.dart';
import 'workforce_more_screen.dart';
import 'workforce_login_screen.dart';

/// Foreman bottom-nav shell: Dashboard / Collections / Workers / More.
class ForemanHomeShell extends StatefulWidget {
  const ForemanHomeShell({super.key});

  @override
  State<ForemanHomeShell> createState() => _ForemanHomeShellState();
}

class _ForemanHomeShellState extends State<ForemanHomeShell> {
  int _index = 0;
  final _dashKey = GlobalKey<ForemanDashboardState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'Open menu',
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
            if (_index == 0)
              Text(
                WorkforceService.orgName,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_rounded),
            tooltip: 'Payment QR (proof)',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Proof console lives in More',
                      style: GoogleFonts.inter()),
                  backgroundColor: AppColors.accent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: _drawer(),
      body: IndexedStack(
        index: _index,
        children: [
          ForemanDashboardScreen(key: _dashKey),
          const CollectionsScreen(),
          const WorkersScreen(),
          const WorkforceMoreScreen(),
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
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon:
                  Icon(Icons.dashboard_rounded, color: AppColors.primary),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon:
                  Icon(Icons.receipt_long_rounded, color: AppColors.primary),
              label: 'Collections',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon:
                  Icon(Icons.people_rounded, color: AppColors.primary),
              label: 'Workers',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz_rounded),
              selectedIcon: Icon(Icons.more_horiz, color: AppColors.primary),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }

  static const _titles = ['Dashboard', 'Collections', 'Workers', 'More'];

  Widget _drawer() {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
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
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 120,
                    child: Image.asset(AppAssets.logoFull,
                        fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    WorkforceService.demoForemanName,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    WorkforceService.demoForemanPhone,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Foreman · ${WorkforceService.orgName}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _item(Icons.dashboard_rounded, 'Dashboard', 0),
                  _item(Icons.receipt_long_rounded, 'Collections', 1),
                  _item(Icons.people_rounded, 'Workers', 2),
                  _item(Icons.settings_rounded, 'More / Settings', 3),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _item(Icons.logout_rounded, 'Sign out', -1,
                      color: AppColors.danger),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'TapVerify Workforce v2.0.0',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deep,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, int index, {Color? color}) {
    final c = color ?? AppColors.text;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: c == AppColors.danger
                ? AppColors.danger.withOpacity(0.08)
                : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: c, size: 22),
        ),
        title: Text(label,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, fontSize: 14, color: c)),
        trailing: Icon(Icons.chevron_right_rounded,
            size: 18, color: c.withOpacity(0.3)),
        onTap: () {
          Navigator.pop(context);
          if (index < 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const WorkforceLoginScreen()),
              (route) => false,
            );
          } else {
            setState(() => _index = index);
          }
        },
      ),
    );
  }
}
