import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../services/demo_service.dart';
import '../services/hive_service.dart';
import 'home_shell.dart';
import 'member_home_screen.dart';
import 'login_screen.dart';

/// Web landing page shown when a desktop visitor is not logged in.
///
/// A pitch-style entry: the funeral → notebook → TapVerify → SACCO → loans
/// story, the two sides (board + member), the 8 LOOP APIs, and two one-tap
/// CTAs that seed the demo and drop straight into the app (treasurer or member).
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  bool _busy = false;

  static const _apis = [
    ('Mpesa Prompt', Icons.notifications_active_rounded),
    ('Pay to Till', Icons.storefront_rounded),
    ('Pay to Paybill', Icons.account_balance_wallet_rounded),
    ('Transaction Inquiry', Icons.fact_check_rounded),
    ('Transaction History', Icons.insert_drive_file_rounded),
    ('Send Money · M-Pesa', Icons.send_rounded),
    ('Send Money · Loop', Icons.account_balance_rounded),
    ('LOOP Prompt', Icons.swap_vert_rounded),
  ];

  Future<void> _enterTreasurer() async {
    setState(() => _busy = true);
    await DemoService.seed();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeShell(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _enterMember() async {
    setState(() => _busy = true);
    await DemoService.seed();
    await HiveService.saveMemberAuth(
      DemoService.memberDemoPhone,
      DemoService.memberDemoName,
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MemberHomeScreen(
          phone: DemoService.memberDemoPhone,
          name: DemoService.memberDemoName,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _goLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              _topBar(),
              _hero(),
              _story(),
              _twoSides(),
              _loopStrip(),
              _footer(),
            ],
          ),
          if (_busy)
            Container(
              color: Colors.black26,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.deep,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Image.asset(AppAssets.logoFull, fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Text('TapVerify',
              style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deep)),
          const Spacer(),
          TextButton(
            onPressed: _busy ? null : _goLogin,
            child: Text('Log in',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Text('LOOP HACKATHON · 8 APIs LIVE · OFFLINE-FIRST',
                style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Colors.white)),
          ),
          const SizedBox(height: 22),
          Text(
            'The notebook is dead.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 38,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'TapVerify turns funeral levies, church collections and chama savings into digital proof — receipts, ledgers and loan history nobody can dispute.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 15, height: 1.5, color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 26),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _busy ? null : _enterTreasurer,
                  icon: const Icon(Icons.dashboard_customize_rounded),
                  label: Text('Enter as Treasurer',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _busy ? null : _enterMember,
                  icon: const Icon(Icons.verified_user_rounded),
                  label: Text("I'm a Member",
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'One-tap demo · runs fully offline · no app to install',
            style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: AppColors.muted)),
      ),
    );
  }

  Widget _story() {
    const steps = [
      (
        '01 · FUNERAL',
        'Mama Jane dies. Her welfare group has 72 hours to raise Ksh 400,000 — 200 phone calls and a paper notebook.',
        Icons.local_hospital_rounded,
        AppColors.accent,
      ),
      (
        '02 · NOTEBOOK FAILS',
        '"Joel paid 500" gets lost, wet, or disputed. Treasurers are accused of theft. Groups fracture.',
        Icons.menu_book_rounded,
        AppColors.danger,
      ),
      (
        '03 · TAPVERIFY',
        'SMS prompts replace phone calls. Every shilling lands on a ledger with a PIN-protected receipt.',
        Icons.bolt_rounded,
        AppColors.primary,
      ),
      (
        '04 · LOANS',
        'Three years of verified history turns a welfare group into a SACCO that can offer members loans.',
        Icons.savings_rounded,
        const Color(0xFFC9A227),
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('FROM FUNERAL TO LOANS'),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardW = (constraints.maxWidth - 24) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: steps.map((s) {
                    return SizedBox(
                      width: cardW,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(s.$3, color: s.$4, size: 22),
                            const SizedBox(height: 8),
                            Text(s.$1,
                                style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: s.$4)),
                            const SizedBox(height: 4),
                            Text(s.$2,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: AppColors.text)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _twoSides() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('TWO SIDES, ONE LEDGER'),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _sideCard(
                  icon: Icons.dashboard_customize_rounded,
                  color: AppColors.primary,
                  title: 'Board & Treasurer',
                  lines: [
                    'Create a verified organization (KYC)',
                    'Add members — CSV, QR scan or manual',
                    'Collect via M-Pesa Till, Paybill or LOOP',
                    'Reconcile, disburse and export PDFs',
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _sideCard(
                  icon: Icons.phone_android_rounded,
                  color: AppColors.accent,
                  title: 'Members',
                  lines: [
                    'SMS payment links — no app to install',
                    'Belong to many groups at once',
                    'Pay via STK Push or the web',
                    'PIN-protected receipts with GPS proof',
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sideCard({
    required IconData icon,
    required Color color,
    required String title,
    required List<String> lines,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: color, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(line,
                        style: GoogleFonts.inter(
                            fontSize: 11.5, height: 1.35, color: AppColors.text)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _loopStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      color: const Color(0xFF1E1E1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text('POWERED BY 8 LOOP APIS',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _apis.map((a) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withOpacity(0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(a.$2, size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(a.$1,
                        style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            'Collect · Reconcile · Disburse · Future rail — with the LOOP orange that moves money in Kenya.',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.deep,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Image.asset(AppAssets.logoFull, fit: BoxFit.contain),
              ),
              const SizedBox(width: 8),
              Text('TapVerify',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800, color: AppColors.deep)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Proof of payment for Kenya\'s groups · 200+ member pilots in Kayole · Ksh 1,000–5,000/mo per org',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
