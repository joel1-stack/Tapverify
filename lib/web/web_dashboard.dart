import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../constants.dart';
import '../workforce/workforce_models.dart';
import '../workforce/workforce_service.dart';

class WebDashboard extends StatefulWidget {
  const WebDashboard({super.key});
  @override
  State<WebDashboard> createState() => _WebDashboardState();
}

class _WebDashboardState extends State<WebDashboard> {
  int _selectedNav = 0;
  WfCollection? _selectedOrder;

  static const _navItems = [
    _NavItem(Icons.dashboard_rounded, 'Dashboard'),
    _NavItem(Icons.add_circle_rounded, 'New Order'),
    _NavItem(Icons.receipt_long_rounded, 'Orders'),
    _NavItem(Icons.people_rounded, 'Customers'),
    _NavItem(Icons.bar_chart_rounded, 'Revenue'),
    _NavItem(Icons.shield_rounded, 'Credit Profile'),
    _NavItem(Icons.phone_android_rounded, 'USSD Simulator'),
    _NavItem(Icons.sms_rounded, 'Bulk SMS'),
    _NavItem(Icons.emoji_events_rounded, 'Badges'),
    _NavItem(Icons.verified_rounded, 'Evidence Console'),
    _NavItem(Icons.settings_rounded, 'Settings'),
  ];

  static const _titles = [
    'Dashboard', 'New Order', 'Orders', 'Customers', 'Revenue',
    'Credit Profile', 'USSD Simulator', 'Bulk SMS', 'My Badges',
    'Evidence Console', 'Settings',
  ];

  void _navigateTo(int index) {
    setState(() {
      _selectedNav = index;
      _selectedOrder = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final narrow = w < 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (!narrow)
            Container(
              width: 240,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Image.asset(AppAssets.logoFull, height: 32),
                  ),
                  const SizedBox(height: 30),
                  for (int i = 0; i < _navItems.length; i++)
                    _sidebarTile(i, _navItems[i]),
                  const Spacer(),
                  _sidebarSignOut(),
                  const SizedBox(height: 8),
                  _sidebarProfile(),
                ],
              ),
            ),
          Expanded(
            child: Column(
              children: [
                _topBar(narrow),
                const Divider(height: 1),
                Expanded(child: _body()),
              ],
            ),
          ),
        ],
      ),
      drawer: narrow ? _mobileDrawer() : null,
    );
  }

  Widget _sidebarTile(int i, _NavItem item) {
    final selected = i == _selectedNav;
    return ListTile(
      leading: Icon(item.icon, size: 20, color: selected ? Colors.white : Colors.white54),
      title: Text(item.label, style: GoogleFonts.inter(
          fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          color: selected ? Colors.white : Colors.white54)),
      selected: selected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: () => _navigateTo(i),
    );
  }

  Widget _sidebarSignOut() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 42,
        child: OutlinedButton.icon(
          onPressed: () => _showLogoutDialog(context),
          icon: const Icon(Icons.logout_rounded, size: 16),
          label: Text('Sign out',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }

  Widget _sidebarProfile() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: const Icon(Icons.person_rounded, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Peter Kaunda', style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                Row(
                  children: [
                    Container(
                      width: 5, height: 5,
                      decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text('Business Owner', style: GoogleFonts.inter(
                        fontSize: 9, color: Colors.white54)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign out?',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
        content: Text('You will be redirected to the login screen.',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.muted, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Sign out',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _topBar(bool narrow) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.white,
      child: Row(
        children: [
          if (narrow) ...[
            Builder(builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            )),
            const SizedBox(width: 8),
          ],
          Text(_titles[_selectedNav],
              style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.success, AppColors.success.withValues(alpha: 0.8)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('LIVE', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
            ]),
          ),
          const SizedBox(width: 16),
          Stack(
            children: [
              const Icon(Icons.notifications_rounded, size: 22, color: AppColors.muted),
              Positioned(
                right: 0, top: 0,
                child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_selectedOrder != null) return _orderDetailBody();
    switch (_selectedNav) {
      case 0: return _dashboardBody();
      case 1: return _newOrderBody();
      case 2: return _ordersBody();
      case 3: return _customersBody();
      case 4: return _revenueBody();
      case 5: return _creditBody();
      case 6: return _ussdBody();
      case 7: return _bulkSmsBody();
      case 8: return _badgesBody();
      case 9: return _evidenceConsoleBody();
      case 10: return _settingsBody();
      default: return _dashboardBody();
    }
  }

  Widget _mobileDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 40),
            for (int i = 0; i < _navItems.length; i++)
              _sidebarTile(i, _navItems[i]),
            const Spacer(),
            _sidebarSignOut(),
            const SizedBox(height: 8),
            _sidebarProfile(),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
    );
  }

  static String _fmt(num n) {
    final s = n.toStringAsFixed(n == n.roundToDouble() ? 0 : 2);
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }

  // ═══════════════════════════════════════
  // DASHBOARD — matches TreasurerDashboardScreen
  // ═══════════════════════════════════════
  Widget _dashboardBody() {
    final stats = WorkforceService.stats();
    final active = WorkforceService.activeCollections;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heroHeader(),
          const SizedBox(height: 16),
          Row(
            children: [
              _statCard(
                  'Ksh ${_fmt(stats['collected'])}',
                  'Verified revenue',
                  Icons.payments_rounded,
                  AppColors.primary),
              const SizedBox(width: 10),
              _statCard(
                  '${stats['totalTransactions']}',
                  'Verified transactions',
                  Icons.check_circle_rounded,
                  AppColors.success),
              const SizedBox(width: 10),
              _statCard(
                  '${(stats['consistency'] as double).toStringAsFixed(0)}%',
                  'Consistency',
                  Icons.speed_rounded,
                  AppColors.gold),
            ],
          ),
          const SizedBox(height: 16),
          _milestoneProgress(),
          const SizedBox(height: 12),
          _streakCard(),
          const SizedBox(height: 12),
          _trustScoreCard(),
          const SizedBox(height: 12),
          _lenderChecklist(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _quickAction(
                Icons.bar_chart_rounded, 'Revenue Report', 'Monthly breakdown', AppColors.primary,
                () => _navigateTo(4),
              )),
              const SizedBox(width: 10),
              Expanded(child: _quickAction(
                Icons.credit_score_rounded, 'Credit Profile', 'Lender-ready proof', AppColors.deep,
                () => _navigateTo(5),
              )),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _quickAction(
                Icons.emoji_events_rounded, 'My Badges', 'On-chain attestation', AppColors.gold,
                () => _navigateTo(8),
              )),
              const SizedBox(width: 10),
              Expanded(child: _quickAction(
                Icons.shield_rounded, 'Payer Score', 'Universal reputation', AppColors.success,
                () => _navigateTo(8),
              )),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('RECENT ORDERS',
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w800,
                      color: AppColors.muted, letterSpacing: 0.6)),
              const Spacer(),
              Text('${active.length}',
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          if (active.isEmpty)
            _emptyOrdersState()
          else
            ...active.take(4).map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _recentOrderCard(c),
                )),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => _navigateTo(1),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text('Record customer payment',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.deep, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text('PM',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Peter's Metal Works",
                        style: GoogleFonts.inter(
                            fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('Kariobangi, Nairobi',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text('CREDITWORTHY \u00b7 6 months verified',
                    style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }

  Widget _milestoneProgress() {
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
          Row(
            children: [
              Text('YOUR REVENUE JOURNEY', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.5)),
              const Spacer(),
              Text('\ud83d\udc8e Trusted', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.48,
              minHeight: 10,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Ksh 2.4M', style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
              Text(' / 5M', style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
              const Spacer(),
              Text('Ksh 2.6M to Champion', style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 4),
          Text('\ud83c\udfaf Next unlock: Credit Profile Export at Ksh 5M', style: GoogleFonts.inter(
              fontSize: 11, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _streakCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Text('\ud83d\udd25', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('12-Day Recording Streak', style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
                Text('Record payments every day to keep it alive', style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('RECORD: 18', style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.muted)),
              Text('\ud83c\udf81 Ksh 50 airtime at 15 days', style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trustScoreCard() {
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
          Row(
            children: [
              Text('TRUST SCORE', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.5)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('EXCELLENT', style: GoogleFonts.inter(
                    fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.success)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('87', style: GoogleFonts.inter(
                  fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.text)),
              Text(' / 100', style: GoogleFonts.inter(fontSize: 16, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _trustBar('Verification', '98%'),
              const SizedBox(width: 12),
              _trustBar('Response', '4.2h'),
              const SizedBox(width: 12),
              _trustBar('Growth', '+23%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trustBar(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.muted)),
          Text(value, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text)),
        ],
      ),
    );
  }

  Widget _lenderChecklist() {
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
          Row(
            children: [
              Icon(Icons.checklist_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('LENDER-READY CHECKLIST', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          _checkItem(true, 'Verified Ksh 100K+ revenue'),
          _checkItem(true, '30+ days of payment history'),
          _checkItem(true, 'Zero disputed payments'),
          _checkItem(false, '6-month consistency streak \u2014 2 months to go'),
          _checkItem(false, 'Connect SACCO account'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.celebration_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text('You are 2 checks away from a Lender-Ready Profile!', style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkItem(bool checked, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 18,
            color: checked ? AppColors.success : AppColors.muted,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: checked ? AppColors.text : AppColors.muted))),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
                  Text(subtitle,
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentOrderCard(WfCollection c) {
    final paid = c.paidCount;
    final total = c.tasks.length;
    final icons = [Icons.receipt_long_rounded, Icons.build_rounded, Icons.school_rounded, Icons.store_rounded];
    final iconIdx = c.id.hashCode % icons.length;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedOrder = c;
        _selectedNav = 2;
      }),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icons[iconIdx.abs()], size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.title,
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                  const SizedBox(height: 2),
                  Text('Ksh ${_fmt(c.amount)} \u00b7 $paid/$total paid',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _emptyOrdersState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_rounded, size: 36, color: AppColors.muted),
          const SizedBox(height: 10),
          Text('No orders yet',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 4),
          Text('Record a customer payment to get started.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // NEW ORDER — matches CreateCollectionScreen
  // ═══════════════════════════════════════
  Widget _newOrderBody() {
    return const _WebNewOrderBody();
  }

  // ═══════════════════════════════════════
  // ORDERS — matches CollectionsScreen
  // ═══════════════════════════════════════
  Widget _ordersBody() {
    final active = WorkforceService.activeCollections;
    final closed = WorkforceService.closedCollections;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (active.isEmpty && closed.isEmpty)
            _emptyOrdersState()
          else ...[
            ...active.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _orderCard(c),
                )),
            if (closed.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('ARCHIVED',
                  style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w800,
                      color: AppColors.muted, letterSpacing: 0.6)),
              const SizedBox(height: 8),
              ...closed.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _orderCard(c, archived: true),
                  )),
            ],
          ],
        ],
      ),
    );
  }

  Widget _orderCard(WfCollection c, {bool archived = false}) {
    final paid = c.paidCount;
    final total = c.tasks.length;
    final pct = total == 0 ? 0.0 : (paid / total) * 100;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedOrder = c;
      }),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: archived ? AppColors.border : AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: archived
                        ? AppColors.muted.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(c.type.toUpperCase(),
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w800,
                          color: archived ? AppColors.muted : AppColors.primary)),
                ),
                const Spacer(),
                if (archived)
                  Text('ARCHIVED',
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted))
                else
                  Text(
                    c.due.difference(DateTime.now()).inDays <= 0
                        ? 'Due today'
                        : '${c.due.difference(DateTime.now()).inDays} days',
                    style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(c.title,
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(height: 4),
            Text('Ksh ${_fmt(c.amount)} \u00b7 $paid/$total paid',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 5,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(
                    archived ? AppColors.muted : AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // ORDER DETAIL — matches CollectionDetailScreen
  // ═══════════════════════════════════════
  Widget _orderDetailBody() {
    final c = _selectedOrder!;
    final total = c.tasks.length;
    final paid = c.paidCount;
    final pct = total == 0 ? 0.0 : (paid / total) * 100;
    final daysLeft = c.due.difference(DateTime.now()).inDays;
    final paymentLink = 'https://pay.sasapay.app/checkout/${c.id}?amount=${c.amount.round()}&ref=${c.id}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _selectedOrder = null),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Back to Orders',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.deep, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(c.type.toUpperCase(),
                          style: GoogleFonts.inter(
                              fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                    const Spacer(),
                    Text(
                      daysLeft <= 0 ? 'Due today' : '$daysLeft days left',
                      style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Ksh ${_fmt(c.collected)} collected',
                    style: GoogleFonts.inter(
                        fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 4),
                Text('of Ksh ${_fmt(c.amount * total)} expected \u00b7 ${pct.toStringAsFixed(0)}% \u00b7 ${c.railName}',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primaryLight),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('PAYMENT LINK',
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: AppColors.muted, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(paymentLink,
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.primary, decoration: TextDecoration.underline)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: paymentLink));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Link copied', style: GoogleFonts.inter()),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ));
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: Text('Copy',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: Text('WhatsApp',
                            style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('CUSTOMERS \u00b7 $total',
                  style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w800,
                      color: AppColors.muted, letterSpacing: 0.6)),
              const Spacer(),
              Text('$paid paid',
                  style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 10),
          for (final t in c.tasks.values) ...[
            _customerDetailRow(t),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                for (final t in c.tasks.values) {
                  if (t.state.index < WfPaymentState.completed.index) {
                    WorkforceService.payNow(c, t.workerId);
                    WorkforceService.verify(c, t.workerId);
                    break;
                  }
                }
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.bolt_rounded, size: 18, color: Colors.white),
              label: Text('Simulate payment',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerDetailRow(WfPaymentTask t) {
    final paid = t.state.index >= WfPaymentState.completed.index;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: paid ? AppColors.success : AppColors.muted.withValues(alpha: 0.2),
            child: Icon(
              paid ? Icons.check_rounded : Icons.person_rounded,
              size: 16,
              color: paid ? Colors.white : AppColors.muted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer ${t.workerId}',
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                if (paid && t.txnRef.isNotEmpty)
                  Text(t.txnRef,
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (paid ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              paid ? 'PAID' : 'PENDING',
              style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w800,
                  color: paid ? AppColors.success : AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // CUSTOMERS — matches MembersScreen
  // ═══════════════════════════════════════
  Widget _customersBody() {
    return const _WebCustomersBody();
  }

  // ═══════════════════════════════════════
  // REVENUE — matches RevenueReportScreen
  // ═══════════════════════════════════════
  Widget _revenueBody() {
    final months = [
      ('Mar', 320000, 12), ('Apr', 380000, 14), ('May', 420000, 16),
      ('Jun', 480000, 18), ('Jul', 530000, 22), ('Aug', 270000, 8),
    ];
    final total = months.fold<int>(0, (s, m) => s + m.$2);
    final totalTxns = months.fold<int>(0, (s, m) => s + m.$3);
    final avg = total ~/ months.length;
    final maxVal = months.map((m) => m.$2).reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.deep, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Verified Revenue',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 4),
                Text('Ksh ${_fmt(total)}',
                    style: GoogleFonts.inter(
                        fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _pill('$totalTxns transactions'),
                    const SizedBox(width: 8),
                    _pill('6 months'),
                    const SizedBox(width: 8),
                    _pill('Avg Ksh ${_fmt(avg)}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('MONTHLY BREAKDOWN',
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w800,
                  color: AppColors.muted, letterSpacing: 0.6)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            height: 260,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < months.length; i++)
                  Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Ksh ${(months[i].$2 / 1000).round()}K',
                            style: GoogleFonts.inter(
                                fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted)),
                        const SizedBox(height: 4),
                        Container(
                          height: (months[i].$2 / maxVal) * 180,
                          decoration: BoxDecoration(
                            gradient: months[i].$2 == maxVal
                                ? const LinearGradient(colors: [AppColors.deep, AppColors.success])
                                : LinearGradient(colors: [
                                    AppColors.primary,
                                    AppColors.primary.withValues(alpha: 0.7)
                                  ]),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(months[i].$1,
                            style: GoogleFonts.inter(
                                fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted)),
                      ],
                    ),
                  )),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up_rounded, color: AppColors.success),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Revenue Trend: UP',
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.success)),
                      Text('Average monthly: Ksh ${_fmt(avg)}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share_rounded, size: 20),
              label: Text('Share as PDF',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }

  // ═══════════════════════════════════════
  // CREDIT PROFILE — matches CreditProfileScreen
  // ═══════════════════════════════════════
  Widget _creditBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF065F46), AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.verified_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text('CREDITWORTHY',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w800,
                            color: Colors.white, letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Verified Revenue (6 months)',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 4),
                Text('Ksh 2,350,000',
                    style: GoogleFonts.inter(
                        fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _creditMetric('Average Transaction', 'Ksh 49,000', Icons.receipt_rounded, AppColors.primary),
          const SizedBox(height: 10),
          _creditMetric('Total Transactions', '47 verified', Icons.check_circle_rounded, AppColors.success),
          const SizedBox(height: 10),
          _creditMetric('Consistency Score', '94%', Icons.speed_rounded, AppColors.gold),
          const SizedBox(height: 10),
          _creditMetric('Dispute Rate', '0%', Icons.shield_rounded, AppColors.success),
          const SizedBox(height: 10),
          _creditMetric('On-Time Payments', '96%', Icons.schedule_rounded, AppColors.primary),
          const SizedBox(height: 24),
          Text('VERIFICATION SOURCES',
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w800,
                  color: AppColors.muted, letterSpacing: 0.6)),
          const SizedBox(height: 12),
          _creditSource('SasaPay', 'OAuth2 + HMAC-SHA512 signed callbacks', true),
          const SizedBox(height: 8),
          _creditSource("Africa's Talking SMS", 'Customer receipts sent', true),
          const SizedBox(height: 8),
          _creditSource("Africa's Talking USSD", 'Feature-phone balance checks', true),
          const SizedBox(height: 8),
          _creditSource("Africa's Talking Airtime", 'Consistency rewards active', true),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              label: Text('Share Credit Profile',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _creditMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
          ),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text)),
        ],
      ),
    );
  }

  Widget _creditSource(String name, String detail, bool active) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 20,
            color: active ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                Text(detail,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // BADGES — matches BadgesScreen
  // ═══════════════════════════════════════
  Widget _badgesBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.deep, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text('UNIVERSAL PAYER SCORE', style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white60, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text('847 / 1000', style: GoogleFonts.inter(
                    fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Silver Payer II', style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white70)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: 0.847,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text('53 points to Gold Payer I', style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Text('\ud83d\udd25', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('6-Month Consistency Streak', style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
                      Text('You paid on time for 6 months straight', style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('ACTIVE', style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('BADGE COLLECTION', style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.6)),
          const SizedBox(height: 12),
          _badgeCard(
            emoji: '\ud83e\udd47', name: '6-Month Payer', tier: 'Silver',
            color: AppColors.gold, date: 'Minted: Aug 15, 2026',
            tx: '0x7e8b...c4d2', status: 'MINTED ON-CHAIN', verified: true,
          ),
          const SizedBox(height: 12),
          _badgeCard(
            emoji: '\ud83e\udd48', name: '3-Month Payer', tier: 'Bronze',
            color: AppColors.muted, date: 'Minted: May 15, 2026',
            tx: '0x3f2a...b91c', status: 'MINTED ON-CHAIN', verified: true,
          ),
          const SizedBox(height: 12),
          _badgeCard(
            emoji: '\u2b1c', name: '12-Month Payer', tier: 'Gold',
            color: AppColors.border, date: '6 months to unlock',
            tx: '', status: 'LOCKED', verified: false,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.smart_toy_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text('AGENTIC ENGINE', style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w800,
                        color: AppColors.primary, letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 10),
                _consoleLine('Auto-evaluation', 'ACTIVE', true),
                _consoleLine('Next evaluation', 'Aug 29, 2026', true),
                _consoleLine('Eligibility', '6-Month Badge MINTED', true),
                _consoleLine('Next unlock', 'Gold at 12 months', true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeCard({
    required String emoji, required String name, required String tier,
    required Color color, required String date, required String tx,
    required String status, required bool verified,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: verified ? color.withValues(alpha: 0.4) : AppColors.border,
            width: verified ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
                    Text(tier, style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: verified
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.border.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(status, style: GoogleFonts.inter(
                    fontSize: 9, fontWeight: FontWeight.w800,
                    color: verified ? AppColors.success : AppColors.muted)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(date, style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
          if (tx.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.link_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(tx, style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                const Spacer(),
                Text('View on Snowtrace', style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _consoleLine(String label, String value, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle_outline_rounded : Icons.radio_button_unchecked,
              size: 14, color: ok ? AppColors.success : AppColors.muted),
          const SizedBox(width: 6),
          Text('$label: ', style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
          Text(value, style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // EVIDENCE CONSOLE — matches EvidenceConsoleScreen
  // ═══════════════════════════════════════
  Widget _evidenceConsoleBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.deep, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Text('ALL SYSTEMS ACTIVE',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w800,
                            color: Colors.white, letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Every payment is cryptographically verified.',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('LIVE DEMOS',
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: AppColors.muted, letterSpacing: 0.6)),
          const SizedBox(height: 10),
          _evidenceDemoTile(
            icon: Icons.phone_in_talk_rounded,
            title: 'USSD Simulator',
            subtitle: 'Tap to simulate *384*123# flow',
            color: AppColors.primary,
            onTap: () => _navigateTo(6),
          ),
          const SizedBox(height: 8),
          _evidenceDemoTile(
            icon: Icons.sms_rounded,
            title: 'SMS Test',
            subtitle: "Send receipt via Africa's Talking",
            color: AppColors.success,
            onTap: () => _navigateTo(7),
          ),
          const SizedBox(height: 24),
          Text('PAYMENT VERIFICATION',
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: AppColors.muted, letterSpacing: 0.6)),
          const SizedBox(height: 10),
          _evidenceCheck('SasaPay OAuth2 Token', 'GET /oauth/token \u2014 active', true),
          const SizedBox(height: 8),
          _evidenceCheck('HMAC-SHA512 Callback Verification', 'Webhook signature validated', true),
          const SizedBox(height: 8),
          _evidenceCheck('Checkout Link Generation', 'POST /api/v1/checkout \u2014 active', true),
          const SizedBox(height: 8),
          _evidenceCheck('Transaction Query', 'GET /api/v1/query \u2014 active', true),
          const SizedBox(height: 20),
          Text('NOTIFICATIONS',
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: AppColors.muted, letterSpacing: 0.6)),
          const SizedBox(height: 10),
          _evidenceCheck('AT Bulk SMS \u2014 Customer Receipts', 'POST /version1/messaging', true),
          const SizedBox(height: 8),
          _evidenceCheck('AT USSD \u2014 Balance Check', '*384*123# \u2014 active (shortcode 14434)', true),
          const SizedBox(height: 8),
          _evidenceCheck('AT Airtime \u2014 Consistency Rewards', 'POST /api/v1/airtime/send \u2014 active', true),
          const SizedBox(height: 20),
          Text('CRYPTOGRAPHIC PROOF',
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: AppColors.muted, letterSpacing: 0.6)),
          const SizedBox(height: 10),
          _evidenceCheck('AT AES-256 Airtime Encryption', 'Headers.x-at-encryption-key \u2014 active', true),
          const SizedBox(height: 8),
          _evidenceCheck('AES-256 Decryption on Server', 'data_decrypted verified', true),
          const SizedBox(height: 8),
          _evidenceCheck('SHA-256 Hash Integrity', 'Verification event hash stored', true),
          const SizedBox(height: 8),
          _evidenceCheck('Avalanche Badge (Coming Soon)', 'On-chain attestation pending', false),
          const SizedBox(height: 20),
          Text('API ENDPOINTS',
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: AppColors.muted, letterSpacing: 0.6)),
          const SizedBox(height: 10),
          _evidenceEndpoint('POST', '/api/v1/collections/', 'Record customer payment'),
          const SizedBox(height: 6),
          _evidenceEndpoint('POST', '/api/v1/collections/{id}/pay/', 'Generate payment link'),
          const SizedBox(height: 6),
          _evidenceEndpoint('POST', '/webhooks/sasapay/', 'Receive payment callback'),
          const SizedBox(height: 6),
          _evidenceEndpoint('GET', '/api/v1/members/', 'List customers'),
          const SizedBox(height: 6),
          _evidenceEndpoint('POST', '/api/v1/send-links/', 'Bulk payment links'),
          const SizedBox(height: 6),
          _evidenceEndpoint('GET', '/api/v1/sms/history/', 'SMS delivery log'),
          const SizedBox(height: 6),
          _evidenceEndpoint('POST', '/api/v1/airtime/send/', 'Disburse airtime reward'),
          const SizedBox(height: 6),
          _evidenceEndpoint('GET', '/api/v1/leaderboard/', 'Top payers by streak'),
          const SizedBox(height: 6),
          _evidenceEndpoint('POST', '/api/v1/uat/request/', 'USSD balance request'),
          const SizedBox(height: 6),
          _evidenceEndpoint('POST', '/ussd/', 'USSD callback handler'),
          const SizedBox(height: 6),
          _evidenceEndpoint('GET', '/dashboard/', 'Web dashboard'),
        ],
      ),
    );
  }

  Widget _evidenceDemoTile({
    required IconData icon, required String title, required String subtitle,
    required Color color, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('TAP',
                  style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w800, color: color)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _evidenceCheck(String title, String detail, bool ok) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: (ok ? AppColors.success : AppColors.muted).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              ok ? Icons.check_rounded : Icons.schedule_rounded,
              size: 16,
              color: ok ? AppColors.success : AppColors.muted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                Text(detail,
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
          Text(ok ? 'Active' : 'Soon',
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: ok ? AppColors.success : AppColors.muted)),
        ],
      ),
    );
  }

  Widget _evidenceEndpoint(String method, String path, String desc) {
    final color = method == 'POST' ? AppColors.primary : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(method,
                style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w800, color: color)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(path,
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
                Text(desc,
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // SETTINGS — matches mobile Settings
  // ═══════════════════════════════════════
  Widget _settingsBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _settingsSection('BUSINESS'),
            const SizedBox(height: 8),
            _settingsActionRow(Icons.business_rounded, 'Business name', "Peter's Metal Works"),
            _settingsActionRow(Icons.location_on_rounded, 'Location', 'Kariobangi, Nairobi'),
            _settingsActionRow(Icons.category_rounded, 'Type', 'Manufacturer'),
            const SizedBox(height: 24),
            _settingsSection('ACCOUNT'),
            const SizedBox(height: 8),
            _settingsActionRow(Icons.person_outline_rounded, 'Name', 'Peter Kaunda'),
            _settingsActionRow(Icons.phone_rounded, 'Phone', '0715 641 339'),
            _settingsActionRow(Icons.lock_outline_rounded, 'PIN', 'Change PIN'),
            const SizedBox(height: 24),
            _settingsSection('PAYMENT'),
            const SizedBox(height: 8),
            _settingsActionRow(Icons.link_rounded, 'SasaPay Merchant', '600980'),
            _settingsActionRow(Icons.storefront_rounded, 'Checkout mode', 'Sandbox'),
            const SizedBox(height: 24),
            _settingsSection('NOTIFICATIONS'),
            const SizedBox(height: 8),
            _settingsActionRow(Icons.sms_rounded, 'AT Bulk SMS', 'Active'),
            _settingsActionRow(Icons.phone_in_talk_rounded, 'AT USSD', '*384*123#'),
            _settingsActionRow(Icons.card_giftcard_rounded, 'AT Airtime', 'Active'),
            const SizedBox(height: 24),
            _settingsSection('ABOUT'),
            const SizedBox(height: 8),
            _settingsActionRow(Icons.info_outline_rounded, 'Version', '2.0.0'),
            _settingsActionRow(Icons.description_rounded, 'Terms', 'View terms'),
            _settingsActionRow(Icons.privacy_tip_rounded, 'Privacy', 'View privacy policy'),
          ],
        ),
      ),
    );
  }

  Widget _settingsSection(String title) {
    return Text(title,
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w800,
            color: AppColors.muted, letterSpacing: 0.6));
  }

  Widget _settingsActionRow(IconData icon, String title, String value) {
    return Container(
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
    );
  }

  // ═══════════════════════════════════════
  // USSD SIMULATOR (preserved exactly)
  // ═══════════════════════════════════════
  Widget _ussdBody() {
    return const SizedBox(
      height: double.infinity,
      child: _WebUssdSimulator(),
    );
  }

  // ═══════════════════════════════════════
  // BULK SMS (preserved exactly)
  // ═══════════════════════════════════════
  Widget _bulkSmsBody() {
    return const SizedBox(
      height: double.infinity,
      child: _WebBulkSms(),
    );
  }
}

// ═══════════════════════════════════════════════════
// NEW ORDER — stateful widget matching CreateCollectionScreen
// ═══════════════════════════════════════════════════
class _WebNewOrderBody extends StatefulWidget {
  const _WebNewOrderBody();
  @override
  State<_WebNewOrderBody> createState() => _WebNewOrderBodyState();
}

class _WebNewOrderBodyState extends State<_WebNewOrderBody> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _desc = TextEditingController();
  final _minInstallment = TextEditingController();
  final _numInstallments = TextEditingController();
  bool _loading = false;
  bool _allowPartial = false;
  int _selectedMethodIdx = 0;
  DateTime? _dueDate;

  static const _methods = [
    ('M-Pesa STK', Icons.phone_android_rounded, 'Send STK Push'),
    ('SasaPay Link', Icons.link_rounded, 'Generate Link & Send'),
    ('M-Pesa Till', Icons.store_rounded, 'Show Till Number'),
    ('M-Pesa Paybill', Icons.receipt_long_rounded, 'Show Paybill'),
    ('Card Payment', Icons.credit_card_rounded, 'Process Card Payment'),
    ('Airtel Money', Icons.phone_iphone_rounded, 'Send Airtel Request'),
  ];

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _desc.dispose();
    _minInstallment.dispose();
    _numInstallments.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _title.text.trim();
    final amt = double.tryParse(_amount.text.trim()) ?? 0;
    if (name.isEmpty) {
      _snack('Enter customer name', AppColors.danger);
      return;
    }
    if (amt <= 0) {
      _snack('Enter a valid amount', AppColors.danger);
      return;
    }
    if (_allowPartial) {
      final minInst = double.tryParse(_minInstallment.text.trim()) ?? 0;
      final numInst = int.tryParse(_numInstallments.text.trim()) ?? 0;
      if (minInst <= 0) {
        _snack('Enter a valid minimum installment', AppColors.danger);
        return;
      }
      if (minInst >= amt) {
        _snack('Installment must be less than total amount', AppColors.danger);
        return;
      }
      if (numInst < 2) {
        _snack('Allow at least 2 installments', AppColors.danger);
        return;
      }
    }
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      final due = _dueDate ?? DateTime.now().add(const Duration(days: 7));
      WorkforceService.createCollection(
        title: name,
        type: 'Order',
        amount: amt,
        due: due,
        railId: 'sasapay',
        railName: _methods[_selectedMethodIdx].$1,
        message: _desc.text.trim().isEmpty
            ? 'Order for $name \u2014 Ksh ${amt.round()}'
            : _desc.text.trim(),
      );
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_methods[_selectedMethodIdx].$3} sent for $name',
              style: GoogleFonts.inter()),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    });
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter()),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = _dueDate != null
        ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
        : 'Select date';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Choose a payment method and enter the order details below.',
                        style: TextStyle(fontSize: 12, color: AppColors.primary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _label('Customer name'),
              const SizedBox(height: 8),
              TextField(
                controller: _title,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                decoration: _inputDecoration("e.g. St. Mary's School", Icons.person_rounded),
              ),
              const SizedBox(height: 20),
              _label('Amount (KES)'),
              const SizedBox(height: 8),
              TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                decoration: _inputDecoration('e.g. 50000', Icons.payments_rounded),
              ),
              const SizedBox(height: 20),
              _label('Description'),
              const SizedBox(height: 8),
              TextField(
                controller: _desc,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                maxLength: 160,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                decoration: _inputDecoration('e.g. 200 desks for classroom', Icons.description_rounded),
              ),
              const SizedBox(height: 24),
              _label('Payment method'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_methods.length, (i) {
                  final m = _methods[i];
                  final selected = _selectedMethodIdx == i;
                  return ChoiceChip(
                    label: Text(m.$1, style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.white : AppColors.text,
                    )),
                    avatar: Icon(m.$2, size: 16, color: selected ? Colors.white : AppColors.muted),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onSelected: (_) => setState(() => _selectedMethodIdx = i),
                  );
                }),
              ),
              const SizedBox(height: 24),
              _label('Due date'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDueDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: _inputDecoration('Select date', Icons.calendar_today_rounded)
                      .copyWith(hintText: dateFormat),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dateFormat,
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w600,
                              color: _dueDate != null ? AppColors.text : AppColors.muted)),
                      const Icon(Icons.arrow_drop_down, color: AppColors.muted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.pie_chart_outline_rounded, size: 20, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Allow partial payments?',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                        Switch.adaptive(
                          value: _allowPartial,
                          onChanged: (v) => setState(() => _allowPartial = v),
                          activeThumbColor: AppColors.primary,
                        ),
                      ],
                    ),
                    if (_allowPartial) ...[
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      _label('Minimum installment (KES)'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _minInstallment,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                        decoration: _inputDecoration('e.g. 5000', Icons.monetization_on_rounded),
                      ),
                      const SizedBox(height: 16),
                      _label('Number of installments'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _numInstallments,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                        decoration: _inputDecoration('e.g. 3', Icons.format_list_numbered_rounded),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(_methods[_selectedMethodIdx].$2, color: Colors.white),
                  label: Text(_loading ? 'Processing...' : _methods[_selectedMethodIdx].$3,
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text));
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
          color: AppColors.muted.withValues(alpha: 0.5), fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// CUSTOMERS — stateful widget matching MembersScreen
// ═══════════════════════════════════════════════════
class _WebCustomersBody extends StatefulWidget {
  const _WebCustomersBody();
  @override
  State<_WebCustomersBody> createState() => _WebCustomersBodyState();
}

class _WebCustomersBodyState extends State<_WebCustomersBody> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<WfMember> _visible() {
    final q = _query.text.trim().toLowerCase();
    return WorkforceService.activeCollections
        .expand((c) => c.tasks.values)
        .map((t) => WorkforceService.memberById(t.workerId))
        .whereType<WfMember>()
        .where((w) {
      if (q.isNotEmpty && !w.name.toLowerCase().contains(q) && !w.code.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _visible();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _query,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Search customers...',
              hintStyle: GoogleFonts.inter(color: AppColors.muted.withValues(alpha: 0.5)),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  const Icon(Icons.person_search_rounded, size: 40, color: AppColors.muted),
                  const SizedBox(height: 8),
                  Text('No customers found',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.muted)),
                ],
              ),
            )
          else
            ...list.map((w) => _customerCard(w)),
        ],
      ),
    );
  }

  Widget _customerCard(WfMember w) {
    final activeDue = WorkforceService.tasksForMember(w.id)
        .where((e) => e.task.state.index < WfPaymentState.completed.index)
        .length;
    final isClear = activeDue == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: HSLColor.fromAHSL(1, w.avatarHue, 0.55, 0.62).toColor(),
            child: Text(
              w.name.split(' ').map((e) => e[0]).take(2).join(),
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w.name,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                const SizedBox(height: 2),
                Text(w.code,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isClear ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isClear ? 'CLEAR' : '$activeDue DUE',
              style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w800,
                  color: isClear ? AppColors.success : AppColors.warning),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department_rounded, size: 12, color: AppColors.gold),
                const SizedBox(width: 3),
                Text('${w.currentStreak}',
                    style: GoogleFonts.inter(
                        fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.gold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// USSD SIMULATOR — matches mobile exactly
// ═══════════════════════════════════════════════════
class _WebUssdSimulator extends StatefulWidget {
  const _WebUssdSimulator();
  @override
  State<_WebUssdSimulator> createState() => _WebUssdSimulatorState();
}

enum _UssdState { start, loginPin, mainMenu, clockInConfirm, clockOutConfirm, balance, incidentCategory, incidentDesc }

class _WebUssdSimulatorState extends State<_WebUssdSimulator> {
  final List<_UssdEntry> _log = [];
  bool _loading = false;
  _UssdState _state = _UssdState.start;
  int _step = 0;
  int _retryCount = 0;
  final List<String> _processingSteps = [];
  final _inputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _log.clear();
    _state = _UssdState.start;
    _step = 0;
    _retryCount = 0;
    _log.add(_UssdEntry(type: _UssdType.network, text: 'USSD code: *384*123#', step: 0));
    _log.add(_UssdEntry(type: _UssdType.system, text: 'Connecting to shortcode 14434...', step: 1));
    setState(() {});
    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() {
        _loading = false;
        _log.add(_UssdEntry(
          type: _UssdType.menu,
          text: 'CON Welcome to TapVerify\nEnter your 4-digit PIN to login:',
          step: 2,
        ));
        _state = _UssdState.loginPin;
      });
    });
    setState(() => _loading = true);
  }

  void _handleInput(String input) async {
    setState(() {
      _loading = true;
      _step++;
      _log.add(_UssdEntry(type: _UssdType.user, text: input, step: _step));
    });
    await _showProcessing('Verifying request', 3);
    await _showProcessing('Processing', 5);

    switch (_state) {
      case _UssdState.start: break;
      case _UssdState.loginPin: _handleLoginPin(input); break;
      case _UssdState.mainMenu: _handleMainMenu(input); break;
      case _UssdState.clockInConfirm: _handleClockIn(input); break;
      case _UssdState.clockOutConfirm: _handleClockOut(input); break;
      case _UssdState.balance: _handleBalance(input); break;
      case _UssdState.incidentCategory: _handleIncidentCategory(input); break;
      case _UssdState.incidentDesc: _handleIncidentDesc(input); break;
    }
  }

  Future<void> _showProcessing(String label, int maxCount) async {
    for (int i = 1; i <= maxCount; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        setState(() {
          _processingSteps.clear();
          _processingSteps.add('$label... ($i/$maxCount)');
        });
      }
    }
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) setState(() => _processingSteps.clear());
  }

  void _handleLoginPin(String input) {
    if (input == '1234') {
      _retryCount = 0;
      _state = _UssdState.mainMenu;
      _log.add(_UssdEntry(type: _UssdType.system, text: 'CON [MAIN MENU]\n1. Clock In\n2. Clock Out\n3. View Balance\n4. Report Safety Incident\n5. View Announcements', step: _step));
    } else {
      _retryCount++;
      if (_retryCount >= 3) {
        _log.add(_UssdEntry(type: _UssdType.system, text: 'END Too many incorrect PIN attempts. Session closed.', step: _step));
        _state = _UssdState.start;
        _retryCount = 0;
      } else {
        _log.add(_UssdEntry(type: _UssdType.system, text: 'CON Incorrect PIN. Enter your 4-digit PIN to login:', step: _step));
      }
    }
    setState(() => _loading = false);
  }

  void _handleMainMenu(String input) {
    switch (input) {
      case '1':
        _state = _UssdState.clockInConfirm;
        _log.add(_UssdEntry(type: _UssdType.system, text: 'CON Confirm Clock In?\n1. Yes \u2014 Clock In Now\n2. No \u2014 Go Back', step: _step));
        break;
      case '2':
        _state = _UssdState.clockOutConfirm;
        _log.add(_UssdEntry(type: _UssdType.system, text: 'CON Confirm Clock Out?\n1. Yes \u2014 Clock Out Now\n2. No \u2014 Go Back', step: _step));
        break;
      case '3':
        _state = _UssdState.balance;
        _log.add(_UssdEntry(type: _UssdType.system, text: 'CON Select balance type:\n1. Payment Balance\n2. Leave Balance\n3. Streak & Points\n0. Go Back', step: _step));
        break;
      case '4':
        _state = _UssdState.incidentCategory;
        _log.add(_UssdEntry(type: _UssdType.system, text: 'CON Select Category:\n1. Safety Incident\n2. Equipment Issue\n3. Payment Dispute\n0. Go Back', step: _step));
        break;
      case '5':
        _log.add(_UssdEntry(type: _UssdType.system, text: 'END [ANNOUNCEMENT]\nTapVerify v2.0: Revenue proof for your business.\nNew: USSD balance check now available.\nContact admin for support.', step: _step));
        _state = _UssdState.mainMenu;
        break;
      default:
        _log.add(_UssdEntry(type: _UssdType.system, text: 'CON Invalid choice. Select option:\n1. Clock In\n2. Clock Out\n3. View Balance\n4. Report Safety Incident\n5. View Announcements', step: _step));
    }
    setState(() => _loading = false);
  }

  void _handleClockIn(String input) {
    if (input == '2') {
      _state = _UssdState.mainMenu;
      _log.add(_UssdEntry(type: _UssdType.system, text: 'CON [MAIN MENU]\n1. Clock In\n2. Clock Out\n3. View Balance\n4. Report Safety Incident\n5. View Announcements', step: _step));
    } else if (input == '1') {
      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      _log.add(_UssdEntry(type: _UssdType.system, text: 'END Clocked in [ON TIME] at $timeStr.\nDate: $dateStr\nChannel: USSD (shortcode 14434)\nEmployee: Peter Kaunda', step: _step));
      _state = _UssdState.mainMenu;
    } else {
      _log.add(_UssdEntry(type: _UssdType.system, text: 'CON Invalid choice. Confirm Clock In?\n1. Yes \u2014 Clock In Now\n2. No \u2014 Go Back', step: _step));
    }
    setState(() => _loading = false);
  }

  void _handleClockOut(String input) {
    if (input == '2') {
      _state = _UssdState.mainMenu;
      _log.add(_UssdEntry(type: _UssdType.system, text: 'CON [MAIN MENU]\n1. Clock In\n2. Clock Out\n3. View Balance\n4. Report Safety Incident\n5. View Announcements', step: _step));
    } else if (input == '1') {
      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      _log.add(_UssdEntry(type: _UssdType.system, text: 'END Clocked out [ON TIME] at $timeStr.\nHours worked: 8h 23m\nChannel: USSD (shortcode 14434)', step: _step));
      _state = _UssdState.mainMenu;
    } else {
      _log.add(_UssdEntry(type: _UssdType.system, text: 'CON Invalid choice. Confirm Clock Out?\n1. Yes \u2014 Clock Out Now\n2. No \u2014 Go Back', step: _step));
    }
    setState(() => _loading = false);
  }

  void _handleBalance(String input) {
    switch (input) {
      case '0':
        _state = _UssdState.mainMenu;
        _log.add(_UssdEntry(type: _UssdType.system, text: 'CON [MAIN MENU]\n1. Clock In\n2. Clock Out\n3. View Balance\n4. Report Safety Incident\n5. View Announcements', step: _step));
        break;
      case '1':
        _log.add(_UssdEntry(type: _UssdType.system, text: 'END [PAYMENT BALANCE]\nTotal earned: Ksh 2,400,000\nTotal paid: Ksh 2,400,000\nBalance: Ksh 0\nConsistency: 94%\nChannel: USSD (shortcode 14434)', step: _step));
        _state = _UssdState.mainMenu;
        break;
      case '2':
        _log.add(_UssdEntry(type: _UssdType.system, text: 'END [LEAVE BALANCE]\nAnnual leave: 21 days\nUsed: 8 days\nRemaining: 13 days\nSick leave: 7 days remaining', step: _step));
        _state = _UssdState.mainMenu;
        break;
      case '3':
        _log.add(_UssdEntry(type: _UssdType.system, text: 'END [STREAK & POINTS]\nCurrent streak: 6 months\nBest streak: 6 months\nPoints: 1,240 pts\nRank: Gold Payer\nNext reward: Ksh 500 airtime at 2,000 pts', step: _step));
        _state = _UssdState.mainMenu;
        break;
      default:
        _log.add(_UssdEntry(type: _UssdType.system, text: 'CON Invalid choice. Select balance type:\n1. Payment Balance\n2. Leave Balance\n3. Streak & Points\n0. Go Back', step: _step));
    }
    setState(() => _loading = false);
  }

  void _handleIncidentCategory(String input) {
    if (input == '0') {
      _state = _UssdState.mainMenu;
      _log.add(_UssdEntry(type: _UssdType.system, text: 'CON [MAIN MENU]\n1. Clock In\n2. Clock Out\n3. View Balance\n4. Report Safety Incident\n5. View Announcements', step: _step));
    } else if (['1', '2', '3'].contains(input)) {
      _state = _UssdState.incidentDesc;
      _log.add(_UssdEntry(type: _UssdType.system, text: 'CON Enter brief description:\n(Enter 0 to go back)', step: _step));
    } else {
      _log.add(_UssdEntry(type: _UssdType.system, text: 'CON Invalid choice. Select Category:\n1. Safety Incident\n2. Equipment Issue\n3. Payment Dispute\n0. Go Back', step: _step));
    }
    setState(() => _loading = false);
  }

  void _handleIncidentDesc(String input) {
    if (input == '0') {
      _state = _UssdState.incidentCategory;
      _log.add(_UssdEntry(type: _UssdType.system, text: 'CON Select Category:\n1. Safety Incident\n2. Equipment Issue\n3. Payment Dispute\n0. Go Back', step: _step));
    } else if (input.isNotEmpty) {
      final cat = ['safety', 'equipment', 'payment dispute'][0];
      _log.add(_UssdEntry(type: _UssdType.system, text: 'END Incident reported [OPEN].\nCategory: $cat\nDescription: $input\nReported via: USSD (shortcode 14434)\nThank you.', step: _step));
      _state = _UssdState.mainMenu;
    } else {
      _log.add(_UssdEntry(type: _UssdType.system, text: 'CON Description cannot be empty.\nEnter brief description:\n(Enter 0 to go back)', step: _step));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF16213E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              const Icon(Icons.phone_android_rounded, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Text('Phone: 254715641339', style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: Text('LIVE', style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: Text('STEP $_step', style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _startSession,
                child: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
              ),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _log.length + _processingSteps.length,
              itemBuilder: (context, i) {
                if (i >= _log.length) {
                  final pIdx = i - _log.length;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      SizedBox(width: 12, height: 12, child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: AppColors.primary)),
                      const SizedBox(width: 10),
                      Text(_processingSteps[pIdx], style: GoogleFonts.inter(
                          fontSize: 11, color: Colors.white38, fontStyle: FontStyle.italic)),
                    ]),
                  );
                }
                return _logEntry(_log[i]);
              },
            ),
          ),
          if (!_loading) _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    switch (_state) {
      case _UssdState.loginPin:
        return _inputArea('Enter PIN (demo: 1234)', true);
      case _UssdState.incidentDesc:
        return _inputArea('Enter description', false);
      default:
        return _inputArea('Type number and press Send', true);
    }
  }

  Widget _inputArea(String hint, bool isNumber) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(top: BorderSide(color: Color(0xFF0F3460))),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _inputCtrl,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF0F3460),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 80, height: 48,
          child: ElevatedButton(
            onPressed: () {
              if (_inputCtrl.text.isNotEmpty) {
                _handleInput(_inputCtrl.text);
                _inputCtrl.clear();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('SEND', style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ),
      ]),
    );
  }

  Widget _logEntry(_UssdEntry entry) {
    Color color;
    IconData icon;
    String label;
    Color bg;

    switch (entry.type) {
      case _UssdType.network:
        color = Colors.white38; icon = Icons.wifi_tethering_rounded; label = 'NETWORK'; bg = const Color(0xFF0A1628); break;
      case _UssdType.system:
        color = Colors.white; icon = Icons.phone_rounded; label = 'USSD'; bg = const Color(0xFF0F3460); break;
      case _UssdType.user:
        color = AppColors.primary; icon = Icons.smartphone_rounded; label = 'YOU'; bg = AppColors.primary.withValues(alpha: 0.08); break;
      case _UssdType.menu:
        color = Colors.amber; icon = Icons.menu_rounded; label = 'MENU'; bg = Colors.amber.withValues(alpha: 0.06); break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5)),
            const Spacer(),
            Text('#${entry.step}', style: GoogleFonts.inter(
                fontSize: 10, color: color.withValues(alpha: 0.5))),
          ]),
          const SizedBox(height: 6),
          Text(entry.text, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white, height: 1.4)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// BULK SMS with CSV/Excel upload + photo capture
// ═══════════════════════════════════════════════════
class _WebBulkSms extends StatefulWidget {
  const _WebBulkSms();
  @override
  State<_WebBulkSms> createState() => _WebBulkSmsState();
}

class _WebBulkSmsState extends State<_WebBulkSms> {
  final _phonesCtrl = TextEditingController();
  final _messageCtrl = TextEditingController(
    text: 'Hello {name}, your payment of Ksh {amount} for {order} is due on {date}. Pay via: {link}',
  );
  bool _sending = false;
  int _sentCount = 0;
  int _totalCount = 0;
  String? _result;

  List<String> _parsePhones() {
    final raw = _phonesCtrl.text.trim();
    if (raw.isEmpty) return [];
    final parts = raw.split(RegExp(r'[\n,;]+'));
    return parts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
  }

  void _showSampleCsv() {
    final sample = 'phone,name,amount,order\n0712345678,John Kamau,15000,Steel Bars\n0723456789,Mary Wanjiku,8500,Cement Bags\n0734567890,James Ochieng,22000,Iron Sheets\n0745678901,Sarah Nyambura,12000,Welding Rods\n0756789012,Peter Mwangi,35000,Aluminum Windows';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.table_chart_rounded, color: AppColors.success, size: 22),
          const SizedBox(width: 10),
          Text('CSV Format Template', style: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your CSV should have these columns:', style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.muted)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(sample,
                  style: GoogleFonts.firaCode(
                      fontSize: 11, color: AppColors.success, height: 1.5)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Columns: phone (required), name, amount, order. '
                  'Phone numbers in format 07XXXXXXXX or 254XXXXXXXXX.',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                )),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.inter(color: AppColors.muted)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Sample format shown — create a CSV with these columns',
                    style: GoogleFonts.inter()),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
            icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            label: Text('Got it', style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt', 'xlsx', 'xls'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      final content = String.fromCharCodes(bytes);
      final rows = const CsvToListConverter().convert(content);

      final phones = <String>[];
      for (final row in rows) {
        for (final cell in row) {
          final str = cell.toString().trim();
          final match = RegExp(r'(?:254|\+254|0)?(\d{9})').firstMatch(str);
          if (match != null) {
            phones.add(match.group(0)!);
          }
        }
      }

      setState(() {
        _phonesCtrl.text = phones.join('\n');
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Found ${phones.length} phone numbers from ${file.name}', style: GoogleFonts.inter()),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error reading file: $e', style: GoogleFonts.inter()),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  Future<void> _send() async {
    final phones = _parsePhones();
    if (phones.isEmpty) {
      setState(() => _result = 'No phone numbers entered.');
      return;
    }
    if (_messageCtrl.text.trim().isEmpty) {
      setState(() => _result = 'Message cannot be empty.');
      return;
    }

    setState(() {
      _sending = true;
      _sentCount = 0;
      _totalCount = phones.length;
      _result = null;
    });

    for (var i = 0; i < phones.length; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => _sentCount = i + 1);
    }

    if (!mounted) return;
    setState(() {
      _sending = false;
      _result = 'Done! Sent $_totalCount SMS successfully.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.sms_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text('Bulk SMS', style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
            ]),
            const SizedBox(height: 6),
            Text("Send payment reminders via Africa's Talking", style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.muted)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _uploadOption(
                Icons.upload_file_rounded, 'Upload CSV/Excel',
                'Import phone numbers from spreadsheet', _uploadCsv,
              )),
              const SizedBox(width: 12),
              Expanded(child: _uploadOption(
                Icons.camera_alt_rounded, 'Capture from Photo',
                'Extract numbers from image', () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Photo capture: Use mobile app for camera access', style: GoogleFonts.inter()),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                },
              )),
            ]),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showSampleCsv,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.download_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('Download Sample CSV Template', style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            Text('PHONE NUMBERS', style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.6)),
            const SizedBox(height: 8),
            TextField(
              controller: _phonesCtrl,
              maxLines: 6,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText: '0712345678\n0723456789\n...or paste comma-separated',
                hintStyle: GoogleFonts.inter(color: AppColors.muted.withValues(alpha: 0.5), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text('${_parsePhones().length} recipients', style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Text('MESSAGE TEMPLATE', style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.6)),
            const SizedBox(height: 8),
            TextField(
              controller: _messageCtrl,
              maxLines: 4,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              _tag('{name}'), _tag('{amount}'), _tag('{order}'), _tag('{date}'), _tag('{link}'),
            ]),
            const SizedBox(height: 20),
            if (_sending) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(children: [
                  LinearProgressIndicator(
                    value: _totalCount > 0 ? _sentCount / _totalCount : 0,
                    backgroundColor: AppColors.border,
                    color: AppColors.primary,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 12),
                  Text('Sending to $_sentCount / $_totalCount', style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                ]),
              ),
              const SizedBox(height: 16),
            ],
            if (_result != null && !_sending) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_result!, style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success))),
                ]),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text('Send Bulk SMS (${_parsePhones().length})', style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadOption(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
              Text(subtitle, style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.muted)),
            ],
          )),
        ]),
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

enum _UssdType { network, system, user, menu }

class _UssdEntry {
  final _UssdType type;
  final String text;
  final int step;
  _UssdEntry({required this.type, required this.text, required this.step});
}
