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

class _WebLandingPageState extends State<WebLandingPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  bool _scrolled = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => setState(() => _scrolled = _scroll.offset > 40));
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _goToLogin() => Navigator.push(context, MaterialPageRoute(builder: (_) => const WebLoginPage()));
  void _goToDemo() => Navigator.push(context, MaterialPageRoute(builder: (_) => const WebDashboard()));

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
          _navBar(narrow, pad),
          _hero(narrow, pad),
          _howItWorks(narrow, pad),
          _features(narrow, pad),
          _pricing(narrow, pad),
          _cta(narrow, pad),
          _footer(narrow, pad),
        ],
      ),
    );
  }

  // ── NAV ──
  SliverToBoxAdapter _navBar(bool narrow, double pad) {
    return SliverToBoxAdapter(
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
    );
  }

  Widget _navLink(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: TextButton(
      onPressed: _goToLogin,
      child: Text(text, style: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
    ),
  );

  // ── HERO ──
  SliverToBoxAdapter _hero(bool narrow, double pad) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: narrow ? 60 : 100),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0FDFA), Colors.white, Color(0xFFF0FDFA)],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: narrow
              ? Column(children: [_heroContent(narrow), const SizedBox(height: 40), _heroImage()])
              : Row(children: [
                  Expanded(child: _heroContent(narrow)),
                  const SizedBox(width: 60),
                  Expanded(child: _heroImage()),
                ]),
        ),
      ),
    );
  }

  Widget _heroContent(bool narrow) {
    return Column(
      crossAxisAlignment: narrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.deep]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('AT Hackathon 2026 — Track 3', style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 24),
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
            _heroStat('Ksh 2.4M+', 'Verified Revenue'),
            const SizedBox(width: 30),
            _heroStat('94%', 'Consistency'),
            const SizedBox(width: 30),
            _heroStat('48', 'Transactions'),
          ],
        ),
      ],
    );
  }

  Widget _heroStat(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
    ],
  );

  Widget _heroImage() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 40, offset: const Offset(0, 20)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=800&h=600&fit=crop',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.primary.withOpacity(0.1),
                child: Icon(Icons.phone_iphone_rounded, size: 120, color: AppColors.primary.withOpacity(0.3)),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.deep.withOpacity(0.8)],
                ),
              ),
            ),
            Positioned(
              bottom: 30, left: 30, right: 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          const Icon(Icons.check_circle, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('VERIFIED', style: GoogleFonts.inter(
                              fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('GOLD BADGE', style: GoogleFonts.inter(
                            fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text("Peter's Metal Works", style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('Ksh 2,400,000 verified revenue', style: GoogleFonts.inter(
                      fontSize: 13, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HOW IT WORKS ──
  SliverToBoxAdapter _howItWorks(bool narrow, double pad) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: 80),
        color: const Color(0xFFF8FAFC),
        child: Column(children: [
          Text('How It Works', style: GoogleFonts.inter(
              fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 8),
          Text('From payment to proof in 5 steps', style: GoogleFonts.inter(
              fontSize: 16, color: AppColors.muted)),
          const SizedBox(height: 50),
          narrow
              ? Column(children: _steps().map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: _stepCard(s),
                )).toList())
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _steps().map((s) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _stepCard(s),
                    ),
                  )).toList(),
                ),
        ]),
      ),
    );
  }

  List<_StepData> _steps() => [
    _StepData('1', 'Record Payment', 'Business owner records a customer payment.', AppColors.primary,
        'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=400&h=300&fit=crop'),
    _StepData('2', 'Generate Link', 'SasaPay checkout link generated per order.', AppColors.secondary,
        'https://images.unsplash.com/photo-1556745753-b2904692b3cd?w=400&h=300&fit=crop'),
    _StepData('3', 'Customer Pays', 'Link shared via WhatsApp or SMS.', AppColors.success,
        'https://images.unsplash.com/photo-1611262588024-d25151a65097?w=400&h=300&fit=crop'),
    _StepData('4', 'Webhook Verifies', 'SasaPay callback confirms payment.', AppColors.deep,
        'https://images.unsplash.com/photo-1563013544-824ae1b704d3?w=400&h=300&fit=crop'),
    _StepData('5', 'Revenue Proof', 'Verified credit profile emerges.', AppColors.gold,
        'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=400&h=300&fit=crop'),
  ];

  Widget _stepCard(_StepData s) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              s.imageUrl,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 140,
                color: s.color.withOpacity(0.1),
                child: Icon(Icons.image_rounded, size: 40, color: s.color.withOpacity(0.4)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [s.color, s.color.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text(s.num, style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white))),
                ),
                const SizedBox(height: 14),
                Text(s.title, style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
                const SizedBox(height: 6),
                Text(s.desc, style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.muted, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── FEATURES ──
  SliverToBoxAdapter _features(bool narrow, double pad) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: 80),
        child: Column(children: [
          Text('Everything You Need', style: GoogleFonts.inter(
              fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 8),
          Text('Built for Kenyan businesses', style: GoogleFonts.inter(
              fontSize: 16, color: AppColors.muted)),
          const SizedBox(height: 50),
          narrow
              ? Column(children: _featuresList().map((f) => Padding(
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
                  children: _featuresList().map((f) => _featureCard(f)).toList(),
                ),
        ]),
      ),
    );
  }

  List<_FeatureData> _featuresList() => [
    _FeatureData(Icons.payment_rounded, 'Multi-Rail Payments', 'M-Pesa, SasaPay, Airtel, Card, Bank.',
        'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=400&h=300&fit=crop', AppColors.primary),
    _FeatureData(Icons.verified_rounded, 'Cryptographic Proof', 'HMAC-SHA512 signed webhooks.',
        'https://images.unsplash.com/photo-1563013544-824ae1b704d3?w=400&h=300&fit=crop', AppColors.success),
    _FeatureData(Icons.receipt_long_rounded, 'SMS Receipts', "Automatic receipts via Africa's Talking.",
        'https://images.unsplash.com/photo-1611262588024-d25151a65097?w=400&h=300&fit=crop', AppColors.secondary),
    _FeatureData(Icons.phone_android_rounded, 'USSD Access', 'Check balance via *384*123#.',
        'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?w=400&h=300&fit=crop', AppColors.deep),
    _FeatureData(Icons.stacked_bar_chart_rounded, 'Revenue Dashboard', 'Bar charts and consistency scores.',
        'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=400&h=300&fit=crop', AppColors.gold),
    _FeatureData(Icons.emoji_events_rounded, 'Badge System', 'Bronze, Silver, Gold on-chain attestation.',
        'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=400&h=300&fit=crop', AppColors.accent),
  ];

  Widget _featureCard(_FeatureData f) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              f.imageUrl,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 100,
                color: f.color.withOpacity(0.1),
                child: Icon(f.icon, size: 36, color: f.color.withOpacity(0.4)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [f.color, f.color.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(f.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 14),
                Text(f.title, style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
                const SizedBox(height: 6),
                Text(f.desc, style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.muted, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── PRICING ──
  SliverToBoxAdapter _pricing(bool narrow, double pad) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: 80),
        color: const Color(0xFFF8FAFC),
        child: Column(children: [
          Text('Simple Pricing', style: GoogleFonts.inter(
              fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 8),
          Text('No transaction fees. SaaS subscription only.', style: GoogleFonts.inter(
              fontSize: 16, color: AppColors.muted)),
          const SizedBox(height: 50),
          narrow
              ? Column(children: _plans().map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _planCard(p),
                )).toList())
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _plans().map((p) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _planCard(p),
                    ),
                  )).toList(),
                ),
        ]),
      ),
    );
  }

  List<_PlanData> _plans() => [
    _PlanData('Starter', 'KES 1,500', '/month', [
      '1 business', '50 verified payments', 'SMS receipts', 'Basic dashboard',
    ], false, Icons.rocket_launch_rounded, AppColors.muted),
    _PlanData('Growth', 'KES 3,500', '/month', [
      '1 business', '500 verified payments', 'USSD access', 'Credit profile', 'Priority support',
    ], true, Icons.trending_up_rounded, AppColors.primary),
    _PlanData('Enterprise', 'KES 8,000', '/month', [
      '5 businesses', 'Unlimited payments', 'All features', 'API access', 'Dedicated support',
    ], false, Icons.diamond_rounded, AppColors.gold),
  ];

  Widget _planCard(_PlanData p) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: p.popular ? AppColors.primary : AppColors.border,
            width: p.popular ? 2 : 1),
        boxShadow: p.popular
            ? [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))]
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.popular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.deep]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('MOST POPULAR', style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          if (p.popular) const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [p.iconColor, p.iconColor.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(p.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(p.name, style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
            ],
          ),
          const SizedBox(height: 12),
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

  // ── CTA ──
  SliverToBoxAdapter _cta(bool narrow, double pad) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: 80),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.deep, AppColors.primary]),
        ),
        child: Column(children: [
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
        ]),
      ),
    );
  }

  // ── FOOTER ──
  SliverToBoxAdapter _footer(bool narrow, double pad) {
    return SliverToBoxAdapter(
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
    );
  }

  Widget _footerLinks() => Wrap(
    spacing: 30,
    runSpacing: 12,
    children: [
      _footerCol('Product', ['Features', 'Pricing', 'Dashboard', 'API']),
      _footerCol('Company', ['About', 'Blog', 'Careers', 'Contact']),
      _footerCol('Legal', ['Privacy', 'Terms', 'Security']),
    ],
  );

  Widget _footerCol(String title, List<String> links) => Column(
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

class _StepData {
  final String num, title, desc, imageUrl;
  final Color color;
  _StepData(this.num, this.title, this.desc, this.color, this.imageUrl);
}

class _FeatureData {
  final IconData icon;
  final String title, desc, imageUrl;
  final Color color;
  _FeatureData(this.icon, this.title, this.desc, this.imageUrl, this.color);
}

class _PlanData {
  final String name, price, period;
  final List<String> features;
  final bool popular;
  final IconData icon;
  final Color iconColor;
  _PlanData(this.name, this.price, this.period, this.features, this.popular, this.icon, this.iconColor);
}
