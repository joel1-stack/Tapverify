import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'home_screen.dart';
import 'proof_screen.dart';
import 'collect_screen.dart';
import 'workforce_login_screen.dart';

class TreasurerHomeShell extends StatefulWidget {
  const TreasurerHomeShell({super.key});
  @override
  State<TreasurerHomeShell> createState() => _TreasurerHomeShellState();
}

class _TreasurerHomeShellState extends State<TreasurerHomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: IndexedStack(
        index: _index,
        children: [
          SafeArea(child: HomeScreen()),
          SafeArea(child: ProofScreen()),
          SafeArea(child: const _MeScreen()),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, 'Home'),
                _navItem(1, Icons.verified_user_rounded, 'Proof'),
                _navItem(2, Icons.person_rounded, 'Me'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              elevation: 4,
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CollectScreen())),
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
    );
  }

  Widget _navItem(int i, IconData icon, String label) {
    final selected = _index == i;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _index = i);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: selected ? AppColors.primary : AppColors.muted),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.primary : AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _MeScreen extends StatelessWidget {
  const _MeScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          // Profile card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.deep, AppColors.primary]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text('PK',
                        style: GoogleFonts.inter(
                            fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Peter Kaunda',
                    style: GoogleFonts.inter(
                        fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
                const SizedBox(height: 4),
                Text('Treasurer · Kamau Welfare',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text('12 collections in a row',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text('🏅 Trusted Treasurer',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gold)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Settings
          Text('SETTINGS',
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: AppColors.muted, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          _settingRow(Icons.group_rounded, 'Group name', 'Kamau Welfare'),
          _settingRow(Icons.phone_rounded, 'Phone', '0715 641 339'),
          _settingRow(Icons.lock_outline_rounded, 'Change PIN', null),
          _settingRow(Icons.help_outline_rounded, 'Help', null),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WorkforceLoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text('LOG OUT',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.danger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingRow(IconData icon, String title, String? value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.muted),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
          ),
          if (value != null) ...[
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted)),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
        ],
      ),
    );
  }
}
