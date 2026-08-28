import 'dart:async';
import 'dart:math' as math;
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
    with TickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  bool _scrolled = false;

  late AnimationController _heroFadeController;
  late AnimationController _typewriterController;
  late Animation<double> _heroFade;
  late Animation<int> _typewriter;

  late AnimationController _orbController1;
  late AnimationController _orbController2;
  late AnimationController _orbController3;

  int _visibleNavItems = 0;

  static const _heroText = 'Turn M-Pesa Chaos Into Revenue Proof';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final s = _scroll.offset > 40;
      if (s != _scrolled) setState(() => _scrolled = s);
    });

    _heroFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _heroFade = CurvedAnimation(
      parent: _heroFadeController,
      curve: Curves.easeOutCubic,
    );
    _heroFadeController.forward();

    _typewriterController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _heroText.length * 50),
    );
    _typewriter = IntTween(begin: 0, end: _heroText.length).animate(
      CurvedAnimation(parent: _typewriterController, curve: Curves.linear),
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _typewriterController.forward();
    });

    _orbController1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _orbController2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _orbController3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _animateNavItems();
  }

  void _animateNavItems() async {
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) setState(() => _visibleNavItems = i + 1);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _heroFadeController.dispose();
    _typewriterController.dispose();
    _orbController1.dispose();
    _orbController2.dispose();
    _orbController3.dispose();
    super.dispose();
  }

  void _goToLogin() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const WebLoginPage()));
  void _goToDemo() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const WebDashboard()));

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
          _socialProof(narrow, pad),
          _howItWorks(narrow, pad),
          _features(narrow, pad),
          _liveDemo(narrow, pad),
          _pricing(narrow, pad),
          _testimonial(narrow, pad),
          _cta(narrow, pad),
          _footer(narrow, pad),
        ],
      ),
    );
  }

  SliverToBoxAdapter _navBar(bool narrow, double pad) {
    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: 16),
        color: _scrolled
            ? Colors.white.withValues(alpha: 0.95)
            : Colors.transparent,
        child: Row(
          children: [
            Image.asset(AppAssets.logoFull, height: 40),
            const Spacer(),
            if (!narrow) ...[
              for (int i = 0; i < _visibleNavItems && i < 3; i++)
                _navLink(['How It Works', 'Features', 'Pricing'][i]),
              const SizedBox(width: 16),
            ],
            ElevatedButton(
              onPressed: _goToLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Get Started',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
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
          child: Text(text,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text)),
        ),
      );

  SliverToBoxAdapter _hero(bool narrow, double pad) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: Listenable.merge([_heroFade, _typewriterController, _orbController1]),
        builder: (context, _) {
          return Container(
            padding:
                EdgeInsets.symmetric(horizontal: pad, vertical: narrow ? 60 : 100),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF0FDFA),
                  Colors.white,
                  Color(0xFFF0FDFA),
                ],
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -40,
                  right: narrow ? -60 : 40,
                  child: _floatingOrb(120, AppColors.accent, _orbController1, 0.12),
                ),
                Positioned(
                  top: 60,
                  right: narrow ? 20 : 200,
                  child: _floatingOrb(80, AppColors.gold, _orbController2, 0.10),
                ),
                Positioned(
                  bottom: -20,
                  left: narrow ? -40 : 100,
                  child: _floatingOrb(100, AppColors.primary, _orbController3, 0.08),
                ),
                FadeTransition(
                  opacity: _heroFade,
                  child: narrow
                      ? Column(
                          children: [
                            _heroContent(narrow),
                            const SizedBox(height: 40),
                            _heroImage(),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: _heroContent(narrow)),
                            const SizedBox(width: 60),
                            Expanded(child: _heroImage()),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _floatingOrb(double size, Color color, AnimationController ctrl, double opacity) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        final v = ctrl.value;
        return Transform.translate(
          offset: Offset(0, math.sin(v * math.pi * 2) * 20),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: opacity),
                  color.withValues(alpha: opacity * 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _heroContent(bool narrow) {
    return Column(
      crossAxisAlignment:
          narrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            gradient:
                LinearGradient(colors: [AppColors.primary, AppColors.deep]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: AppColors.accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('AT Hackathon 2026 — Track 3',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AnimatedBuilder(
          animation: _typewriter,
          builder: (context, _) {
            final text = _heroText.substring(0, _typewriter.value);
            return Text(
              text + (_typewriter.value < _heroText.length ? '|' : ''),
              textAlign: narrow ? TextAlign.center : TextAlign.left,
              style: GoogleFonts.inter(
                fontSize: narrow ? 32 : 48,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
                height: 1.1,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          'A jua kali welder in Kariobangi can now walk into a bank with '
          'Ksh 2 million in verified transactions instead of a notebook.',
          textAlign: narrow ? TextAlign.center : TextAlign.left,
          style: GoogleFonts.inter(
              fontSize: 16, color: AppColors.muted, height: 1.6),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment:
              narrow ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            _shimmerButton('Start Free Trial', true),
            const SizedBox(width: 16),
            _shimmerButton('See Demo', false),
          ],
        ),
        const SizedBox(height: 30),
        _AnimatedCounterRow(narrow: narrow),
      ],
    );
  }

  Widget _shimmerButton(String text, bool primary) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: primary
            ? [
                BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: primary ? _goToLogin : _goToDemo,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary ? AppColors.primary : Colors.white,
          side: primary ? null : const BorderSide(color: AppColors.border),
          padding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        ),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: primary ? Colors.white : AppColors.text)),
      ),
    );
  }

  Widget _heroImage() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, 20)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1556742502-ec7c0e9f34b1?w=800&h=600&fit=crop',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(Icons.phone_iphone_rounded,
                    size: 120,
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.deep.withValues(alpha: 0.8)
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 30,
              right: 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _tag('VERIFIED', AppColors.success),
                      const SizedBox(width: 8),
                      _tag('GOLD BADGE', AppColors.gold),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text("Peter's Metal Works",
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  Text('Ksh 2,400,000 verified revenue',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(text,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ]),
      );

  SliverToBoxAdapter _socialProof(bool narrow, double pad) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: 30),
        color: AppColors.deep,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Trusted by 200+ Kenyan businesses',
                style: GoogleFonts.inter(
                    fontSize: narrow ? 14 : 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70)),
            const SizedBox(width: 20),
            if (!narrow) ...[
              _proofBadge('KES 480M+'),
              const SizedBox(width: 12),
              _proofBadge('12,000+ Payments'),
              const SizedBox(width: 12),
              _proofBadge('99.9% Uptime'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _proofBadge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      );

  SliverToBoxAdapter _howItWorks(bool narrow, double pad) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: 80),
        color: AppColors.primary,
        child: Column(children: [
          Text('How It Works',
              style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text('From payment to proof in 5 steps',
              style: GoogleFonts.inter(
                  fontSize: 16, color: Colors.white.withValues(alpha: 0.7))),
          const SizedBox(height: 50),
          narrow
              ? Column(
                  children: _steps()
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 30),
                            child: _stepCard(s),
                          ))
                      .toList())
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _steps()
                      .map((s) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: _stepCard(s),
                            ),
                          ))
                      .toList(),
                ),
        ]),
      ),
    );
  }

  List<_StepData> _steps() => [
        _StepData('1', 'Record Payment',
            'Business owner records a customer payment.', AppColors.gold,
            'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=400&h=300&fit=crop'),
        _StepData('2', 'Generate Link',
            'SasaPay checkout link generated per order.', Colors.white,
            'https://images.unsplash.com/photo-1556745757-8d76bdb6984b?w=400&h=300&fit=crop'),
        _StepData('3', 'Customer Pays',
            'Link shared via WhatsApp or SMS.', AppColors.success,
            'https://images.unsplash.com/photo-1556742111-a301076d9d18?w=400&h=300&fit=crop'),
        _StepData('4', 'Webhook Verifies',
            'SasaPay callback confirms payment.', AppColors.accent,
            'https://images.unsplash.com/photo-1563986768609-322da13575f2?w=400&h=300&fit=crop'),
        _StepData('5', 'Revenue Proof',
            'Verified credit profile emerges.', Colors.white,
            'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=400&h=300&fit=crop'),
      ];

  Widget _stepCard(_StepData s) {
    return _AnimatedCard(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: s.color.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                s.imageUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  color: s.color.withValues(alpha: 0.1),
                  child: Icon(Icons.image_rounded,
                      size: 40,
                      color: s.color.withValues(alpha: 0.4)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [s.color, s.color.withValues(alpha: 0.7)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                        child: Text(s.num,
                            style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: s.num == '2' || s.num == '5'
                                    ? AppColors.primary
                                    : Colors.white))),
                  ),
                  const SizedBox(height: 14),
                  Text(s.title,
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text)),
                  const SizedBox(height: 6),
                  Text(s.desc,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.muted,
                          height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _features(bool narrow, double pad) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: 80),
        child: Column(children: [
          Text('Everything You Need',
              style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text)),
          const SizedBox(height: 8),
          Text('Built for Kenyan businesses',
              style:
                  GoogleFonts.inter(fontSize: 16, color: AppColors.muted)),
          const SizedBox(height: 50),
          narrow
              ? Column(
                  children: _featuresList()
                      .map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _featureCard(f),
                          ))
                      .toList())
              : GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.4,
                  children: _featuresList()
                      .map((f) => _featureCard(f))
                      .toList(),
                ),
        ]),
      ),
    );
  }

  List<_FeatureData> _featuresList() => [
        _FeatureData(Icons.payment_rounded, 'Multi-Rail Payments',
            'M-Pesa, SasaPay, Airtel, Card, Bank.',
            'https://images.unsplash.com/photo-1556742502-ec7c0e9f34b1?w=400&h=300&fit=crop',
            AppColors.primary),
        _FeatureData(Icons.verified_rounded, 'Cryptographic Proof',
            'HMAC-SHA512 signed webhooks.',
            'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=400&h=300&fit=crop',
            AppColors.success),
        _FeatureData(Icons.receipt_long_rounded, 'SMS Receipts',
            "Automatic receipts via Africa's Talking.",
            'https://images.unsplash.com/photo-1596526131083-e8c633c948d2?w=400&h=300&fit=crop',
            AppColors.secondary),
        _FeatureData(Icons.phone_android_rounded, 'USSD Access',
            'Check balance via *384*123#.',
            'https://images.unsplash.com/photo-1423666639041-f56000c27a9a?w=400&h=300&fit=crop',
            AppColors.deep),
        _FeatureData(Icons.stacked_bar_chart_rounded, 'Revenue Dashboard',
            'Bar charts and consistency scores.',
            'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=400&h=300&fit=crop',
            AppColors.gold),
        _FeatureData(Icons.emoji_events_rounded, 'Badge System',
            'Bronze, Silver, Gold on-chain attestation.',
            'https://images.unsplash.com/photo-1622630998477-20aa696ecb05?w=400&h=300&fit=crop',
            AppColors.accent),
      ];

  Widget _featureCard(_FeatureData f) {
    return _AnimatedCard(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: f.color.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                f.imageUrl,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  color: f.color.withValues(alpha: 0.1),
                  child: Icon(f.icon,
                      size: 36,
                      color: f.color.withValues(alpha: 0.4)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [f.color, f.color.withValues(alpha: 0.7)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(f.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 14),
                  Text(f.title,
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text)),
                  const SizedBox(height: 6),
                  Text(f.desc,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.muted,
                          height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _liveDemo(bool narrow, double pad) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: 80),
        color: const Color(0xFFF8FAFC),
        child: Column(children: [
          Text('See It In Action',
              style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text)),
          const SizedBox(height: 8),
          Text('Real-time dashboard with verified revenue tracking',
              style: GoogleFonts.inter(
                  fontSize: 16, color: AppColors.muted)),
          const SizedBox(height: 40),
          _AnimatedCard(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 40,
                      offset: const Offset(0, 20)),
                ],
              ),
              child: Column(children: [
                Row(children: [
                  _demoStat('Ksh 2.4M', 'Revenue', AppColors.primary),
                  const SizedBox(width: 16),
                  _demoStat('48', 'Payments', AppColors.success),
                  const SizedBox(width: 16),
                  _demoStat('94%', 'Consistency', AppColors.gold),
                  const SizedBox(width: 16),
                  _demoStat('87/100', 'Trust', AppColors.deep),
                ]),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Revenue Journey',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.muted)),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                                value: 0.48,
                                minHeight: 12,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                                valueColor:
                                    const AlwaysStoppedAnimation(AppColors.primary)),
                          ),
                          const SizedBox(height: 6),
                          Text('Ksh 2.4M / 5M to Champion',
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Trust Score',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.muted)),
                          const SizedBox(height: 8),
                          Row(children: [
                            Text('87',
                                style: GoogleFonts.inter(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.text)),
                            Text(' / 100',
                                style: GoogleFonts.inter(
                                    fontSize: 14, color: AppColors.muted)),
                          ]),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                AppColors.success,
                                AppColors.success.withValues(alpha: 0.8)
                              ]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('EXCELLENT',
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: _goToDemo,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text('Try Live Demo',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
          ),
        ]),
      ),
    );
  }

  Widget _demoStat(String value, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.muted)),
          ]),
        ),
      );

  SliverToBoxAdapter _pricing(bool narrow, double pad) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: 80),
        color: const Color(0xFF0F172A),
        child: Column(children: [
          Text('Simple Pricing',
              style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text('No transaction fees. SaaS subscription only.',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.6))),
          const SizedBox(height: 50),
          narrow
              ? Column(
                  children: _plans()
                      .map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _planCard(p),
                          ))
                      .toList())
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _plans()
                      .map((p) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: _planCard(p),
                            ),
                          ))
                      .toList(),
                ),
        ]),
      ),
    );
  }

  List<_PlanData> _plans() => [
        _PlanData(
            'Starter',
            'KES 1,500',
            '/month',
            ['1 business', '50 verified payments', 'SMS receipts', 'Basic dashboard'],
            false,
            Icons.rocket_launch_rounded,
            AppColors.muted),
        _PlanData(
            'Growth',
            'KES 3,500',
            '/month',
            ['1 business', '500 verified payments', 'USSD access', 'Credit profile', 'Priority support'],
            true,
            Icons.trending_up_rounded,
            AppColors.primary),
        _PlanData(
            'Enterprise',
            'KES 8,000',
            '/month',
            ['5 businesses', 'Unlimited payments', 'All features', 'API access', 'Dedicated support'],
            false,
            Icons.diamond_rounded,
            AppColors.gold),
      ];

  Widget _planCard(_PlanData p) {
    return _AnimatedCard(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: p.popular ? AppColors.primary : const Color(0xFF334155),
              width: p.popular ? 2 : 1),
          boxShadow: p.popular
              ? [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8)),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.popular)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.deep]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('MOST POPULAR',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            if (p.popular) const SizedBox(height: 12),
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [p.iconColor, p.iconColor.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(p.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(p.name,
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ]),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(p.price,
                  style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary)),
              Text(p.period,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.5))),
            ]),
            const SizedBox(height: 20),
            const Divider(color: Color(0xFF334155)),
            const SizedBox(height: 16),
            for (final f in p.features)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 18, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(f,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: Colors.white70))),
                ]),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _goToLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      p.popular ? AppColors.primary : Colors.white,
                  side: p.popular
                      ? null
                      : const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Get Started',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: p.popular ? Colors.white : AppColors.text)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _testimonial(bool narrow, double pad) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: 80),
        child: _AnimatedCard(
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.deep]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(children: [
              const Icon(Icons.format_quote_rounded,
                  size: 48, color: Colors.white),
              const SizedBox(height: 20),
              Text(
                '"Before TapVerify, I had a notebook of payments. '
                'Now I walk into a bank with Ksh 2.4 million in verified transactions. '
                'They gave me a loan in 3 days instead of 3 months."',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: narrow ? 16 : 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.6),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: const Text('PK',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Peter Kaunda',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      Text('Metal Works, Kariobangi',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _cta(bool narrow, double pad) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: 80),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [AppColors.deep, AppColors.primary, Color(0xFF16A34A)]),
        ),
        child: Column(children: [
          Text('Ready to Verify Your Revenue?',
              style: GoogleFonts.inter(
                  fontSize: narrow ? 24 : 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 12),
          Text('Start free. Upgrade when you grow.',
              style: GoogleFonts.inter(
                  fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 30),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: ElevatedButton(
              onPressed: _goToLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              ),
              child: Text('Get Started Free',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deep)),
            ),
          ),
        ]),
      ),
    );
  }

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
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.white54)),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(AppAssets.logoFull, height: 36),
                  const SizedBox(width: 40),
                  Expanded(child: _footerLinks()),
                  Text('© 2026 TapVerify. All rights reserved.',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.white54)),
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
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 12),
          for (final l in links)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(l,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: Colors.white54)),
            ),
        ],
      );
}

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  const _AnimatedCard({required this.child});
  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _AnimatedCounterRow extends StatefulWidget {
  final bool narrow;
  const _AnimatedCounterRow({required this.narrow});
  @override
  State<_AnimatedCounterRow> createState() => _AnimatedCounterRowState();
}

class _AnimatedCounterRowState extends State<_AnimatedCounterRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final v = _ctrl.value;
        return Row(
          mainAxisAlignment:
              widget.narrow ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            _counter('Ksh ${(2400000 * v).round()}+', 'Verified Revenue'),
            SizedBox(width: widget.narrow ? 20 : 30),
            _counter('${(94 * v).round()}%', 'Consistency'),
            SizedBox(width: widget.narrow ? 20 : 30),
            _counter('${(48 * v).round()}', 'Transactions'),
          ],
        );
      },
    );
  }

  Widget _counter(String value, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
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
  _PlanData(this.name, this.price, this.period, this.features, this.popular,
      this.icon, this.iconColor);
}
