import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../widgets/app_feedback.dart';
import 'legal_screen.dart';
import 'login_screen.dart';

/// Public marketing page: what a visitor sees before logging in.
/// Sells the one job TapVerify does: knowing who has paid.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  static const int _sectionCount = 9;

  late final AnimationController _controller;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _howItWorksKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );

    // A settled, overshoot free entrance reads as more trustworthy than a
    // bouncy one, and it keeps the curve vocabulary consistent with the app.
    _fadeAnimations = List.generate(
      _sectionCount,
      (i) => CurvedAnimation(
        parent: _controller,
        curve: Interval(
          (i * 0.07).clamp(0.0, 0.6),
          (0.55 + i * 0.06).clamp(0.0, 1.0),
          curve: AppMotion.enter,
        ),
      ),
    );

    _slideAnimations = List.generate(
      _sectionCount,
      (i) => Tween<Offset>(
        begin: const Offset(0, 0.14),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(
          (i * 0.07).clamp(0.0, 0.6),
          (0.55 + i * 0.06).clamp(0.0, 1.0),
          curve: AppMotion.enter,
        ),
      )),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If the session was restored (or a login completed elsewhere), the root
    // now shows Home. Step aside so two screens are never stacked.
    if (AuthState.signedIn.value && Navigator.of(context).canPop()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    }
  }

  /// "See how it works" should actually show how it works, not open login.
  void _scrollToHowItWorks() {
    final target = _howItWorksKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: AppMotion.slow,
      curve: AppMotion.enter,
    );
  }

  void _openLogin() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: AppMotion.enter)),
            child: child,
          ),
        ),
        transitionDuration: AppMotion.medium,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              const BackendWarningBanner(),
              _buildAnimatedSection(0, _NavBar(onLogin: _openLogin)),
              _buildAnimatedSection(
                1,
                _Hero(onLogin: _openLogin, onSeeHowItWorks: _scrollToHowItWorks),
              ),
              _buildAnimatedSection(2, const _Problem()),
              _buildAnimatedSection(3, const _RealPeople()),
              _buildAnimatedSection(
                4,
                _HowItWorks(key: _howItWorksKey),
              ),
              _buildAnimatedSection(5, const _LiveDemo()),
              _buildAnimatedSection(6, const _DetectionTable()),
              _buildAnimatedSection(7, const _MemberExperience()),
              _buildAnimatedSection(8, const _Footer()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSection(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(
        position: _slideAnimations[index],
        child: child,
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: kHairline)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              const Expanded(child: _LogoChip(onDark: false)),
              const SizedBox(width: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onLogin,
                child: const Text('Secretary Login',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Brand lock up. The wordmark colour is a parameter because the footer needs
/// it on a dark background, where the old hardcoded near black was invisible.
class _LogoChip extends StatelessWidget {
  const _LogoChip({required this.onDark});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: onDark ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: AppLogo(height: 26, onDark: onDark),
        ),
        if (!onDark) ...[
          const SizedBox(width: 10),
          const Flexible(
            child: Text(
              'TapVerify',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: kBrandInk,
                letterSpacing: -0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _Hero extends StatefulWidget {
  const _Hero({required this.onLogin, required this.onSeeHowItWorks});

  final VoidCallback onLogin;
  final VoidCallback onSeeHowItWorks;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    // A single settle instead of an endless pulse: the old version repeated
    // forever, so the app kept re-rasterising a 300px radial gradient for as
    // long as the landing page was on screen.
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..forward();
    _glowAnimation = Tween<double>(begin: 0.28, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.enter),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 860;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: wide ? 80 : 48),
      // Very light green wash from the left, fading into clean white.
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [kPrimaryLight, Colors.white, Colors.white],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Stack(
            children: [
              // Soft brand glow. Isolated so its animation does not repaint
              // the rest of the hero.
              Positioned(
                top: -100,
                right: -100,
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) => Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            kPrimary.withValues(alpha: _glowAnimation.value * 0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Soft light green curve at the bottom left of the hero.
              Positioned(
                bottom: -110,
                left: -110,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: kPrimaryLight,
                  ),
                ),
              ),
              Column(
                children: [
                  Flex(
                    direction: wide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: wide
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: wide ? 6 : 0,
                        child: Column(
                          crossAxisAlignment: wide
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(color: kPrimaryBorder, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: kPrimary.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: kPrimary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Built for Kenyan chamas, welfare & school groups',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Stop asking people\nif they have paid.',
                              textAlign: wide ? TextAlign.left : TextAlign.center,
                              style: TextStyle(
                                fontSize: wide ? 52 : 42,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                color: kBrandInk,
                                letterSpacing: -1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [kPrimary, kPrimaryDark],
                              ).createShader(bounds),
                              child: Text(
                                'Open this and see.',
                                textAlign: wide ? TextAlign.left : TextAlign.center,
                                style: TextStyle(
                                  fontSize: wide ? 52 : 42,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                  color: Colors.white,
                                  letterSpacing: -1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'One live list for your chama, welfare group or school '
                              'collection: who has paid, who has not, and how much is '
                              'still out. Digital payments appear automatically.',
                              textAlign: wide ? TextAlign.left : TextAlign.center,
                              style: TextStyle(fontSize: 18, color: Colors.grey[700],
                                  height: 1.6, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 32),
                            // Wrap, not Row: two full-width labels cannot fit
                            // side by side on a 360dp phone.
                            Wrap(
                              alignment: wide ? WrapAlignment.start : WrapAlignment.center,
                              spacing: 14,
                              runSpacing: 12,
                              children: [
                                FilledButton(
                                  onPressed: widget.onLogin,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                                    backgroundColor: kPrimary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                    shadowColor: kPrimary.withValues(alpha: 0.4),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Start Collecting for Free', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward, size: 20),
                                    ],
                                  ),
                                ),
                                // Secondary: white with a green border, green
                                // label and a play icon.
                                OutlinedButton.icon(
                                  onPressed: widget.onSeeHowItWorks,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                                    side: const BorderSide(color: kPrimary, width: 1.6),
                                    foregroundColor: kPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                                  label: const Text('See How It Works',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: wide ? 48 : 0, height: wide ? 0 : 40),
                      Expanded(
                        flex: wide ? 5 : 0,
                        child: const Center(child: _HeroArt()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  const _FeatureBar(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hero artwork: the brand phone mockup with the torn-paper portrait of a
/// member overlapping it in front, plus a small payment-detected chip, laid
/// out exactly like the brand artwork.
class _HeroArt extends StatelessWidget {
  const _HeroArt();

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 470,
        height: 600,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Light green shape giving the composition a soft base.
            Positioned(
              left: 0,
              bottom: 24,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimaryLight,
                ),
              ),
            ),
            // Phone mockup photo, lightly rounded with a deep soft shadow.
            Positioned(
              right: 8,
              top: 24,
              child: Container(
                width: 300,
                height: 540,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 44,
                      offset: const Offset(0, 22),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: Image.asset(
                    'assets/images/phone_mockup.png',
                    fit: BoxFit.cover,
                    semanticLabel: 'The TapVerify app open on a phone',
                  ),
                ),
              ),
            ),
            // Member portrait with the torn-paper edge, in front of the phone.
            Positioned(
              left: 0,
              bottom: 34,
              width: 372,
              child: Image.asset(
                'assets/images/hero_woman.png',
                fit: BoxFit.contain,
                cacheWidth: (372 * dpr).round(),
                semanticLabel: 'A member smiling at her phone',
              ),
            ),
            // Small proof chip floating over the phone.
            Positioned(
              left: 0,
              top: 76,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kPrimaryBorder, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 18, color: kSuccess),
                    SizedBox(width: 8),
                    Text(
                      'Payment detected - KES 500',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: kBrandInk,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Four quick trust signals in one clean white bar under the hero.
class _FeatureBar extends StatelessWidget {
  const _FeatureBar();

  static const _items = [
    (Icons.shield_outlined, 'Protected', 'Your collection data stays private.'),
    (Icons.bolt_outlined, 'Auto-detected', 'Till and Paybill payments mark themselves.'),
    (Icons.people_outline, 'No app needed', 'Members pay from one SMS link.'),
    (Icons.sms_outlined, 'Always in the loop', 'Reminders and receipts by SMS.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth > 820 ? 4 : (c.maxWidth > 480 ? 2 : 1);
          final width = (c.maxWidth - (cols - 1) * 12) / cols;
          return Wrap(
            spacing: 12,
            runSpacing: 20,
            children: [
              for (final (icon, title, subtitle) in _items)
                SizedBox(
                  width: width,
                  child: _FeatureItem(
                    icon: icon,
                    title: title,
                    subtitle: subtitle,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: kPrimaryLight,
          ),
          child: Icon(icon, size: 26, color: kPrimary),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: kBrandInk,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem();

  static const _pains = [
    ('"Umelipa?"', 'The question every secretary is tired of asking.'),
    ('"Tuma screenshot"', 'Screenshots get lost in WhatsApp within a day.'),
    ('"Nililipa cash"', 'Someone claims they paid. The notebook disagrees.'),
    ('Arguments', 'M-Pesa messages and the notebook never match.'),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Every month, the same chase',
      subtitle: 'Chamas, factory welfare groups, school contributions: '
          'secretaries waste hours chasing people for proof of payment.',
      child: LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth > 860 ? 4 : (c.maxWidth > 560 ? 2 : 1);
          // A fixed aspect ratio made single-column cards far too short and
          // they overflowed. Let each card size itself instead.
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (var i = 0; i < _pains.length; i++)
                SizedBox(
                  width: cols == 1
                      ? c.maxWidth
                      : (c.maxWidth - (cols - 1) * 16) / cols,
                  child: FadeSlideIn(
                    delay: AppMotion.stagger(i, stepMs: 70, capMs: 210),
                    offset: 24,
                    child: _PainCard(title: _pains[i].$1, body: _pains[i].$2),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PainCard extends StatefulWidget {
  const _PainCard({required this.title, required this.body});
  final String title;
  final String body;

  @override
  State<_PainCard> createState() => _PainCardState();
}

class _PainCardState extends State<_PainCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _hovered ? const Color(0xFF00A86B) : const Color(0xFFE5E7EB), width: _hovered ? 2 : 1),
          boxShadow: _hovered ? [
            BoxShadow(
              color: const Color(0xFF00A86B).withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.body,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Real photos that show who TapVerify is for and what the flow looks like.
class _RealPeople extends StatelessWidget {
  const _RealPeople();

  static const _cards = [
    (
      imageUrl:
          'https://images.pexels.com/photos/33569521/pexels-photo-33569521.jpeg?auto=compress&cs=tinysrgb&w=900',
      title: 'Secretaries & treasurers',
      body: 'Stop chasing screenshots. Open one list and see the truth.',
      tag: 'The person collecting',
    ),
    (
      imageUrl:
          'https://images.pexels.com/photos/1368484/pexels-photo-1368484.jpeg?auto=compress&cs=tinysrgb&w=900',
      title: 'Members pay from any phone',
      body: 'One SMS, one link, one tap. No app, no account, no password.',
      tag: 'The people paying',
    ),
    (
      imageUrl:
          'https://images.pexels.com/photos/4226272/pexels-photo-4226272.jpeg?auto=compress&cs=tinysrgb&w=900',
      title: 'Payments mark themselves',
      body: 'Till and Paybill money appears as Paid automatically.',
      tag: 'The proof',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      background: kSurface,
      title: 'Built for real groups in Kenya',
      subtitle: 'Chamas, factory welfare groups, school contributions and '
          'anywhere money is collected from many people at once.',
      child: LayoutBuilder(
        builder: (context, c) {
          // Wrap with an explicit width, so one column really is one column
          // instead of three squeezed cards side by side.
          final cols = c.maxWidth > 860 ? 3 : (c.maxWidth > 560 ? 2 : 1);
          final width = cols == 1
              ? c.maxWidth
              : (c.maxWidth - (cols - 1) * 16) / cols;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (var i = 0; i < _cards.length; i++)
                SizedBox(
                  width: width,
                  child: FadeSlideIn(
                    delay: AppMotion.stagger(i, stepMs: 90, capMs: 270),
                    duration: AppMotion.slow,
                    offset: 26,
                    child: _PhotoCard(
                      imageUrl: _cards[i].imageUrl,
                      title: _cards[i].title,
                      body: _cards[i].body,
                      tag: _cards[i].tag,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PhotoCard extends StatefulWidget {
  const _PhotoCard({
    required this.imageUrl,
    required this.title,
    required this.body,
    required this.tag,
  });

  final String imageUrl;
  final String title;
  final String body;
  final String tag;

  @override
  State<_PhotoCard> createState() => _PhotoCardState();
}

class _PhotoCardState extends State<_PhotoCard> {
  bool _hovered = false;

  /// A branded placeholder beats one generic grey icon for every card.
  IconData _fallbackIcon(String tag) {
    final lower = tag.toLowerCase();
    if (lower.contains('paying')) return Icons.phone_iphone_rounded;
    if (lower.contains('proof')) return Icons.verified_rounded;
    return Icons.groups_2_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -6 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _hovered ? kPrimary : const Color(0xFFE5E7EB),
            width: _hovered ? 2 : 1,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: kPrimary.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Decode near the painted size. The old version pulled a
                  // 900px wide JPEG and decoded it at full resolution for a
                  // 190px tall box, which is heavy on a slow connection.
                  Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                    cacheWidth: (MediaQuery.devicePixelRatioOf(context) * 420).round(),
                    filterQuality: FilterQuality.medium,
                    semanticLabel: widget.title,
                    frameBuilder: (context, child, frame, wasSyncLoaded) {
                      if (wasSyncLoaded) return child;
                      return AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: AppMotion.slow,
                        curve: AppMotion.enter,
                        child: child,
                      );
                    },
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: kHairline,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: kPrimary,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stack) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kPrimary.withValues(alpha: 0.14),
                            kPrimaryDark.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(_fallbackIcon(widget.tag),
                          size: 44, color: kPrimary),
                    ),
                  ),
                  // Gradient so the tag stays readable
                  const DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x66000000)],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 12,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        widget.tag,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: kPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.body,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({super.key});

  static const _steps = [
    ('1', 'Create a collection', 'Title, amount per person, and paste the '
        'phone numbers of everyone who should pay.', Icons.add_circle_outline),
    ('2', 'We notify everyone by SMS', 'Each member gets a short SMS with the '
        'amount and a personal payment link.', Icons.sms_outlined),
    ('3', 'Members pay normally', 'Till, Paybill, or one tap on the link. '
        'No app, no account, no password.', Icons.payment_outlined),
    ('4', 'Watch the list update', 'Paid members turn green automatically. '
        'You only mark cash payments yourself.', Icons.check_circle_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      background: kSurface,
      title: 'How it works',
      subtitle: 'From "create" to a live list in under two minutes.',
      child: LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth > 860 ? 4 : (c.maxWidth > 560 ? 2 : 1);
          final width = (c.maxWidth - (cols - 1) * 12) / cols;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 0; i < _steps.length; i++)
                SizedBox(
                  width: width,
                  child: FadeSlideIn(
                    delay: AppMotion.stagger(i, stepMs: 90, capMs: 270),
                    duration: AppMotion.slow,
                    offset: 26,
                    child: _StepCard(step: _steps[i], index: i),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StepCard extends StatefulWidget {
  const _StepCard({required this.step, required this.index});
  final (String, String, String, IconData) step;
  final int index;

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final (n, title, body, icon) = widget.step;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _hovered ? const Color(0xFF00A86B) : const Color(0xFFE5E7EB), width: _hovered ? 2 : 1),
          boxShadow: _hovered ? [
            BoxShadow(
              color: const Color(0xFF00A86B).withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _hovered
                          ? [const Color(0xFF00A86B), const Color(0xFF007A4D)]
                          : [const Color(0xFF00A86B).withValues(alpha: 0.12), const Color(0xFF007A4D).withValues(alpha: 0.08)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _hovered ? [
                      BoxShadow(
                        color: const Color(0xFF00A86B).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: Icon(icon, color: _hovered ? Colors.white : const Color(0xFF00A86B), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$n. $title',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "See the live list in action": the five product screens riding a rotating
/// 3D turntable (splash, login, code, create account, home) inside a premium
/// natural scene: blurred green bokeh photo, soft light-green wash, subtle
/// vignette, and white fades top and bottom so the section blends into the
/// page around it.
class _LiveDemo extends StatefulWidget {
  const _LiveDemo();

  @override
  State<_LiveDemo> createState() => _LiveDemoState();
}

class _LiveDemoState extends State<_LiveDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _spinController;
  late final Animation<double> _lift;

  @override
  void initState() {
    super.initState();
    // The phone breathes up and down with settled easing, no bounce.
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    // The turntable: one full revolution every 10s, so each of the five
    // screens faces the viewer for about two seconds. Linear with whole
    // sine cycles, so the loop never jumps at the seam.
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    )..repeat();
    _lift = CurvedAnimation(parent: _floatController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Container(
      color: kPrimaryLight,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Stack(
            children: [
              // 1. The bokeh photo covers the entire section: stretch to fill,
              // no empty edges or solid gaps behind the phones.
              Positioned.fill(
                child: Image.asset(
                  'assets/images/Dreamy Sunlit Greenery Bokeh.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) =>
                      const ColoredBox(color: kPrimaryLight),
                ),
              ),
              // 2. Soft light green wash (#E6F7F0, 65%) so the dark screens
              // and white interfaces stay crisp against the texture.
              Positioned.fill(
                child: ColoredBox(
                  color: kPrimaryLight.withValues(alpha: 0.65),
                ),
              ),
              // 3. Vignette: subtly darker around the edges so the centre
              // reads like a spotlight and the middle phone pops.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.85,
                      stops: const [0.45, 1],
                      colors: [
                        Colors.transparent,
                        const Color(0xFF003322).withValues(alpha: 0.16),
                      ],
                    ),
                  ),
                ),
              ),
              // 4. White gradient fades top and bottom: no harsh line, the
              // section blends into the white page above and below it.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.97),
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.97),
                      ],
                      stops: const [0, 0.14, 0.86, 1],
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  const Text(
                    'See the live list in action',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: kBrandInk,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'From sign-in to the live list: every screen your group '
                    'runs on, in motion.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.grey[600],
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 44),
                  // Five product screens on a rotating 3D turntable.
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: SizedBox(
                        height: 540,
                        child: AnimatedBuilder(
                          animation: Listenable.merge(
                              [_spinController, _floatController]),
                          builder: (context, _) {
                            final lift = _lift.value;
                            final base =
                                _spinController.value * 2 * math.pi;
                            // Paint back-to-front so the front screen lands
                            // on top of its neighbours.
                            final order = List<int>.generate(
                                _demoScreens.length, (i) => i)
                              ..sort((a, b) => _cos(base, a)
                                  .compareTo(_cos(base, b)));
                            return Transform.translate(
                              offset: Offset(0, -12 * lift),
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  for (final i in order)
                                    _turntableItem(base, i, dpr),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The five phone mockups, in tour order around the turntable.
  static const _demoScreens = [
    ('assets/mobile screens/splash scree.jpeg', 'TapVerify splash screen'),
    ('assets/mobile screens/get started same login screen.jpeg', 'Login screen'),
    ('assets/mobile screens/code verify screen.jpeg', 'Code verification screen'),
    ('assets/mobile screens/create account.jpeg', 'Create account screen'),
    ('assets/mobile screens/home screen.jpeg', 'My Collections home screen'),
  ];

  /// Where screen [i] sits on the circle right now, wrapped to (-pi, pi] so
  /// the front of the turntable is always at angle 0.
  double _angle(double base, int i) {
    var a = base + i * 2 * math.pi / _demoScreens.length;
    while (a > math.pi) {
      a -= 2 * math.pi;
    }
    while (a <= -math.pi) {
      a += 2 * math.pi;
    }
    return a;
  }

  double _cos(double base, int i) => math.cos(_angle(base, i));

  /// One screen: swung around the vertical axis by its angle, pushed out on
  /// x, shrunk and faded as it travels to the back of the turntable.
  Widget _turntableItem(double base, int i, double dpr) {
    final a = _angle(base, i);
    final depth = (math.cos(a) + 1) / 2; // 1 at the front, 0 at the back
    final (asset, label) = _demoScreens[i];
    return Opacity(
      opacity: 0.2 + 0.8 * depth,
      child: Transform.translate(
        offset: Offset(math.sin(a) * 250, 0),
        child: Transform.scale(
          scale: 0.62 + 0.38 * depth,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0016)
              ..rotateY(a),
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color:
                        kDarkGreen.withValues(alpha: 0.16 + 0.10 * depth),
                    blurRadius: 34,
                    offset: Offset(0, 14 + 8 * depth),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Image.asset(
                  asset,
                  width: 240,
                  height: 480,
                  fit: BoxFit.cover,
                  cacheWidth: (240 * dpr * 2).round(),
                  semanticLabel: label,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetectionTable extends StatefulWidget {
  const _DetectionTable();

  @override
  State<_DetectionTable> createState() => _DetectionTableState();
}

class _DetectionTableState extends State<_DetectionTable> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _rows = [
    ('Till Number', 'Auto-detected via SasaPay webhook', true, Icons.account_balance_wallet_outlined),
    ('Paybill', 'Auto-detected via SasaPay webhook', true, Icons.receipt_long_outlined),
    ('Personal M-Pesa / Airtel', 'You mark it, one tap', false, Icons.person_outline),
    ('Bank Account', 'You mark it, one tap', false, Icons.account_balance_outlined),
    ('Cash', 'You mark it, one tap', false, Icons.money_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Payments detected for you',
      subtitle: 'Choose Till or Paybill when creating a collection and payments '
          'mark themselves. That is why we recommend them.',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              for (var i = 0; i < _rows.length; i++)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + i * 100),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(opacity: value, child: child),
                  ),
                  child: _DetectionRow(
                    method: _rows[i].$1,
                    detection: _rows[i].$2,
                    recommended: _rows[i].$3,
                    icon: _rows[i].$4,
                    isFirst: i == 0,
                    isLast: i == _rows.length - 1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetectionRow extends StatelessWidget {
  const _DetectionRow({
    required this.method,
    required this.detection,
    required this.recommended,
    required this.icon,
    required this.isFirst,
    required this.isLast,
  });

  final String method;
  final String detection;
  final bool recommended;
  final IconData icon;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: recommended ? const Color(0xFF00A86B).withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isFirst ? 20 : 0),
          topRight: Radius.circular(isFirst ? 20 : 0),
          bottomLeft: Radius.circular(isLast ? 20 : 0),
          bottomRight: Radius.circular(isLast ? 20 : 0),
        ),
        border: Border.all(
          color: recommended ? const Color(0xFFA7F3D0) : const Color(0xFFE5E7EB),
          width: recommended ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: recommended
                  ? const Color(0xFF00A86B).withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: recommended ? const Color(0xFF00A86B) : Colors.grey[500],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wrap so "Personal M-Pesa / Airtel" and the Recommended pill
                // stack instead of overflowing a narrow phone.
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      method,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    if (recommended)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [kPrimary, kPrimaryDark],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Recommended',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  detection,
                  style: TextStyle(
                    fontSize: 13,
                    color: recommended ? const Color(0xFF007A4D) : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: recommended
                  ? const Color(0xFF00A86B).withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  recommended ? Icons.check_circle : Icons.edit_outlined,
                  color: recommended ? const Color(0xFF00A86B) : Colors.grey[500],
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  recommended ? 'Automatic' : 'Manual',
                  style: TextStyle(
                    color: recommended ? const Color(0xFF00A86B) : Colors.grey[600],
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberExperience extends StatefulWidget {
  const _MemberExperience();

  @override
  State<_MemberExperience> createState() => _MemberExperienceState();
}

class _MemberExperienceState extends State<_MemberExperience> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      background: const Color(0xFFE6F7F0),
      title: 'Members do nothing new',
      subtitle: 'No app to download. No account to create. They receive one '
          'SMS, pay the way they already know, and get a confirmation.',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00A86B).withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A86B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.sms_outlined, color: Color(0xFF00A86B), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Example SMS Member Receives',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1A1A1A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Text(
                      'TapVerify\n'
                      'September Welfare, KES 500\n\n'
                      'Pay to Till: 567890\n'
                      '(Use your full name as reference)\n\n'
                      'Or pay here: https://tapverify.vercel.app/#/pay/1/5000',
                      style: TextStyle(
                          fontFamily: 'monospace', fontSize: 13, height: 1.6, color: Color(0xFF333333)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _MemberStep(icon: '1', text: 'Gets SMS with link')),
                      Expanded(child: _MemberStep(icon: '2', text: 'Opens link in browser')),
                      Expanded(child: _MemberStep(icon: '3', text: 'Taps "Pay with M-Pesa"')),
                      Expanded(child: _MemberStep(icon: '4', text: 'Done, you see green')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberStep extends StatelessWidget {
  const _MemberStep({required this.icon, required this.text});
  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00A86B), Color(0xFF007A4D)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              icon,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

/// Footer: a soft green wave flowing out of the light section above, into a
/// deep green body with the tagline and contact details centred.
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 760;
    return Column(
      children: [
        // Wave transition. Its background continues the light green section
        // above, so the curve reads as the page flowing into the footer.
        Container(
          color: kPrimaryLight,
          height: 130,
          child: const CustomPaint(
            size: Size(double.infinity, 130),
            painter: _FooterWavePainter(),
          ),
        ),
        // Solid deep green body with faint leaf silhouettes for depth.
        Container(
          width: double.infinity,
          color: kPrimaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
          child: Stack(
            children: [
              const Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(painter: _LeafSilhouettesPainter()),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    children: [
                      // The mark, rendered directly: the old white chip put
                      // a white logo on a white box, so nothing showed.
                      const AppLogo(height: 40, onDark: true),
                      const SizedBox(height: 18),
                      const Text(
                        'Stop asking people if they have paid. Open this and see.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Contact: green icon boxes with labels, one row on
                      // wide screens with thin dividers, wrapping on phones.
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: wide
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _ContactItem(
                                    icon: Icons.chat_bubble_outline,
                                    text: '+254 715 641 339',
                                    url: 'https://wa.me/254715641339',
                                  ),
                                  _ContactDivider(),
                                  _ContactItem(
                                    icon: Icons.mail_outline,
                                    text: 'hello@tapverify.co',
                                    url: 'mailto:hello@tapverify.co',
                                  ),
                                  _ContactDivider(),
                                  _ContactItem(
                                    icon: Icons.public,
                                    text: 'tapverify.vercel.app',
                                    url: 'https://tapverify.vercel.app',
                                  ),
                                ],
                              )
                            : const Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 24,
                                runSpacing: 16,
                                children: [
                                  _ContactItem(
                                    icon: Icons.chat_bubble_outline,
                                    text: '+254 715 641 339',
                                    url: 'https://wa.me/254715641339',
                                  ),
                                  _ContactItem(
                                    icon: Icons.mail_outline,
                                    text: 'hello@tapverify.co',
                                    url: 'mailto:hello@tapverify.co',
                                  ),
                                  _ContactItem(
                                    icon: Icons.public,
                                    text: 'tapverify.vercel.app',
                                    url: 'https://tapverify.vercel.app',
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 36),
                      Container(height: 1, color: Colors.white24),
                      const SizedBox(height: 18),
                      Text(
                        '© ${DateTime.now().year} TapVerify. Built for Kenya.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 18,
                        runSpacing: 6,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const LegalScreen(
                                    doc: LegalDoc.terms),
                              ),
                            ),
                            child: const Text(
                              'Terms of Service',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white38,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const LegalScreen(
                                    doc: LegalDoc.privacy),
                              ),
                            ),
                            child: const Text(
                              'Privacy Policy',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white38,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      // Trust strip: icon, bold title, short subtitle.
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: wide
                            ? const Row(
                                children: [
                                  Expanded(
                                    child: _TrustBadge(
                                      icon: Icons.shield_outlined,
                                      title: 'Secure & Encrypted',
                                      subtitle: 'Your data stays safe',
                                    ),
                                  ),
                                  _ContactDivider(),
                                  Expanded(
                                    child: _TrustBadge(
                                      icon: Icons.bolt_outlined,
                                      title: 'Fast & Easy',
                                      subtitle: 'Get started in minutes',
                                    ),
                                  ),
                                  _ContactDivider(),
                                  Expanded(
                                    child: _TrustBadge(
                                      icon: Icons.favorite_outline,
                                      title: 'Built for Kenya',
                                      subtitle: 'Local needs, real impact',
                                    ),
                                  ),
                                ],
                              )
                            : const Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 28,
                                runSpacing: 20,
                                children: [
                                  _TrustBadge(
                                    icon: Icons.shield_outlined,
                                    title: 'Secure & Encrypted',
                                    subtitle: 'Your data stays safe',
                                  ),
                                  _TrustBadge(
                                    icon: Icons.bolt_outlined,
                                    title: 'Fast & Easy',
                                    subtitle: 'Get started in minutes',
                                  ),
                                  _TrustBadge(
                                    icon: Icons.favorite_outline,
                                    title: 'Built for Kenya',
                                    subtitle: 'Local needs, real impact',
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One wide, gentle sweep across the full width. The fill runs light green at
/// the crest into the deep green of the body, so the two read as one surface.
class _FooterWavePainter extends CustomPainter {
  const _FooterWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.62)
      ..cubicTo(w * 0.25, h * 0.18, w * 0.62, h * 0.14, w, h * 0.5)
      ..lineTo(w, h)
      ..close();
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [kPrimaryLight, kPrimary, kPrimaryDark],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FooterWavePainter oldDelegate) => false;
}

/// Faint leaf silhouettes anchored in the bottom corners of the footer, so
/// the dark green reads as depth rather than a flat block.
class _LeafSilhouettesPainter extends CustomPainter {
  const _LeafSilhouettesPainter();

  static Path _leaf(Offset base, double length, double angle, double width) {
    final tip = base +
        Offset(math.cos(angle) * length, math.sin(angle) * length);
    final mid = Offset((base.dx + tip.dx) / 2, (base.dy + tip.dy) / 2);
    final nx = -math.sin(angle) * width;
    final ny = math.cos(angle) * width;
    return Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(mid.dx + nx, mid.dy + ny, tip.dx, tip.dy)
      ..quadraticBezierTo(mid.dx - nx, mid.dy - ny, base.dx, base.dy)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 2) return;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.05);
    // Bottom left, leaves reaching up and to the right.
    canvas.drawPath(
        _leaf(Offset(0, size.height), 170, -math.pi * 0.24, 40), paint);
    canvas.drawPath(
        _leaf(Offset(0, size.height), 130, -math.pi * 0.42, 32), paint);
    canvas.drawPath(
        _leaf(Offset(20, size.height), 95, -math.pi * 0.6, 26), paint);
    // Bottom right, mirrored.
    canvas.drawPath(
        _leaf(Offset(size.width, size.height), 170, math.pi + math.pi * 0.24, 40),
        paint);
    canvas.drawPath(
        _leaf(Offset(size.width, size.height), 130, math.pi + math.pi * 0.42, 32),
        paint);
    canvas.drawPath(
        _leaf(Offset(size.width - 20, size.height), 95, math.pi + math.pi * 0.6, 26),
        paint);
  }

  @override
  bool shouldRepaint(covariant _LeafSilhouettesPainter oldDelegate) => false;
}

/// A tappable contact item: bright green rounded icon square plus its label.
class _ContactItem extends StatelessWidget {
  const _ContactItem({required this.icon, required this.text, required this.url});
  final IconData icon;
  final String text;
  final String url;

  Future<void> _open() async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Clipboard is the reliable fallback when no browser or handler exists.
      await Clipboard.setData(ClipboardData(text: url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _open,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(text,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

/// Thin vertical rule between contact items or trust badges.
class _ContactDivider extends StatelessWidget {
  const _ContactDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: 1,
        height: 44,
        color: Colors.white24,
      ),
    );
  }
}

/// Icon, bold title, short subtitle in one vertically centred row.
class _TrustBadge extends StatelessWidget {
  const _TrustBadge(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: kSoftGreen),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12.5)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
    this.background = Colors.white,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A), height: 1.2)),
              const SizedBox(height: 16),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 17, color: Colors.grey[600], height: 1.6, fontWeight: FontWeight.w400)),
              const SizedBox(height: 40),
              child,
            ],
          ),
        ),
      ),
    );
  }
}