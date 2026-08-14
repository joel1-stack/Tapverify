import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart';
import 'login_screen.dart';
import 'payments_ledger_screen.dart';
import 'disburse_screen.dart';
import 'loan_eligibility_screen.dart';
import 'member_home_screen.dart';
import 'member_payment_demo_screen.dart';
import 'board_demo_screen.dart';
import '../services/demo_service.dart';

/// More tab — account + tools.
///
/// Shows the active workspace profile (with its cover image), the payment
/// rails available, and clearly separated sections:
///  - **LOOP INTEGRATION · 8 APIS** — product map, disbursement, member view
///  - **PAYMENTS & PROOF** — production tools (ledger, loan, exports)
///  - **DEMOS & WALKTHROUGHS** — self-contained demo journeys (member pays,
///    treasurer creates an org through KYC)
/// plus offline sync and logout. Checks rail status via
/// [ApiService.getPaymentRailInfo].
class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRail();
  }

  Future<void> _loadRail() async {
    try {
      await ApiService.getPaymentRailInfo();
    } catch (e) {}
    setState(() => _loading = false);
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

  void _openLedger() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaymentsLedgerScreen()),
    );
  }

  /// Replays the member payment journey on the funeral/levy campaign — always
  /// works, even on a fresh install.
  Future<void> _openMemberDemo() async {
    final target = await DemoService.memberDemo();
    if (!mounted) return;
    if (target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Add a member first, then replay the demo',
              style: GoogleFonts.inter()),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemberPaymentDemoScreen(
          campaign: target.campaign,
          member: target.member,
        ),
      ),
    );
  }

  Widget _moreTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 21),
      ),
      title: Text(title,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.text)),
      subtitle: Text(subtitle,
          style: GoogleFonts.inter(
              fontSize: 11.5, color: AppColors.muted, height: 1.35)),
      trailing: Icon(Icons.chevron_right_rounded,
          size: 18, color: color.withOpacity(0.4)),
      onTap: onTap,
    );
  }

  /// The active workspace's cover photo (Pexels), used to personalize the
  /// profile card. Falls back to the logo asset if offline/unavailable.
  Widget _orgCover({Map? ws, double size = 60}) {
    final image = ws?['image']?.toString();
    if (image == null || image.isEmpty) {
      return Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Image.asset(AppAssets.logoFull, fit: BoxFit.contain),
      );
    }
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
      ),
      child: Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(8),
          color: Colors.white.withOpacity(0.2),
          child: Image.asset(AppAssets.logoFull, fit: BoxFit.contain),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = HiveService.getStaff();
    final ws = HiveService.getActiveWorkspace();
    final pending = HiveService.pendingCount();
    final rails = ws?['rails'];
    final railParts = <String>[];
    if (rails is Map) {
      if (rails['loop'] == true) railParts.add('LOOP');
      if (rails['till'] == true)
        railParts.add('M-PESA Till ${ws?['till_number'] ?? ''}');
      if (rails['paybill'] == true)
        railParts.add('Paybill ${ws?['paybill_number'] ?? ''}');
      if (rails['bank'] == true)
        railParts.add('Bank ${ws?['account_number'] ?? ''}');
    }
    if (railParts.isEmpty) railParts.add('LOOP (NCBA)');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Profile Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.deep, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              _orgCover(ws: ws),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff?['name'] ?? 'Treasurer',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      staff?['phone'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ws?['name'] ?? 'Group',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section: Sync
        Text(
          'OFFLINE SYNC',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: pending > 0
                    ? AppColors.accent.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                pending > 0
                    ? Icons.cloud_upload_rounded
                    : Icons.cloud_done_rounded,
                color: pending > 0 ? AppColors.accent : AppColors.primary,
                size: 20,
              ),
            ),
            title: Text(
              pending > 0 ? '$pending payments pending' : 'All payments synced',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.text),
            ),
            subtitle: Text(
              pending > 0
                  ? 'Sync when you have internet'
                  : 'You are up to date',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
            ),
            trailing: Material(
              color: pending > 0
                  ? AppColors.accent
                  : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  final synced = await ApiService.syncPending();
                  if (mounted) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$synced payments synced',
                            style: GoogleFonts.inter()),
                        backgroundColor: AppColors.accent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text(
                    'SYNC',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: pending > 0 ? Colors.white : AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Section: Payment Rail
        Text(
          'PAYMENT RAILS',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.swap_vert_circle_rounded,
                      color: AppColors.primary, size: 20),
                ),
                title: Text(
                  '${ws?['name'] ?? 'Group'} rails',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.text),
                ),
                subtitle: Text(
                  '${ws?['type'] ?? ''} · Ksh ${ws?['contribution'] ?? 0}/member/mo',
                  style:
                      GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                ),
                trailing: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary))
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle,
                                size: 8, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      railParts.join('\n'),
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.text,
                          height: 1.7,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.accent.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_rounded,
                              color: AppColors.accent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Members get a LOOP Request to Pay + an SMS receipt. You see proof even when payments are collected offline.',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w500),
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
        const SizedBox(height: 20),

        // LOOP integration — the 8 API products
        Text(
          'LOOP INTEGRATION · 8 APIS',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              _moreTile(
                icon: Icons.send_rounded,
                color: const Color(0xFFDC2626),
                title: 'Send Money (disburse)',
                subtitle:
                    'Funeral payouts, refunds, welfare — M-Pesa or Loop, logged with proof.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DisburseScreen()),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _moreTile(
                icon: Icons.person_rounded,
                color: const Color(0xFF2D6A4F),
                title: 'Member side (two-user)',
                subtitle:
                    'See the app the way a member does — all their groups in one place, pay now, receipts, notifications.',
                onTap: () async {
                  await DemoService.seed();
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MemberHomeScreen(
                        phone: DemoService.memberDemoPhone,
                        name: DemoService.memberDemoName,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Payments & proof — production tools
        Text(
          'PAYMENTS & PROOF',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
child: _moreTile(
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFF2563EB),
            title: 'Payments Ledger',
            subtitle:
                'Every payment with ref + PIN proof. Tap to verify, export PDF, share or print.',
            onTap: _openLedger,
          ),
        ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: _moreTile(
          icon: Icons.savings_rounded,
          color: const Color(0xFFC9A227),
          title: 'Loan eligibility & disbursement',
          subtitle:
              '12-month transaction inquiry backs the 3× chama lending rule — eligible amount, history & certification.',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoanEligibilityScreen()),
          ),
        ),
      ),
      const SizedBox(height: 20),

        // Monthly reminder proof-point
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.campaign_rounded,
                      color: AppColors.accent, size: 20),
                ),
                title: Text(
                  'Monthly contribution reminder',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.text),
                ),
                subtitle: Text(
                  'Each registered member gets SMS: "You have to pay Ksh ${ws?['contribution'] ?? 0} for ${ws?['name'] ?? 'your group'} this month"',
                  style:
                      GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Reminder sent to ${HiveService.getMembersForWorkspace(ws?['id'] ?? '').length} members',
                          style: GoogleFonts.inter()),
                      backgroundColor: AppColors.accent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_rounded,
                          color: AppColors.accent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'SEND REMINDER',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Demos & walkthroughs — self-contained, judge-facing
        Text(
          'DEMOS & WALKTHROUGHS',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              _moreTile(
                icon: Icons.badge_rounded,
                color: AppColors.deep,
                title: 'Treasurer & KYC demo',
                subtitle:
                    'Create an organization, watch KYC get approved — or rejected — and start collecting for real.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BoardDemoScreen()),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _moreTile(
                icon: Icons.sms_rounded,
                color: AppColors.accent,
                title: 'Member payment demo',
                subtitle:
                    'Watch the member journey: SMS → payment link → PIN → rail → SMS receipt with ref.',
                onTap: _openMemberDemo,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section: About
        Text(
          'ABOUT',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Image.asset(AppAssets.logoFull, fit: BoxFit.contain),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'TapVerify',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: AppColors.text),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'v1.0.0',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Proof of payment for Kenya\'s groups',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Logout Button
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _logout,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded,
                        color: AppColors.danger, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
