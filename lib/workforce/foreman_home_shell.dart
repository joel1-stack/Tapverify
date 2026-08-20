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
  final _scaffoldKey = GlobalKey<ScaffoldState>();

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
                  content: Text('Attestation & proof live in More',
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
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  Image.network(
                    AppImages.chamaMeeting,
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 190,
                      color: AppColors.deep,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 110,
                          child:
                              Image.asset(AppAssets.logoFull, fit: BoxFit.contain),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          WorkforceService.demoForemanName,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            shadows: [
                              const Shadow(
                                  color: Colors.black54, blurRadius: 8),
                              const Shadow(
                                  color: Colors.black38, offset: Offset(0, 2)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          WorkforceService.demoForemanPhone,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 6),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black38,
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _item(Icons.dashboard_rounded, 'Dashboard', 0),
                  _item(Icons.receipt_long_rounded, 'Collections', 1),
                  _item(Icons.people_rounded, 'Workers', 2),
                  _item(Icons.settings_rounded, 'More / Settings', 3),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _signOut(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.danger,
                        elevation: 0,
                        side: const BorderSide(color: AppColors.danger),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text(
                        'Sign out',
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TapVerify Workforce v2.0.0',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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

  void _signOut() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WorkforceLoginScreen()),
      (route) => false,
    );
  }

  Widget _item(IconData icon, String label, int index) {
    final active = _index == index;
    final c = active ? AppColors.primary : AppColors.text;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: active ? AppColors.primary.withOpacity(0.08) : null,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withOpacity(0.12)
                : AppColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              color: active ? AppColors.primary : AppColors.muted, size: 21),
        ),
        title: Text(label,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 14, color: c)),
        trailing: active
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.muted.withOpacity(0.4)),
        onTap: () {
          Navigator.pop(context);
          setState(() => _index = index);
        },
      ),
    );
  }
}
