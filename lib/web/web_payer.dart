import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'landing_page.dart';
import 'web_about.dart';
import 'web_contact.dart';

class WebPayerPage extends StatelessWidget {
  const WebPayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final narrow = w < 800;
    final pad = narrow ? 20.0 : 60.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _navBar(context, narrow, pad),
            _payerIdentityHeader(narrow, pad),
            _scoreCard(narrow, pad),
            _streakCard(narrow, pad),
            _avalancheBadges(narrow, pad),
            _activePerks(narrow, pad),
            _shareProofButton(narrow, pad),
            _footer(narrow, pad),
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
          Image.asset(AppAssets.logoFull, height: 36),
          const Spacer(),
          if (!narrow) ...[
            GestureDetector(
              onTap: () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const WebLandingPage())),
              child: Text('Home',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
            ),
            const SizedBox(width: 30),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WebAboutPage())),
              child: Text('About',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
            ),
            const SizedBox(width: 30),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WebContactPage())),
              child: Text('Contact',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
            ),
            const SizedBox(width: 30),
          ],
          ElevatedButton(
            onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const WebLandingPage())),
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

  Widget _payerIdentityHeader(bool narrow, double pad) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: narrow ? 30 : 50),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.deep, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _payerIdentityContent(true),
              ],
            )
          : Row(
              children: [
                Expanded(child: _payerIdentityContent(false)),
              ],
            ),
    );
  }

  Widget _payerIdentityContent(bool narrow) {
    return Column(
      crossAxisAlignment: narrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: narrow ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text('JK',
                  style: GoogleFonts.inter(
                      fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Joel Kaunda',
                    style: GoogleFonts.inter(
                        fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('⭐ Silver Payer II · 847/1000',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _scoreCard(bool narrow, double pad) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.deep, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('🏅 TOP 15% IN KENYA',
                  style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('847',
                    style: GoogleFonts.inter(
                        fontSize: 56, fontWeight: FontWeight.w900, color: Colors.white)),
                Text(' / 1000 points',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 4),
            Text('53 to Gold',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gold)),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: 0.847,
                minHeight: 12,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Text('84.7% complete',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _streakCard(bool narrow, double pad) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pad),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('7-Month Streak with Peter\'s Metal Works',
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text)),
                  const SizedBox(height: 4),
                  Text('Pay Sept welfare by Sep 2 to keep it alive!',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('ACTIVE',
                  style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avalancheBadges(bool narrow, double pad) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AVALANCHE BADGES',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                  letterSpacing: 0.6)),
          const SizedBox(height: 12),
          narrow
              ? Column(
                  children: [
                    _badgeTile(
                        emoji: '🥉',
                        name: 'Bronze',
                        period: '3 Months',
                        tx: '0x3f2a...b91c',
                        status: 'MINTED',
                        statusColor: AppColors.success),
                    const SizedBox(height: 10),
                    _badgeTile(
                        emoji: '🥈',
                        name: 'Silver',
                        period: '6 Months',
                        tx: '0x7e8b...c4d2',
                        status: 'MINTING',
                        statusColor: AppColors.gold),
                    const SizedBox(height: 10),
                    _badgeTile(
                        emoji: '🥇',
                        name: 'Gold',
                        period: '12 Months',
                        tx: '6mo to go',
                        status: 'LOCKED',
                        statusColor: AppColors.muted),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                        child: _badgeTile(
                            emoji: '🥉',
                            name: 'Bronze',
                            period: '3 Months',
                            tx: '0x3f2a...b91c',
                            status: 'MINTED',
                            statusColor: AppColors.success)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _badgeTile(
                            emoji: '🥈',
                            name: 'Silver',
                            period: '6 Months',
                            tx: '0x7e8b...c4d2',
                            status: 'MINTING',
                            statusColor: AppColors.gold)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _badgeTile(
                            emoji: '🥇',
                            name: 'Gold',
                            period: '12 Months',
                            tx: '6mo to go',
                            status: 'LOCKED',
                            statusColor: AppColors.muted)),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _badgeTile({
    required String emoji,
    required String name,
    required String period,
    required String tx,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text)),
                    Text(period,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(status,
                    style: GoogleFonts.inter(
                        fontSize: 9, fontWeight: FontWeight.w800, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.link_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(tx,
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activePerks(bool narrow, double pad) {
    final perks = [
      ('✅', '3% discount at ALL merchants', true),
      ('✅', 'Priority SACCO pre-approval', true),
      ('✅', 'Faster dispute resolution', true),
      ('⬜', '5% discount at Gold tier', false),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🎁', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text('Active Perks',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
              ],
            ),
            const SizedBox(height: 16),
            for (final p in perks) ...[
              Row(
                children: [
                  Text(p.$1, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(p.$2,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: p.$3 ? AppColors.text : AppColors.muted)),
                  ),
                ],
              ),
              if (p != perks.last) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _shareProofButton(bool narrow, double pad) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          icon: const Icon(Icons.share_rounded, color: Colors.white, size: 22),
          label: Text('Share My Proof to WhatsApp',
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _footer(bool narrow, double pad) {
    return Container(
      padding: EdgeInsets.fromLTRB(pad, 30, pad, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 18, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Lenders verify instantly at tapverify.co.ke/verify/joel-k',
                            style: GoogleFonts.inter(
                                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Image.asset(AppAssets.logoFull, height: 32),
                const SizedBox(height: 12),
                Text("Replaced the treasurer's notebook with 5 screens.",
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white54, height: 1.5)),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFF1E293B)),
                const SizedBox(height: 16),
                Text('© 2026 TapVerify. All rights reserved.',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
              ],
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 18, color: AppColors.success),
                      const SizedBox(width: 10),
                      Text('Lenders verify instantly at tapverify.co.ke/verify/joel-k',
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(AppAssets.logoFull, height: 32),
                          const SizedBox(height: 12),
                          Text("Replaced the treasurer's notebook with 5 screens.",
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: Colors.white54, height: 1.5)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Product',
                              style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(height: 14),
                          Text('Features',
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
                          const SizedBox(height: 10),
                          Text('Pricing',
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
                          const SizedBox(height: 10),
                          Text('Dashboard',
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Company',
                              style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(height: 14),
                          Text('About',
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
                          const SizedBox(height: 10),
                          Text('Contact',
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
                          const SizedBox(height: 10),
                          Text('Blog',
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Get in Touch',
                              style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(height: 14),
                          Row(children: [
                            const Icon(Icons.chat_rounded, size: 14, color: AppColors.success),
                            const SizedBox(width: 8),
                            Text('WhatsApp: 0715 641 339',
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.email_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text('info@tapverify.co.ke',
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.phone_rounded, size: 14, color: AppColors.gold),
                            const SizedBox(width: 8),
                            Text('+254 715 641 339',
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Divider(color: Color(0xFF1E293B)),
                const SizedBox(height: 16),
                Row(children: [
                  Text('© 2026 TapVerify. All rights reserved.',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
                  const Spacer(),
                  Text('Built in Nairobi, Kenya 🇰🇪',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
                ]),
              ],
            ),
    );
  }
}
