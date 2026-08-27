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
    _NavItem(Icons.receipt_long_rounded, 'Orders'),
    _NavItem(Icons.people_rounded, 'Customers'),
    _NavItem(Icons.bar_chart_rounded, 'Revenue'),
    _NavItem(Icons.shield_rounded, 'Credit Profile'),
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
          // ── SIDEBAR ──
          if (!narrow)
            Container(
              width: 240,
              color: const Color(0xFF0F172A),
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
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
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
                              Text('Business Owner', style: GoogleFonts.inter(
                                  fontSize: 10, color: Colors.white54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── MAIN CONTENT ──
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
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
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('LIVE', style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success)),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.notifications_rounded, size: 20, color: AppColors.muted),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Body
                Expanded(child: _body()),
              ],
            ),
          ),
        ],
      ),
      drawer: narrow
          ? Drawer(
              child: Container(
                color: const Color(0xFF0F172A),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    for (int i = 0; i < _navItems.length; i++)
                      _sidebarTile(i, _navItems[i]),
                  ],
                ),
              ),
            )
          : null,
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

  Widget _body() {
    switch (_selectedNav) {
      case 0: return _dashboardBody();
      case 1: return _ordersBody();
      case 2: return _customersBody();
      case 3: return _revenueBody();
      case 4: return _creditBody();
      case 5: return _settingsBody();
      default: return _dashboardBody();
    }
  }

  // ── DASHBOARD ──
  Widget _dashboardBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            children: [
              _statCard('Total Revenue', 'Ksh 2,400,000', AppColors.primary, Icons.account_balance_rounded),
              const SizedBox(width: 16),
              _statCard('Verified Payments', '48', AppColors.success, Icons.verified_rounded),
              const SizedBox(width: 16),
              _statCard('Consistency', '94%', AppColors.gold, Icons.trending_up_rounded),
              const SizedBox(width: 16),
              _statCard('Customers', '12', AppColors.secondary, Icons.people_rounded),
            ],
          ),
          const SizedBox(height: 24),
          // Recent orders
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent Orders', style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
                const SizedBox(height: 16),
                _orderTable(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
                Text(label, style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── ORDERS ──
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
                  onPressed: () {},
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

  Widget _orderTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
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
    final statusColor = status == 'verified' ? AppColors.success : AppColors.warning;
    return TableRow(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(cols[0], style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
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
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status, style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
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

  // ── CUSTOMERS ──
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
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(c.name[0], style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800, color: AppColors.primary)),
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

  // ── REVENUE ──
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
                                  color: i == 2 ? AppColors.primary : AppColors.primary.withOpacity(0.3),
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

  // ── CREDIT PROFILE ──
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
                    color: AppColors.success,
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
            Text('Ready for lender review.', style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.success)),
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

  // ── SETTINGS ──
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
