import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'web_login.dart';

class WebContactPage extends StatefulWidget {
  const WebContactPage({super.key});
  @override
  State<WebContactPage> createState() => _WebContactPageState();
}

class _WebContactPageState extends State<WebContactPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _sent = false;

  void _sendEmail() {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _messageCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill in all required fields', style: GoogleFonts.inter()),
        backgroundColor: AppColors.danger,
      ));
      return;
    }
    setState(() => _sent = true);
  }

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
            _contactGrid(narrow, pad),
            _contactForm(narrow, pad),
            _map(narrow, pad),
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
            _navLink('About', () => Navigator.pushReplacementNamed(context, '/about')),
            _navLink('Contact', () {}),
            const SizedBox(width: 16),
          ],
          ElevatedButton(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const WebLoginPage())),
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
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: narrow ? 50 : 80),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0FDFA), Colors.white, Color(0xFFF0FDFA)],
        ),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.deep]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('Get In Touch',
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
        const SizedBox(height: 24),
        Text("Let's Build Together",
            style: GoogleFonts.inter(
                fontSize: narrow ? 32 : 44,
                fontWeight: FontWeight.w900,
                color: AppColors.text)),
        const SizedBox(height: 12),
        Text(
          'Have a question? Want to partner? Need support?\nWe\'d love to hear from you.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 16, color: AppColors.muted, height: 1.6),
        ),
      ]),
    );
  }

  Widget _contactGrid(bool narrow, double pad) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 40),
      child: narrow
          ? Column(children: _contactCards().map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _contactCard(c),
            )).toList())
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _contactCards().map((c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _contactCard(c),
                ),
              )).toList(),
            ),
    );
  }

  List<_ContactInfo> _contactCards() => [
    _ContactInfo(
      Icons.chat_rounded,
      'WhatsApp',
      'Chat with us directly',
      '0715 641 339',
      AppColors.success,
      () {
        final url = Uri.parse('https://wa.me/254715641339?text=Hello TapVerify! I have a question.');
        _launchUrl(url);
      },
    ),
    _ContactInfo(
      Icons.email_rounded,
      'Email',
      'We reply within 24 hours',
      'info@tapverify.co.ke',
      AppColors.primary,
      () {
        final url = Uri.parse('mailto:info@tapverify.co.ke?subject=TapVerify Inquiry&body=Hello TapVerify team,');
        _launchUrl(url);
      },
    ),
    _ContactInfo(
      Icons.location_on_rounded,
      'Location',
      'Nairobi, Kenya',
      'Westlands, Nairobi',
      AppColors.deep,
      () {},
    ),
    _ContactInfo(
      Icons.phone_rounded,
      'Phone',
      'Mon-Fri 8am-6pm',
      '+254 715 641 339',
      AppColors.gold,
      () {
        final url = Uri.parse('tel:+254715641339');
        _launchUrl(url);
      },
    ),
  ];

  Future<void> _launchUrl(Uri url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url.toString()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Link copied! Paste in your browser to open.',
              style: GoogleFonts.inter()),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {}
  }

  Widget _contactCard(_ContactInfo info) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: info.color.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [info.color, info.color.withValues(alpha: 0.7)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(info.icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 16),
        Text(info.title,
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 4),
        Text(info.subtitle,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 8),
        Text(info.value,
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w700, color: info.color)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: info.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: info.color.withValues(alpha: 0.15)),
            ),
            child: Text('Get in Touch →',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: info.color)),
          ),
        ),
      ]),
    );
  }

  Widget _contactForm(bool narrow, double pad) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 60),
      color: const Color(0xFFF8FAFC),
      child: _sent ? _thankYou() : _form(narrow),
    );
  }

  Widget _form(bool narrow) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 700),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 30,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.mail_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Text('Send Us a Message',
              style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
        ]),
        const SizedBox(height: 6),
        Text("We'll get back to you within 24 hours",
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: _field('Your Name *', Icons.person_rounded, _nameCtrl)),
          const SizedBox(width: 16),
          Expanded(child: _field('Email Address *', Icons.email_rounded, _emailCtrl, keyboard: TextInputType.emailAddress)),
        ]),
        const SizedBox(height: 16),
        _field('Subject', Icons.subject_rounded, _subjectCtrl),
        const SizedBox(height: 16),
        TextField(
          controller: _messageCtrl,
          maxLines: 5,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Your message...',
            hintStyle: GoogleFonts.inter(color: AppColors.muted.withValues(alpha: 0.5), fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, top: 16),
              child: Icon(Icons.message_rounded, color: AppColors.muted, size: 20),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _sendEmail,
            icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            label: Text('Send Message',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ]),
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
        hintStyle: GoogleFonts.inter(
            color: AppColors.muted.withValues(alpha: 0.5), fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }

  Widget _thankYou() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: AppColors.success.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(children: [
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 36, color: AppColors.success),
        ),
        const SizedBox(height: 20),
        Text('Message Sent!',
            style: GoogleFonts.inter(
                fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 8),
        Text(
          'Thank you for reaching out. We\'ll get back to you within 24 hours.\n\n'
          'For urgent inquiries, message us on WhatsApp at 0715 641 339.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 14, color: AppColors.muted, height: 1.6),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => setState(() => _sent = false),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text('Send Another',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ]),
    );
  }

  Widget _map(bool narrow, double pad) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 40),
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_rounded,
                  size: 48, color: AppColors.primary.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text('Nairobi, Kenya',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text)),
              Text('Westlands, Nairobi',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.muted)),
            ],
          ),
        ),
      ),
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
        ('About', () => Navigator.pushReplacementNamed(context, '/about')),
        ('Contact', () {}),
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

class _ContactInfo {
  final IconData icon;
  final String title, subtitle, value;
  final Color color;
  final VoidCallback onTap;
  _ContactInfo(this.icon, this.title, this.subtitle, this.value, this.color, this.onTap);
}
