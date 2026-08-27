import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'treasurer_dashboard_screen.dart';
import 'collections_screen.dart';
import 'members_screen.dart';
import 'workforce_login_screen.dart';
import 'revenue_report_screen.dart';
import 'credit_profile_screen.dart';
import 'evidence_console_screen.dart';
import 'bulk_sms_screen.dart';

/// 3-tab shell: Dashboard / Orders / Customers.
class TreasurerHomeShell extends StatefulWidget {
  const TreasurerHomeShell({super.key});
  @override
  State<TreasurerHomeShell> createState() => _TreasurerHomeShellState();
}

class _TreasurerHomeShellState extends State<TreasurerHomeShell> {
  int _index = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _pages = const [
    TreasurerDashboardScreen(),
    CollectionsScreen(),
    MembersScreen(),
  ];

  static const _titles = ['Dashboard', 'Orders', 'Customers'];

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
        title: Text(
          _titles[_index],
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      drawer: _drawer(),
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
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primary),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded, color: AppColors.primary),
              label: 'Customers',
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawer() {
    return Drawer(
      backgroundColor: Colors.white,
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
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text('TV',
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text("Peter's Metal Works",
                      style: GoogleFonts.inter(
                          fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Kariobangi, Nairobi',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                    child: Text('Manufacturer · Treasurer',
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Revenue tools
            _drawerItem(Icons.bar_chart_rounded, 'Revenue Report', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RevenueReportScreen()));
            }),
            _drawerItem(Icons.credit_score_rounded, 'Credit Profile', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CreditProfileScreen()));
            }),
            _drawerItem(Icons.verified_rounded, 'Evidence Console', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EvidenceConsoleScreen()));
            }),
            _drawerItem(Icons.sms_rounded, 'Bulk SMS', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const BulkSmsScreen()));
            }),
            _drawerItem(Icons.settings_rounded, 'Settings', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const _SettingsScreen()));
            }),

            const Spacer(),
            const Divider(color: AppColors.border, height: 1),

            // Logout
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text('Sign out',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign out?',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
        content: Text('You will be redirected to the login screen.',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.muted, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WorkforceLoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Sign out',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.text, size: 22),
      title: Text(label,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing:
          const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

/// Settings page — tappable rows with navigation.
class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text('Settings',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section('BUSINESS'),
          const SizedBox(height: 8),
          _actionRow(Icons.business_rounded, 'Business name', "Peter's Metal Works", onTap: () {
            _showEditDialog(context, 'Business name', "Peter's Metal Works");
          }),
          _actionRow(Icons.location_on_rounded, 'Location', 'Kariobangi, Nairobi', onTap: () {
            _showEditDialog(context, 'Location', 'Kariobangi, Nairobi');
          }),
          _actionRow(Icons.category_rounded, 'Type', 'Manufacturer', onTap: () {
            _showEditDialog(context, 'Business type', 'Manufacturer');
          }),
          const SizedBox(height: 24),
          _section('ACCOUNT'),
          const SizedBox(height: 8),
          _actionRow(Icons.person_outline_rounded, 'Name', 'Peter Kaunda', onTap: () {
            _showEditDialog(context, 'Name', 'Peter Kaunda');
          }),
          _actionRow(Icons.phone_rounded, 'Phone', '0715 641 339', onTap: () {
            _showEditDialog(context, 'Phone', '0715 641 339');
          }),
          _actionRow(Icons.lock_outline_rounded, 'PIN', 'Change PIN', onTap: () {
            _showChangePinDialog(context);
          }),
          const SizedBox(height: 24),
          _section('PAYMENT'),
          const SizedBox(height: 8),
          _actionRow(Icons.link_rounded, 'SasaPay Merchant', '600980', onTap: () {
            _showEditDialog(context, 'SasaPay Merchant ID', '600980');
          }),
          _actionRow(Icons.storefront_rounded, 'Checkout mode', 'Sandbox', onTap: () {}),
          const SizedBox(height: 24),
          _section('NOTIFICATIONS'),
          const SizedBox(height: 8),
          _actionRow(Icons.sms_rounded, 'AT Bulk SMS', 'Active', onTap: () {}),
          _actionRow(Icons.phone_in_talk_rounded, 'AT USSD', '*384*123#', onTap: () {}),
          _actionRow(Icons.card_giftcard_rounded, 'AT Airtime rewards', 'Active', onTap: () {}),
          const SizedBox(height: 24),
          _section('ABOUT'),
          const SizedBox(height: 8),
          _actionRow(Icons.info_outline_rounded, 'Version', '2.0.0', onTap: () {}),
          _actionRow(Icons.description_rounded, 'Terms', 'View terms', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const _TermsScreen()));
          }),
          _actionRow(Icons.privacy_tip_rounded, 'Privacy', 'View privacy policy', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const _PrivacyScreen()));
          }),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Text(title,
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w800,
            color: AppColors.muted, letterSpacing: 0.6));
  }

  Widget _actionRow(IconData icon, String title, String value, {VoidCallback? onTap}) {
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
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, String title, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit $title',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog(BuildContext context) {
    final currentPin = TextEditingController();
    final newPin = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Change PIN',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPin,
              obscureText: true,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Current PIN',
                labelStyle: GoogleFonts.inter(fontSize: 13),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPin,
              obscureText: true,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'New PIN',
                labelStyle: GoogleFonts.inter(fontSize: 13),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Update', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _TermsScreen extends StatelessWidget {
  const _TermsScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text('Terms of Service',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Terms of Service',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 16),
          Text(
            'By using TapVerify you agree that all payment data is verified via SasaPay webhooks and Africa\'s Talking SMS. Revenue proof is generated from verified transaction hashes. Your data is encrypted with AES-256.',
            style: GoogleFonts.inter(fontSize: 15, height: 1.6, color: AppColors.text),
          ),
          const SizedBox(height: 20),
          Text(
            '1. Payment Verification\n'
            'All payment data processed through TapVerify is verified via SasaPay webhooks and Africa\'s Talking SMS notifications. We do not store raw payment credentials.',
            style: GoogleFonts.inter(fontSize: 14, height: 1.6, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Text(
            '2. Revenue Proof\n'
            'Revenue proof is generated from verified transaction hashes. Each proof is cryptographically linked to the original verified transaction.',
            style: GoogleFonts.inter(fontSize: 14, height: 1.6, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Text(
            '3. Data Security\n'
            'Your data is encrypted with AES-256 encryption. We employ industry-standard security measures to protect your information.',
            style: GoogleFonts.inter(fontSize: 14, height: 1.6, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Text(
            '4. Service Availability\n'
            'TapVerify relies on third-party services (SasaPay, Africa\'s Talking, Avalanche) for payment verification and attestation. Service availability depends on these providers.',
            style: GoogleFonts.inter(fontSize: 14, height: 1.6, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _PrivacyScreen extends StatelessWidget {
  const _PrivacyScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text('Privacy Policy',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Privacy Policy',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 16),
          Text(
            'TapVerify collects phone numbers, business names, and payment records to generate verified revenue history. We use SasaPay for payment verification, Africa\'s Talking for SMS/USSD/airtime, and Avalanche for on-chain attestation. We never sell your data.',
            style: GoogleFonts.inter(fontSize: 15, height: 1.6, color: AppColors.text),
          ),
          const SizedBox(height: 20),
          Text(
            '1. Data We Collect\n'
            '• Phone numbers for account verification\n'
            '• Business names for organization identification\n'
            '• Payment records for revenue proof generation',
            style: GoogleFonts.inter(fontSize: 14, height: 1.6, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Text(
            '2. How We Use Your Data\n'
            'We use SasaPay for payment verification, Africa\'s Talking for SMS, USSD, and airtime services, and Avalanche blockchain for on-chain attestation of revenue proofs.',
            style: GoogleFonts.inter(fontSize: 14, height: 1.6, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Text(
            '3. Data Sharing\n'
            'We never sell your data to third parties. Data is only shared with the third-party services listed above for the purpose of providing TapVerify\'s core functionality.',
            style: GoogleFonts.inter(fontSize: 14, height: 1.6, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Text(
            '4. Data Security\n'
            'All data is encrypted using AES-256 encryption. We implement strict access controls and regular security audits.',
            style: GoogleFonts.inter(fontSize: 14, height: 1.6, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
