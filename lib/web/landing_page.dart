import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'web_login.dart';
import 'web_dashboard.dart';

class WebLandingPage extends StatefulWidget {
  const WebLandingPage({super.key});
  @override
  State<WebLandingPage> createState() => _WebLandingPageState();
}

class _WebLandingPageState extends State<WebLandingPage> {
  final ScrollController _scroll = ScrollController();
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      setState(() => _scrolled = _scroll.offset > 40);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const WebLoginPage()));
  }

  void _goToDemo() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const WebDashboard()));
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final narrow = w < 800;
    final pad = narrow ? 20.0 : 60.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          // ── NAV BAR ──
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: pad, vertical: 16),
              color: _scrolled ? Colors.white : Colors.transparent,
              child: Row(
                children: [
                  Image.asset(AppAssets.logoFull, height: 40),
                  const Spacer(),
                  if (!narrow) ...[
                    _navLink('How It Works'),
                    _navLink('Features'),
                    _navLink('Pricing'),
                    const SizedBox(width: 16),
                  ],
                  ElevatedButton(
                    onPressed: _goToLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text('Get Started', style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),

          // ── HERO ──
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: pad, vertical: narrow ? 60 : 100),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF0FDFA), Colors.white],
                ),
              ),
              child: narrow
                  ? Column(
                      children: [
                        _heroContent(narrow),
                        const SizedBox(height: 40),
                        _heroImage(narrow),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _heroContent(narrow)),
                        const SizedBox(width: 60),
                        Expanded(child: _heroImage(narrow)),
                      ],
                    ),
            ),
          ),

          // ── HOW IT WORKS ──
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: pad, vertical: 80),
              color: const Color(0xFFF8FAFC),
              child: Column(
                children: [
                  Text('How It Works', style: GoogleFonts.inter(
                      fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.text)),
                  const SizedBox(height: 8),
                  Text('From payment to proof in 5 steps', style: GoogleFonts.inter(
                      fontSize: 16, color: AppColors.muted)),
                  const SizedBox(height: 50),
                  narrow
                      ? Column(children: _steps().map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 30),
                          child: _stepCard(s, narrow),
                        )).toList())
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _steps().map((s) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: _stepCard(s, narrow),
                            ),
                          )).toList(),
                        ),
                ],
              ),
            ),
          ),

          // ── FEATURES ──
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: pad, vertical: 80),
              child: Column(
                children: [
                  Text('Everything You Need', style: GoogleFonts.inter(
                      fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.text)),
                  const SizedBox(height: 8),
                  Text('Built for Kenyan businesses', style: GoogleFonts.inter(
                      fontSize: 16, color: AppColors.muted)),
                  const SizedBox(height: 50),
                  narrow
                      ? Column(children: _features().map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _featureCard(f),
                        )).toList())
                      : GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 1.4,
                          children: _features().map((f) => _featureCard(f)).toList(),
                        ),
                ],
              ),
            ),
          ),

          // ── PRICING ──
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: pad, vertical: 80),
              color: const Color(0xFFF8FAFC),
              child: Column(
                children: [
                  Text('Simple Pricing', style: GoogleFonts.inter(
                      fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.text)),
                  const SizedBox(height: 8),
                  Text('No transaction fees. SaaS subscription only.', style: GoogleFonts.inter(
                      fontSize: 16, color: AppColors.muted)),
                  const SizedBox(height: 50),
                  narrow
                      ? Column(children: _plans().map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _planCard(p, narrow),
                        )).toList())
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _plans().map((p) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: _planCard(p, narrow),
                            ),
                          )).toList(),
                        ),
                ],
              ),
            ),
          ),

          // ── CTA ──
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: pad, vertical: 80),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.deep, AppColors.primary]),
              ),
              child: Column(
                children: [
                  Text('Ready to Verify Your Revenue?',
                      style: GoogleFonts.inter(
                          fontSize: narrow ? 24 : 36, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 12),
                  Text('Start free. Upgrade when you grow.',
                      style: GoogleFonts.inter(fontSize: 16, color: Colors.white70)),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _goToLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                    ),
                    child: Text('Get Started Free', style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.deep)),
                  ),
                ],
              ),
            ),
          ),

          // ── FOOTER ──
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: pad, vertical: 40),
              color: const Color(0xFF0F172A),
              child: narrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(AppAssets.logoFull, height: 36),
                        const SizedBox(height: 20),
                        _footerLinks(),
                        const SizedBox(height: 20),
                        Text('© 2026 TapVerify. All rights reserved.',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(AppAssets.logoFull, height: 36),
                        const SizedBox(width: 40),
                        Expanded(child: _footerLinks()),
                        Text('© 2026 TapVerify. All rights reserved.',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navLink(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton(
        onPressed: _goToLogin,
        child: Text(text, style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
      ),
    );
  }

  Widget _heroContent(bool narrow) {
    return Column(
      crossAxisAlignment: narrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('Built for Kenyan SMEs', style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ),
        const SizedBox(height: 20),
        Text('Turn M-Pesa Chaos\nInto Revenue Proof',
            textAlign: narrow ? TextAlign.center : TextAlign.left,
            style: GoogleFonts.inter(
                fontSize: narrow ? 32 : 48, fontWeight: FontWeight.w900,
                color: AppColors.text, height: 1.1)),
        const SizedBox(height: 16),
        Text(
          'A jua kali welder in Kariobangi can now walk into a bank with '
          'Ksh 2 million in verified transactions instead of a notebook.',
          textAlign: narrow ? TextAlign.center : TextAlign.left,
          style: GoogleFonts.inter(fontSize: 16, color: AppColors.muted, height: 1.6),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: narrow ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _goToLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              ),
              child: Text('Start Free Trial', style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: _goToDemo,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              ),
              child: Text('See Demo', style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: narrow ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            _stat('Ksh 2.4M+', 'Verified Revenue'),
            const SizedBox(width: 30),
            _stat('94%', 'Consistency Score'),
            const SizedBox(width: 30),
            _stat('48', 'Verified Payments'),
          ],
        ),
      ],
    );
  }

  Widget _heroImage(bool narrow) {
    return Container(
      height: narrow ? 250 : 400,
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Center(
        child: Image.asset(
          AppAssets.logoFull,
          width: narrow ? 180 : 280,
          errorBuilder: (_, __, ___) => Icon(Icons.shield_rounded,
              size: 120, color: AppColors.primary.withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
      ],
    );
  }

  List<_StepData> _steps() => [
    _StepData('1', 'Record Payment', 'Business owner records a customer payment.', AppColors.primary),
    _StepData('2', 'Generate Link', 'SasaPay checkout link generated per order.', AppColors.secondary),
    _StepData('3', 'Customer Pays', 'Link shared via WhatsApp or SMS.', AppColors.success),
    _StepData('4', 'Webhook Verifies', 'SasaPay callback confirms payment.', AppColors.deep),
    _StepData('5', 'Revenue Proof', 'Verified credit profile emerges.', AppColors.gold),
  ];

  Widget _stepCard(_StepData s, bool narrow) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: s.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(s.num, style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w800, color: s.color)),
            ),
          ),
          const SizedBox(height: 16),
          Text(s.title, style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 8),
          Text(s.desc, style: GoogleFonts.inter(
              fontSize: 14, color: AppColors.muted, height: 1.5)),
        ],
      ),
    );
  }

  List<_FeatureData> _features() => [
    _FeatureData(Icons.payment_rounded, 'Multi-Rail Payments', 'M-Pesa, SasaPay, Airtel, Card, Bank.'),
    _FeatureData(Icons.verified_rounded, 'Cryptographic Proof', 'HMAC-SHA512 signed webhooks.'),
    _FeatureData(Icons.receipt_long_rounded, 'SMS Receipts', 'Automatic receipts via Africa\'s Talking.'),
    _FeatureData(Icons.phone_android_rounded, 'USSD Access', 'Check balance via *384*123#.'),
    _FeatureData(Icons.stacked_bar_chart_rounded, 'Revenue Dashboard', 'Bar charts and consistency scores.'),
    _FeatureData(Icons.shield_rounded, 'Credit Profile', 'Verified revenue for loan applications.'),
  ];

  Widget _featureCard(_FeatureData f) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(f.icon, color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 16),
          Text(f.title, style: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 8),
          Text(f.desc, style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.muted, height: 1.5)),
        ],
      ),
    );
  }

  List<_PlanData> _plans() => [
    _PlanData('Starter', 'KES 1,500', '/month', [
      '1 business', '50 verified payments', 'SMS receipts', 'Basic dashboard',
    ], false),
    _PlanData('Growth', 'KES 3,500', '/month', [
      '1 business', '500 verified payments', 'USSD access', 'Credit profile', 'Priority support',
    ], true),
    _PlanData('Enterprise', 'KES 8,000', '/month', [
      '5 businesses', 'Unlimited payments', 'All features', 'API access', 'Dedicated support',
    ], false),
  ];

  Widget _planCard(_PlanData p, bool narrow) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: p.popular ? AppColors.primary : AppColors.border,
            width: p.popular ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.popular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('MOST POPULAR', style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          if (p.popular) const SizedBox(height: 12),
          Text(p.name, style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(p.price, style: GoogleFonts.inter(
                fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary)),
            Text(p.period, style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.muted)),
          ]),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),
          for (final f in p.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(child: Text(f, style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.text))),
              ]),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _goToLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: p.popular ? AppColors.primary : Colors.white,
                side: p.popular ? null : const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('Get Started', style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: p.popular ? Colors.white : AppColors.text)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerLinks() {
    return Wrap(
      spacing: 30,
      runSpacing: 12,
      children: [
        _footerCol('Product', ['Features', 'Pricing', 'Dashboard', 'API']),
        _footerCol('Company', ['About', 'Blog', 'Careers', 'Contact']),
        _footerCol('Legal', ['Privacy', 'Terms', 'Security']),
      ],
    );
  }

  Widget _footerCol(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 12),
        for (final l in links)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(l, style: GoogleFonts.inter(
                fontSize: 13, color: Colors.white54)),
          ),
      ],
    );
  }
}

class _StepData {
  final String num, title, desc;
  final Color color;
  _StepData(this.num, this.title, this.desc, this.color);
}

class _FeatureData {
  final IconData icon;
  final String title, desc;
  _FeatureData(this.icon, this.title, this.desc);
}

class _PlanData {
  final String name, price, period;
  final List<String> features;
  final bool popular;
  _PlanData(this.name, this.price, this.period, this.features, this.popular);
}
