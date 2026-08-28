import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
          // Gamified stat cards with gradients
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

          // Milestone + Streak row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _milestoneWidget()),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _streakWidget()),
            ],
          ),
          const SizedBox(height: 16),

          // Trust + Lender checklist
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _trustScoreWidget()),
              const SizedBox(width: 16),
              Expanded(flex: 3, child: _lenderChecklistWidget()),
            ],
          ),
          const SizedBox(height: 16),

          // Badges row
          _badgesWidget(),
          const SizedBox(height: 16),

          // Recent orders
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
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, size: 18, color: AppColors.gold),
              const SizedBox(width: 8),
              Text('REVENUE JOURNEY', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Ksh 2.4M', style: GoogleFonts.inter(
                  fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primary)),
              Text(' / 5M', style: GoogleFonts.inter(
                  fontSize: 16, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.48,
              minHeight: 12,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
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
            ],
          ),
          const SizedBox(height: 8),
          Text('Next: Credit Profile Export at Ksh 5M', style: GoogleFonts.inter(
              fontSize: 11, color: AppColors.muted)),
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
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('RECORDING STREAK', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFFDC2626)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 8)],
                ),
                child: const Center(child: Text('🔥', style: TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('12 Days', style: GoogleFonts.inter(
                      fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.text)),
                  Text('Record: 18 days', style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.success.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.card_giftcard_rounded, size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                Text('Ksh 50 airtime at 15 days', style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
              ],
            ),
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
          Row(
            children: [
              const Icon(Icons.shield_rounded, size: 18, color: AppColors.deep),
              const SizedBox(width: 8),
              Text('TRUST SCORE', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('87', style: GoogleFonts.inter(
                  fontSize: 44, fontWeight: FontWeight.w900, color: AppColors.text)),
              Text(' / 100', style: GoogleFonts.inter(
                  fontSize: 18, color: AppColors.muted)),
            ],
          ),
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
          Row(
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
              const Spacer(),
              Text(value, style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
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
          Row(
            children: [
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
            ],
          ),
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
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.08), AppColors.primary.withOpacity(0.04)],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.celebration_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text('You are 2 checks away from a Lender-Ready Profile!', style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkItem(bool checked, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 18,
            color: checked ? AppColors.success : AppColors.muted,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: checked ? AppColors.text : AppColors.muted))),
        ],
      ),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
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
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _badgeCard('🥇', '6-Month Payer', 'Silver', true, '0x7e8b...c4d2',
                  'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=200&h=200&fit=crop'),
              const SizedBox(width: 16),
              _badgeCard('🥈', '3-Month Payer', 'Bronze', true, '0x3f2a...b91c',
                  'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=200&h=200&fit=crop'),
              const SizedBox(width: 16),
              _badgeCard('🏆', '12-Month Payer', 'Gold', false, '',
                  'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=200&h=200&fit=crop'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badgeCard(String emoji, String name, String tier, bool active, String tx, String imageUrl) {
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
          boxShadow: active
              ? [BoxShadow(color: AppColors.gold.withOpacity(0.1), blurRadius: 8)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                      onError: (_, __) {},
                    ),
                    color: active ? AppColors.gold.withOpacity(0.1) : AppColors.border.withOpacity(0.3),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: active
                        ? LinearGradient(colors: [AppColors.success, AppColors.success.withOpacity(0.8)])
                        : null,
                    color: active ? null : AppColors.border.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(active ? 'MINTED' : 'LOCKED', style: GoogleFonts.inter(
                      fontSize: 9, fontWeight: FontWeight.w800,
                      color: active ? Colors.white : AppColors.muted)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(name, style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
            Text(tier, style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.muted)),
            if (tx.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.link_rounded, size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(tx, style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ],
              ),
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
          Row(
            children: [
              Text('Recent Orders', style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => setState(() => _selectedNav = 1),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('New Order', style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _orderTable(),
        ],
      ),
    );
  }

  Widget _orderTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.5),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
      },
      children: [
        _tableHeader(['Customer', 'Amount', 'Status', 'Date']),
        _tableRow(['St. Mary\'s School', 'Ksh 45,000', 'verified', '15 Mar 2026']),
        _tableRow(['Kariobangi Hardware', 'Ksh 120,000', 'verified', '12 Mar 2026']),
        _tableRow(['Eastlands Academy', 'Ksh 30,000', 'pending', '10 Mar 2026']),
        _tableRow(['Pumani Construction', 'Ksh 80,000', 'verified', '08 Mar 2026']),
        _tableRow(['Donholm Furniture', 'Ksh 25,000', 'pending', '05 Mar 2026']),
        _tableRow(['Umoja Phase 2 Shop', 'Ksh 15,000', 'verified', '01 Mar 2026']),
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
    final status = cols[2];
    final isVerified = status == 'verified';
    return TableRow(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(
                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(cols[0])}&background=0D9488&color=fff&size=100',
                ),
              ),
              const SizedBox(width: 10),
              Text(cols[0], style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
            ],
          ),
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
            child: Text(status, style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: isVerified ? Colors.white : AppColors.warning)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(cols[3], style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.muted)),
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
            Row(
              children: [
                Text('All Orders', style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _selectedNav = 1),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text('New Order', style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
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
      _Cust('St. Mary\'s School', '0712 345 678', 'Ksh 45,000', 6,
          'https://images.unsplash.com/photo-1580582932707-520aed937b7b?w=100&h=100&fit=crop'),
      _Cust('Kariobangi Hardware', '0723 456 789', 'Ksh 120,000', 4,
          'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=100&h=100&fit=crop'),
      _Cust('Eastlands Academy', '0734 567 890', 'Ksh 30,000', 3,
          'https://images.unsplash.com/photo-1580582932707-520aed937b7b?w=100&h=100&fit=crop'),
      _Cust('Pumani Construction', '0745 678 901', 'Ksh 80,000', 5,
          'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=100&h=100&fit=crop'),
      _Cust('Donholm Furniture', '0756 789 012', 'Ksh 25,000', 2,
          'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=100&h=100&fit=crop'),
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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage(c.imageUrl),
                      backgroundColor: AppColors.primary.withOpacity(0.1),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(c.total, style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        Text('${c.payments} payments', style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.muted)),
                      ],
                    ),
                  ],
                ),
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
                                      : LinearGradient(colors: [
                                          AppColors.primary.withOpacity(0.3),
                                          AppColors.primary.withOpacity(0.2),
                                        ]),
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
          Row(
            children: [
              _revenueStat('Total Collected', 'Ksh 2,400,000'),
              const SizedBox(width: 16),
              _revenueStat('Average Order', 'Ksh 50,000'),
              const SizedBox(width: 16),
              _revenueStat('Best Month', 'March 2026'),
            ],
          ),
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
            Row(
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
              ],
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
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.inter(
              fontSize: 14, color: AppColors.muted)),
          const Spacer(),
          Text(value, style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // NEW ORDER
  // ═══════════════════════════════════════
  Widget _newOrderBody() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
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
            _field('Customer name', Icons.person_rounded, nameCtrl),
            const SizedBox(height: 16),
            _field('Amount (Ksh)', Icons.payments_rounded, amountCtrl, keyboard: TextInputType.number),
            const SizedBox(height: 16),
            _field('Order description', Icons.receipt_rounded, descCtrl),
            const SizedBox(height: 16),
            Text('Payment method', style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                _payChip('M-Pesa STK', true),
                _payChip('SasaPay Link', false),
                _payChip('Till Number', false),
                _payChip('Paybill', false),
                _payChip('Card', false),
                _payChip('Airtel', false),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
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

  Widget _field(String hint, IconData icon, TextEditingController ctrl,
      {TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.muted.withOpacity(0.5), fontSize: 14),
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
  // USSD SIMULATOR
  // ═══════════════════════════════════════
  Widget _ussdBody() {
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
            Row(
              children: [
                Icon(Icons.phone_android_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Text('USSD Simulator', style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Shortcode 14434 · *384*123#', style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.muted)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Phone: 0715 641 339', style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text)),
                  const SizedBox(height: 12),
                  Text('Dial *384*123# to start session', style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.muted)),
                  const SizedBox(height: 16),
                  _ussdMenuItem('1', 'Clock In'),
                  _ussdMenuItem('2', 'Clock Out'),
                  _ussdMenuItem('3', 'View Balance'),
                  _ussdMenuItem('4', 'Report Safety Incident'),
                  _ussdMenuItem('5', 'View Announcements'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.08), AppColors.primary.withOpacity(0.04)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('PIN: 1234 · Demo mode active', style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.primary)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ussdMenuItem(String num, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.deep]),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(child: Text(num, style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white))),
          ),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // BULK SMS
  // ═══════════════════════════════════════
  Widget _bulkSmsBody() {
    final msgCtrl = TextEditingController(
        text: 'Dear {name}, your payment of Ksh {amount} for order #{order} is due on {date}. Pay now: {link}');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(28),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sms_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Text('Bulk SMS', style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
              ],
            ),
            const SizedBox(height: 6),
            Text("Send payment reminders via Africa's Talking", style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.muted)),
            const SizedBox(height: 20),
            Text('Recipients', style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
            const SizedBox(height: 8),
            TextField(
              maxLines: 3,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Paste phone numbers, one per line:\n0712345678\n0723456789\n0734567890',
                hintStyle: GoogleFonts.inter(color: AppColors.muted.withOpacity(0.5), fontSize: 13),
                filled: true,
                fillColor: Colors.white,
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
            const SizedBox(height: 16),
            Text('Message template', style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
            const SizedBox(height: 8),
            TextField(
              controller: msgCtrl,
              maxLines: 4,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
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
            Wrap(
              spacing: 6, runSpacing: 6,
              children: [
                _tag('{name}'), _tag('{amount}'), _tag('{order}'), _tag('{date}'), _tag('{link}'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('SMS sent to 12 customers!', style: GoogleFonts.inter()),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text('Send Bulk SMS', style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
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

  // ═══════════════════════════════════════
  // BADGES (dedicated page)
  // ═══════════════════════════════════════
  Widget _badgesBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payer score hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.deep, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UNIVERSAL PAYER SCORE', style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('847', style: GoogleFonts.inter(
                              fontSize: 56, fontWeight: FontWeight.w900, color: Colors.white)),
                          Text(' / 1000', style: GoogleFonts.inter(
                              fontSize: 24, color: Colors.white70)),
                        ],
                      ),
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
                  ),
                ),
                Column(
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(child: Text('🥈', style: TextStyle(fontSize: 50))),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Badges grid
          Row(
            children: [
              _largeBadge('🥇', '6-Month Payer', 'Silver', true, '0x7e8b...c4d2',
                  'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=300&h=300&fit=crop'),
              const SizedBox(width: 16),
              _largeBadge('🥈', '3-Month Payer', 'Bronze', true, '0x3f2a...b91c',
                  'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=300&h=300&fit=crop'),
              const SizedBox(width: 16),
              _largeBadge('🏆', '12-Month Payer', 'Gold', false, '',
                  'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=300&h=300&fit=crop'),
            ],
          ),
          const SizedBox(height: 16),

          // Agentic engine
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('AGENTIC ENGINE', style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 14),
                _trustRow('Status', 'Active — evaluating daily'),
                _trustRow('Next Evaluation', 'Tomorrow 00:00 UTC'),
                _trustRow('Gold Eligibility', '2 months away'),
                _trustRow('Next Badge Unlock', '3-Month Streak'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _largeBadge(String emoji, String name, String tier, bool active, String tx, String imageUrl) {
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
          boxShadow: active
              ? [BoxShadow(color: AppColors.gold.withOpacity(0.1), blurRadius: 12)]
              : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                ),
                color: active ? AppColors.gold.withOpacity(0.1) : AppColors.border.withOpacity(0.3),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 48))),
            ),
            const SizedBox(height: 14),
            Text(name, style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
            Text(tier, style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.muted)),
            if (tx.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
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
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _trustRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
          const Spacer(),
          Text(value, style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
        ],
      ),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
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

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _Cust {
  final String name, phone, total, imageUrl;
  final int payments;
  _Cust(this.name, this.phone, this.total, this.payments, this.imageUrl);
}
