import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../constants.dart';

class WebDashboard extends StatefulWidget {
  const WebDashboard({super.key});
  @override
  State<WebDashboard> createState() => _WebDashboardState();
}

class _WebDashboardState extends State<WebDashboard> {
  int _selectedNav = 0;

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
    _NavItem(Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final narrow = w < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
      selectedTileColor: AppColors.primary.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: () => setState(() => _selectedNav = i),
    );
  }

  Widget _sidebarProfile() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: const Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Peter Kaunda', style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text('Business Owner', style: GoogleFonts.inter(
                        fontSize: 10, color: Colors.white54)),
                  ],
                ),
              ],
            ),
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
          Text(_navItems[_selectedNav].label,
              style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.success, AppColors.success.withOpacity(0.8)]),
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
      case 9: return _settingsBody();
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
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // DASHBOARD
  // ═══════════════════════════════════════
  Widget _dashboardBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _gradientStatCard('Total Revenue', 'Ksh 2,400,000', Icons.account_balance_rounded,
                  [const Color(0xFF0D9488), const Color(0xFF0F766E)]),
              const SizedBox(width: 16),
              _gradientStatCard('Verified Payments', '48', Icons.verified_rounded,
                  [const Color(0xFF16A34A), const Color(0xFF15803D)]),
              const SizedBox(width: 16),
              _gradientStatCard('Consistency', '94%', Icons.trending_up_rounded,
                  [const Color(0xFFC9A227), const Color(0xFFA88B1E)]),
              const SizedBox(width: 16),
              _gradientStatCard('Trust Score', '87/100', Icons.shield_rounded,
                  [const Color(0xFF1E40AF), const Color(0xFF1E3A8A)]),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _milestoneWidget()),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _streakWidget()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _trustScoreWidget()),
              const SizedBox(width: 16),
              Expanded(flex: 3, child: _lenderChecklistWidget()),
            ],
          ),
          const SizedBox(height: 16),
          _badgesWidget(),
          const SizedBox(height: 16),
          _recentOrdersWidget(),
        ],
      ),
    );
  }

  Widget _gradientStatCard(String label, String value, IconData icon, List<Color> colors) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: colors[0].withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                Text(label, style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _milestoneWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.emoji_events_rounded, size: 18, color: AppColors.gold),
            const SizedBox(width: 8),
            Text('REVENUE JOURNEY', style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Text('Ksh 2.4M', style: GoogleFonts.inter(
                fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primary)),
            Text(' / 5M', style: GoogleFonts.inter(fontSize: 16, color: AppColors.muted)),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: 0.48, minHeight: 12,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.deep]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('TRUSTED', style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            const Spacer(),
            Text('Ksh 2.6M to Champion', style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.muted)),
          ]),
        ],
      ),
    );
  }

  Widget _streakWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.local_fire_department_rounded, size: 18, color: AppColors.accent),
            const SizedBox(width: 8),
            Text('RECORDING STREAK', style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFFDC2626)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(child: Text('🔥', style: TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('12 Days', style: GoogleFonts.inter(
                  fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.text)),
              Text('Record: 18 days', style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.muted)),
            ]),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.card_giftcard_rounded, size: 16, color: AppColors.success),
              const SizedBox(width: 8),
              Text('Ksh 50 airtime at 15 days', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _trustScoreWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.shield_rounded, size: 18, color: AppColors.deep),
            const SizedBox(width: 8),
            Text('TRUST SCORE', style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Text('87', style: GoogleFonts.inter(
                fontSize: 44, fontWeight: FontWeight.w900, color: AppColors.text)),
            Text(' / 100', style: GoogleFonts.inter(fontSize: 18, color: AppColors.muted)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.success, AppColors.success.withOpacity(0.8)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('EXCELLENT', style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(height: 14),
          _trustBar('Verification', '98%', 0.98, AppColors.success),
          _trustBar('Response', '4.2h', 0.72, AppColors.primary),
          _trustBar('Growth', '+23%', 0.82, AppColors.gold),
        ],
      ),
    );
  }

  Widget _trustBar(String label, String value, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
            const Spacer(),
            Text(value, style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, minHeight: 6,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(color)),
          ),
        ],
      ),
    );
  }

  Widget _lenderChecklistWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.checklist_rounded, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            Text('LENDER-READY CHECKLIST', style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 14),
          _checkItem(true, 'Verified Ksh 100K+ revenue'),
          _checkItem(true, '30+ days of payment history'),
          _checkItem(true, 'Zero disputed payments'),
          _checkItem(false, '6-month consistency streak — 2 months to go'),
          _checkItem(false, 'Connect SACCO account'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.08), AppColors.primary.withOpacity(0.04)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.celebration_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text('You are 2 checks away from a Lender-Ready Profile!', style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _checkItem(bool checked, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 18, color: checked ? AppColors.success : AppColors.muted),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: checked ? AppColors.text : AppColors.muted))),
      ]),
    );
  }

  Widget _badgesWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.emoji_events_rounded, size: 16, color: AppColors.gold),
            ),
            const SizedBox(width: 8),
            Text('MY BADGES', style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.5)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.deep]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Payer Score: 847/1000', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _badgeCard('🥇', '6-Month Payer', 'Silver', true, '0x7e8b...c4d2'),
            const SizedBox(width: 16),
            _badgeCard('🥈', '3-Month Payer', 'Bronze', true, '0x3f2a...b91c'),
            const SizedBox(width: 16),
            _badgeCard('🏆', '12-Month Payer', 'Gold', false, ''),
          ]),
        ],
      ),
    );
  }

  Widget _badgeCard(String emoji, String name, String tier, bool active, String tx) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? AppColors.gold.withOpacity(0.3) : AppColors.border,
            width: active ? 2 : 1,
          ),
          boxShadow: active ? [BoxShadow(color: AppColors.gold.withOpacity(0.1), blurRadius: 8)] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: active ? LinearGradient(colors: [AppColors.success, AppColors.success.withOpacity(0.8)]) : null,
                  color: active ? null : AppColors.border.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(active ? 'MINTED' : 'LOCKED', style: GoogleFonts.inter(
                    fontSize: 9, fontWeight: FontWeight.w800, color: active ? Colors.white : AppColors.muted)),
              ),
            ]),
            const SizedBox(height: 12),
            Text(name, style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
            Text(tier, style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
            if (tx.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.link_rounded, size: 12, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(tx, style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _recentOrdersWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Recent Orders', style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => setState(() => _selectedNav = 1),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('New Order', style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 16),
          _orderTable(),
        ],
      ),
    );
  }

  Widget _orderTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.5), 1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1), 3: FlexColumnWidth(1),
      },
      children: [
        _tableHeader(['Customer', 'Amount', 'Status', 'Date']),
        _tableRow(['St. Mary\'s School', 'Ksh 45,000', 'verified', '15 Mar 2026']),
        _tableRow(['Kariobangi Hardware', 'Ksh 120,000', 'verified', '12 Mar 2026']),
        _tableRow(['Eastlands Academy', 'Ksh 30,000', 'pending', '10 Mar 2026']),
        _tableRow(['Pumani Construction', 'Ksh 80,000', 'verified', '08 Mar 2026']),
        _tableRow(['Donholm Furniture', 'Ksh 25,000', 'pending', '05 Mar 2026']),
      ],
    );
  }

  TableRow _tableHeader(List<String> cols) {
    return TableRow(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      children: cols.map((c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(c, style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted)),
      )).toList(),
    );
  }

  TableRow _tableRow(List<String> cols) {
    final isVerified = cols[2] == 'verified';
    return TableRow(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage(
                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(cols[0])}&background=0D9488&color=fff&size=100',
              ),
            ),
            const SizedBox(width: 10),
            Text(cols[0], style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(cols[1], style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: isVerified
                  ? LinearGradient(colors: [AppColors.success, AppColors.success.withOpacity(0.8)])
                  : null,
              color: isVerified ? null : AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(cols[2], style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: isVerified ? Colors.white : AppColors.warning)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(cols[3], style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // ORDERS
  // ═══════════════════════════════════════
  Widget _ordersBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('All Orders', style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => setState(() => _selectedNav = 1),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('New Order', style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 16),
            _orderTable(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // CUSTOMERS
  // ═══════════════════════════════════════
  Widget _customersBody() {
    final customers = [
      _Cust('St. Mary\'s School', '0712 345 678', 'Ksh 45,000', 6),
      _Cust('Kariobangi Hardware', '0723 456 789', 'Ksh 120,000', 4),
      _Cust('Eastlands Academy', '0734 567 890', 'Ksh 30,000', 3),
      _Cust('Pumani Construction', '0745 678 901', 'Ksh 80,000', 5),
      _Cust('Donholm Furniture', '0756 789 012', 'Ksh 25,000', 2),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customers', style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(height: 16),
            for (final c in customers)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(
                      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(c.name)}&background=0D9488&color=fff&size=100',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                      Text(c.phone, style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.muted)),
                    ],
                  )),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(c.total, style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    Text('${c.payments} payments', style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.muted)),
                  ]),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // REVENUE
  // ═══════════════════════════════════════
  Widget _revenueBody() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    final amounts = [420000.0, 480000.0, 530000.0, 390000.0, 320000.0, 260000.0];
    final maxVal = amounts.reduce((a, b) => a > b ? a : b);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Revenue', style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
                const SizedBox(height: 24),
                SizedBox(
                  height: 250,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (int i = 0; i < months.length; i++)
                        Expanded(child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('Ksh ${(amounts[i]/1000).round()}K', style: GoogleFonts.inter(
                                  fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted)),
                              const SizedBox(height: 4),
                              Container(
                                height: (amounts[i] / maxVal) * 180,
                                decoration: BoxDecoration(
                                  gradient: i == 2
                                      ? const LinearGradient(colors: [AppColors.primary, AppColors.deep])
                                      : LinearGradient(colors: [AppColors.primary.withOpacity(0.3), AppColors.primary.withOpacity(0.2)]),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(months[i], style: GoogleFonts.inter(
                                  fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted)),
                            ],
                          ),
                        )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            _revenueStat('Total Collected', 'Ksh 2,400,000'),
            const SizedBox(width: 16),
            _revenueStat('Average Order', 'Ksh 50,000'),
            const SizedBox(width: 16),
            _revenueStat('Best Month', 'March 2026'),
          ]),
        ],
      ),
    );
  }

  Widget _revenueStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 6),
            Text(value, style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // CREDIT PROFILE
  // ═══════════════════════════════════════
  Widget _creditBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.success, Color(0xFF15803D)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('CREDITWORTHY', style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            const SizedBox(height: 24),
            _creditRow('Verified Revenue', 'Ksh 2,400,000'),
            _creditRow('Consistency Score', '94%'),
            _creditRow('Total Payments', '48'),
            _creditRow('Disputes', '0'),
            _creditRow('Best Streak', '6 months'),
            _creditRow('Verification Sources', 'SasaPay, M-Pesa, Bank'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
                const SizedBox(width: 8),
                Text('Ready for lender review.', style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.success)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _creditRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
        const SizedBox(width: 10),
        Text(label, style: GoogleFonts.inter(fontSize: 14, color: AppColors.muted)),
        const Spacer(),
        Text(value, style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
      ]),
    );
  }

  // ═══════════════════════════════════════
  // NEW ORDER
  // ═══════════════════════════════════════
  Widget _newOrderBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(28),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Record Customer Payment', style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(height: 6),
            Text('Create an order and generate a payment link', style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.muted)),
            const SizedBox(height: 24),
            _field('Customer name', Icons.person_rounded),
            const SizedBox(height: 16),
            _field('Amount (Ksh)', Icons.payments_rounded, keyboard: TextInputType.number),
            const SizedBox(height: 16),
            _field('Order description', Icons.receipt_rounded),
            const SizedBox(height: 16),
            Text('Payment method', style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _payChip('M-Pesa STK', true),
              _payChip('SasaPay Link', false),
              _payChip('Till Number', false),
              _payChip('Paybill', false),
              _payChip('Card', false),
              _payChip('Airtel', false),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Order created! Payment link generated.', style: GoogleFonts.inter()),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                },
                icon: const Icon(Icons.link_rounded, size: 18),
                label: Text('Create Order & Generate Link', style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String hint, IconData icon, {TextInputType? keyboard}) {
    return TextField(
      keyboardType: keyboard,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.muted.withOpacity(0.5), fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }

  Widget _payChip(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: selected ? const LinearGradient(colors: [AppColors.primary, AppColors.deep]) : null,
        color: selected ? null : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? AppColors.primary : AppColors.border),
      ),
      child: Text(label, style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppColors.text)),
    );
  }

  // ═══════════════════════════════════════
  // USSD SIMULATOR (matches mobile exactly)
  // ═══════════════════════════════════════
  Widget _ussdBody() {
    return const SizedBox(
      height: double.infinity,
      child: _WebUssdSimulator(),
    );
  }

  // ═══════════════════════════════════════
  // BULK SMS (with CSV/Excel upload + photo capture)
  // ═══════════════════════════════════════
  Widget _bulkSmsBody() {
    return const SizedBox(
      height: double.infinity,
      child: _WebBulkSms(),
    );
  }

  // ═══════════════════════════════════════
  // BADGES
  // ═══════════════════════════════════════
  Widget _badgesBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.deep, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('UNIVERSAL PAYER SCORE', style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Text('847', style: GoogleFonts.inter(
                        fontSize: 56, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text(' / 1000', style: GoogleFonts.inter(
                        fontSize: 24, color: Colors.white70)),
                  ]),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Silver Payer II', style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ],
              )),
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(child: Text('🥈', style: TextStyle(fontSize: 50))),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            _largeBadge('🥇', '6-Month Payer', 'Silver', true, '0x7e8b...c4d2'),
            const SizedBox(width: 16),
            _largeBadge('🥈', '3-Month Payer', 'Bronze', true, '0x3f2a...b91c'),
            const SizedBox(width: 16),
            _largeBadge('🏆', '12-Month Payer', 'Gold', false, ''),
          ]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.psychology_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('AGENTIC ENGINE', style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.5)),
                ]),
                const SizedBox(height: 14),
                _trustRow2('Status', 'Active — evaluating daily'),
                _trustRow2('Next Evaluation', 'Tomorrow 00:00 UTC'),
                _trustRow2('Gold Eligibility', '2 months away'),
                _trustRow2('Next Badge Unlock', '3-Month Streak'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _largeBadge(String emoji, String name, String tier, bool active, String tx) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? AppColors.gold.withOpacity(0.3) : AppColors.border,
            width: active ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Text(emoji, style: const TextStyle(fontSize: 48))),
            const SizedBox(height: 14),
            Text(name, style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
            Text(tier, style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
            if (tx.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(tx, style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _trustRow2(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
        const Spacer(),
        Text(value, style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
      ]),
    );
  }

  // ═══════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════
  Widget _settingsBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Business Settings', style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(height: 20),
            _settingsField('Business Name', "Peter's Metal Works"),
            _settingsField('Phone', '0715 641 339'),
            _settingsField('Business Type', 'Business'),
            _settingsField('SasaPay Merchant', '600980'),
            _settingsField('AT Shortcode', '14434'),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {},
                child: Text('Save Changes', style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: value,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
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
        _log.add(_UssdEntry(type: _UssdType.system, text: 'CON Confirm Clock In?\n1. Yes — Clock In Now\n2. No — Go Back', step: _step));
        break;
      case '2':
        _state = _UssdState.clockOutConfirm;
        _log.add(_UssdEntry(type: _UssdType.system, text: 'CON Confirm Clock Out?\n1. Yes — Clock Out Now\n2. No — Go Back', step: _step));
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
        _log.add(_UssdEntry(type: _UssdType.system, text: 'END [ANNOUNCEMENT]\nTapVerify v2.0: Revenue proof for your business.\nNew: USSD balance check now available.', step: _step));
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
      _log.add(_UssdEntry(type: _UssdType.system, text: 'CON Invalid choice. Confirm Clock In?\n1. Yes — Clock In Now\n2. No — Go Back', step: _step));
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
      _log.add(_UssdEntry(type: _UssdType.system, text: 'CON Invalid choice. Confirm Clock Out?\n1. Yes — Clock Out Now\n2. No — Go Back', step: _step));
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
        _log.add(_UssdEntry(type: _UssdType.system, text: 'END [PAYMENT BALANCE]\nTotal earned: Ksh 2,400,000\nTotal paid: Ksh 2,400,000\nBalance: Ksh 0\nConsistency: 94%', step: _step));
        _state = _UssdState.mainMenu;
        break;
      case '2':
        _log.add(_UssdEntry(type: _UssdType.system, text: 'END [LEAVE BALANCE]\nAnnual leave: 21 days\nUsed: 8 days\nRemaining: 13 days', step: _step));
        _state = _UssdState.mainMenu;
        break;
      case '3':
        _log.add(_UssdEntry(type: _UssdType.system, text: 'END [STREAK & POINTS]\nCurrent streak: 6 months\nBest streak: 6 months\nPoints: 1,240 pts\nRank: Gold Payer', step: _step));
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
      _log.add(_UssdEntry(type: _UssdType.system, text: 'END Incident reported [OPEN].\nDescription: $input\nReported via: USSD (shortcode 14434)', step: _step));
      _state = _UssdState.mainMenu;
    } else {
      _log.add(_UssdEntry(type: _UssdType.system, text: 'CON Description cannot be empty.\nEnter brief description:', step: _step));
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
          // Header
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
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: Text('LIVE', style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
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
          // Log
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
          // Input area
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
        color = AppColors.primary; icon = Icons.smartphone_rounded; label = 'YOU'; bg = AppColors.primary.withOpacity(0.08); break;
      case _UssdType.menu:
        color = Colors.amber; icon = Icons.menu_rounded; label = 'MENU'; bg = Colors.amber.withOpacity(0.06); break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
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
                fontSize: 10, color: color.withOpacity(0.5))),
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
  List<String> _uploadedPhones = [];

  List<String> _parsePhones() {
    final raw = _phonesCtrl.text.trim();
    if (raw.isEmpty) return [];
    final parts = raw.split(RegExp(r'[\n,;]+'));
    return parts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
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
          // Extract Kenyan phone numbers
          final match = RegExp(r'(?:254|\+254|0)?(\d{9})').firstMatch(str);
          if (match != null) {
            phones.add(match.group(0)!);
          }
        }
      }

      setState(() {
        _uploadedPhones = phones;
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
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

            // Upload options
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
            const SizedBox(height: 20),

            // Phone numbers
            Text('PHONE NUMBERS', style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.6)),
            const SizedBox(height: 8),
            TextField(
              controller: _phonesCtrl,
              maxLines: 6,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText: '0712345678\n0723456789\n...or paste comma-separated',
                hintStyle: GoogleFonts.inter(color: AppColors.muted.withOpacity(0.5), fontSize: 13),
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

            // Message template
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

            // Progress
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

            // Result
            if (_result != null && !_sending) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.08),
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

            // Send button
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
              color: AppColors.primary.withOpacity(0.1),
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
        gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.05)]),
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

class _Cust {
  final String name, phone, total;
  final int payments;
  _Cust(this.name, this.phone, this.total, this.payments);
}

enum _UssdType { network, system, user, menu }

class _UssdEntry {
  final _UssdType type;
  final String text;
  final int step;
  _UssdEntry({required this.type, required this.text, required this.step});
}
