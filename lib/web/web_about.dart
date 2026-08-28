import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'web_login.dart';

class WebAboutPage extends StatelessWidget {
  const WebAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final narrow = w < 800;
    final pad = narrow ? 20.0 : 60.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _navBar(context, narrow, pad),
            _hero(narrow, pad),
            _story(narrow, pad),
            _mission(narrow, pad),
            _team(narrow, pad),
            _stats(narrow, pad),
            _cta(context, narrow, pad),
            _footer(context, narrow, pad),
          ],
        ),
      ),
    );
  }

  Widget _navBar(BuildContext context, bool narrow, double pad) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          Image.asset(AppAssets.logoFull, height: 40),
          const Spacer(),
          if (!narrow) ...[
            _navLink('Home', () => Navigator.pop(context)),
            _navLink('Features', () => Navigator.pop(context)),
            _navLink('About', () {}),
            _navLink('Contact', () => Navigator.pushReplacementNamed(context, '/contact')),
            const SizedBox(width: 16),
          ],
          ElevatedButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WebLoginPage())),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Get Started',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _navLink(String text, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: TextButton(
      onPressed: onTap,
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
    ),
  );

  Widget _hero(bool narrow, double pad) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: narrow ? 60 : 100),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0FDFA), Colors.white],
        ),
      ),
      child: narrow
          ? Column(children: [_heroText(narrow), const SizedBox(height: 40), _heroImage()])
          : Row(children: [
              Expanded(child: _heroText(narrow)),
              const SizedBox(width: 60),
              Expanded(child: _heroImage()),
            ]),
    );
  }

  Widget _heroText(bool narrow) {
    return Column(
      crossAxisAlignment: narrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.deep]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('Our Story',
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
        const SizedBox(height: 24),
        Text('We Believe Every\nBusiness Deserves\nRevenue Proof',
            textAlign: narrow ? TextAlign.center : TextAlign.left,
            style: GoogleFonts.inter(
                fontSize: narrow ? 32 : 44,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
                height: 1.1)),
        const SizedBox(height: 16),
        Text(
          'Born in Westlands, Nairobi. Built for every jua kali welder, '
          'every mama mboga, every SACCO that deserves to be seen by lenders.',
          textAlign: narrow ? TextAlign.center : TextAlign.left,
          style: GoogleFonts.inter(
              fontSize: 16, color: AppColors.muted, height: 1.6),
        ),
      ],
    );
  }

  Widget _heroImage() {
    return Container(
      height: 350,
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
              'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800&h=600&fit=crop',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(Icons.groups_rounded, size: 100,
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.deep.withValues(alpha: 0.7)],
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 24,
              child:               Text('Westlands, Nairobi — 2024',
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

  Widget _story(bool narrow, double pad) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 80),
      child: Column(children: [
        Text('How It Started',
            style: GoogleFonts.inter(
                fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 30),
        narrow
            ? Column(children: _storyItems().map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: _storyCard(s),
              )).toList())
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _storyItems().map((s) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _storyCard(s),
                  ),
                )).toList(),
              ),
      ]),
    );
  }

  List<_StoryItem> _storyItems() => [
    _StoryItem(
      Icons.lightbulb_rounded,
      'The Problem',
      'Peter Kaunda had Ksh 2.4 million in revenue but no proof. '
          'Banks saw a notebook. They saw risk. His loan was denied.',
      AppColors.accent,
    ),
    _StoryItem(
      Icons.build_rounded,
      'The Build',
      'We built TapVerify to capture every payment with cryptographic proof. '
          'SasaPay webhooks. Africa\'s Talking SMS. Avalanche badges.',
      AppColors.primary,
    ),
    _StoryItem(
      Icons.emoji_events_rounded,
      'The Result',
      'Peter walked into Equity Bank with a dashboard. Ksh 2.4M verified '
          'across 48 transactions. Loan approved in 3 days.',
      AppColors.gold,
    ),
  ];

  Widget _storyCard(_StoryItem item) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: item.color.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [item.color, item.color.withValues(alpha: 0.7)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 16),
        Text(item.title,
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 8),
        Text(item.desc,
            style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.muted, height: 1.6)),
      ]),
    );
  }

  Widget _mission(bool narrow, double pad) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 80),
      color: AppColors.deep,
      child: Column(children: [
        Text('Our Mission',
            style: GoogleFonts.inter(
                fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 16),
        Text(
          'Turn informal payment chaos into lender-ready revenue proof.\n'
          'Every jua kali business deserves access to credit.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 18, color: Colors.white70, height: 1.6),
        ),
        const SizedBox(height: 40),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: [
            _missionBadge('KES 480M+ Verified', Icons.account_balance_rounded),
            _missionBadge('200+ Businesses', Icons.business_rounded),
            _missionBadge('12,000+ Payments', Icons.payments_rounded),
            _missionBadge('99.9% Uptime', Icons.wifi_rounded),
          ],
        ),
      ]),
    );
  }

  Widget _missionBadge(String text, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 18, color: Colors.white),
      const SizedBox(width: 8),
      Text(text,
          style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
    ]),
  );

  Widget _team(bool narrow, double pad) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 80),
      child: Column(children: [
        Text('The Team',
            style: GoogleFonts.inter(
                fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 8),
        Text('Built by builders who understand the problem',
            style: GoogleFonts.inter(fontSize: 16, color: AppColors.muted)),
        const SizedBox(height: 50),
        Wrap(
          spacing: 30,
          runSpacing: 30,
          alignment: WrapAlignment.center,
          children: [
            _teamMember('Peter Kaunda', 'Founder & CEO', 'PK', AppColors.primary),
            _teamMember('Joel Kaunda', 'Lead Developer', 'JK', AppColors.deep),
            _teamMember('Wanjiru Wambui', 'Product Lead', 'WW', AppColors.gold),
          ],
        ),
      ]),
    );
  }

  Widget _teamMember(String name, String role, String initials, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(initials,
              style: GoogleFonts.inter(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        ),
        const SizedBox(height: 14),
        Text(name,
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 4),
        Text(role,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
      ]),
    );
  }

  Widget _stats(bool narrow, double pad) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 60),
      color: const Color(0xFFF8FAFC),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _aboutStat('2024', 'Founded', narrow: narrow),
          SizedBox(width: narrow ? 20 : 60),
          _aboutStat('15', 'Team Members', narrow: narrow),
          SizedBox(width: narrow ? 20 : 60),
          _aboutStat('Nairobi', 'Based In', narrow: narrow),
        ],
      ),
    );
  }

  Widget _aboutStat(String value, String label, {bool narrow = false}) => Column(
    children: [
      Text(value,
          style: GoogleFonts.inter(
              fontSize: narrow ? 24 : 32,
              fontWeight: FontWeight.w900,
              color: AppColors.primary)),
      const SizedBox(height: 4),
      Text(label,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
    ],
  );

  Widget _cta(BuildContext context, bool narrow, double pad) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 80),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [AppColors.deep, AppColors.primary, Color(0xFF16A34A)]),
      ),
      child: Column(children: [
        Text('Join the Revenue Revolution',
            style: GoogleFonts.inter(
                fontSize: narrow ? 24 : 36,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 12),
        Text('Start free. Upgrade when you grow.',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.white70)),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const WebLoginPage())),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
          ),
          child: Text('Get Started Free',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deep)),
        ),
      ]),
    );
  }

  Widget _footer(BuildContext context, bool narrow, double pad) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 40),
      color: const Color(0xFF0F172A),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(AppAssets.logoFull, height: 36),
                const SizedBox(height: 20),
                _footerLinks(context),
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
                Expanded(child: _footerLinks(context)),
                Text('© 2026 TapVerify. All rights reserved.',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
              ],
            ),
    );
  }

  Widget _footerLinks(BuildContext context) => Wrap(
    spacing: 30,
    runSpacing: 12,
    children: [
      _footerCol(context, 'Product', [
        ('Features', () => Navigator.pop(context)),
        ('Pricing', () => Navigator.pop(context)),
        ('Dashboard', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WebLoginPage()))),
      ]),
      _footerCol(context, 'Company', [
        ('About', () {}),
        ('Contact', () => Navigator.pushReplacementNamed(context, '/contact')),
        ('Careers', () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('We\'re hiring! Check our website for open positions.', style: GoogleFonts.inter()),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }),
      ]),
      _footerCol(context, 'Legal', [
        ('Privacy', () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Privacy policy coming soon.', style: GoogleFonts.inter()),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }),
        ('Terms', () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Terms of service coming soon.', style: GoogleFonts.inter()),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }),
        ('Security', () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Security information coming soon.', style: GoogleFonts.inter()),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }),
      ]),
    ],
  );

  Widget _footerCol(BuildContext context, String title, List<(String, VoidCallback)> links) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title,
          style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 12),
      for (final l in links)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: l.$2,
            child: Text(l.$1,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
          ),
        ),
    ],
  );
}

class _StoryItem {
  final IconData icon;
  final String title, desc;
  final Color color;
  _StoryItem(this.icon, this.title, this.desc, this.color);
}
