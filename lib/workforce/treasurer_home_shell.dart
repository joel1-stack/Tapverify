import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'home_screen.dart';
import 'proof_screen.dart';
import 'collect_screen.dart';
import 'workforce_login_screen.dart';

/// 3-tab shell: Home / Proof / Me
class TreasurerHomeShell extends StatefulWidget {
  const TreasurerHomeShell({super.key});
  @override
  State<TreasurerHomeShell> createState() => _TreasurerHomeShellState();
}

class _TreasurerHomeShellState extends State<TreasurerHomeShell> {
  int _index = 0;
  final _pages = const [
    HomeScreen(),
    ProofScreen(),
    _MeScreen(),
  ];

  static const _titles = ['Home', 'Proof', 'Me'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text(
          _titles[_index],
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        actions: [
          if (_index == 0) ...[
            IconButton(
              icon: const Icon(Icons.add_rounded, size: 26),
              color: AppColors.primary,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CollectScreen()),
              ),
            ),
          ],
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
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
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.verified_user_outlined),
              selectedIcon: Icon(Icons.verified_user_rounded, color: AppColors.primary),
              label: 'Proof',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Me',
            ),
          ],
        ),
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CollectScreen()),
              ),
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
    );
  }
}

/// Me page - Profile & Settings
class _MeScreen extends StatelessWidget {
  const _MeScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text('Me',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.deep, AppColors.primary]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text('PM',
                        style: GoogleFonts.inter(
                            fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Peter Kaunda',
                    style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
                const SizedBox(height: 4),
                Text('Treasurer · Kamau Welfare',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.muted)),
                const SizedBox(height: 16),
                // Streak
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🔥', style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text('12 collections in a row',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('🏅 Trusted Treasurer',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gold)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Settings
          Text('SETTINGS',
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: AppColors.muted, letterSpacing: 0.6)),
          const SizedBox(height: 8),

          _settingRow(Icons.group_rounded, 'Group name', 'Kamau Welfare'),
          _settingRow(Icons.phone_rounded, 'Phone', '0715 641 339'),
          _settingRow(Icons.lock_outline_rounded, 'Change PIN', null, onTap: () {}),
          _settingRow(Icons.help_outline_rounded, 'Help', null, onTap: () {}),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WorkforceLoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text('🚪 LOG OUT',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.danger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingRow(IconData icon, String title, String? value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
            ),
            if (value != null) ...[
              Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
