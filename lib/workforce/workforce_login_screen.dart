import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'treasurer_home_shell.dart';
import 'workforce_register_screen.dart';
import '../workforce/workforce_service.dart';
import 'app_background.dart';
import 'notification_center.dart';
import '../pay/payment_links_screen.dart';

/// Universal login. One form for everyone — a SACCO treasurer, a church
/// secretary, a school bursar, or an individual collecting for one appeal.
/// The app reads the phone + PIN, resolves the person, then greets them by
/// name and position.
class WorkforceLoginScreen extends StatefulWidget {
  const WorkforceLoginScreen({super.key});

  @override
  State<WorkforceLoginScreen> createState() => _WorkforceLoginScreenState();
}

class _WorkforceLoginScreenState extends State<WorkforceLoginScreen> {
  final _phone = TextEditingController(text: '254701234567');
  final _pin = TextEditingController();
  bool _obscure = true;

  static const _samples = [
    ('SACCO Treasurer', 'u-treasurer', Icons.account_balance_rounded,
        AppColors.sasapay),
    ('Church Treasurer', 'u-church', Icons.church_rounded, AppColors.accent),
    ('School Bursar', 'u-school', Icons.school_rounded, AppColors.sky),
    ('Individual Collector', 'u-individual', Icons.person_rounded, AppColors.gold),
  ];

  @override
  void dispose() {
    _phone.dispose();
    _pin.dispose();
    super.dispose();
  }

  void _fillSample(String id) {
    for (final u in WorkforceService.users) {
      if (u.id == id) {
        setState(() => _phone.text = u.phone);
        return;
      }
    }
  }

  void _login() {
    final user = WorkforceService.login(_phone.text, _pin.text);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No account for this phone. Use PIN 1234 or pick a sample below.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    NotificationCenter.instance.notify(
      title: 'Welcome back, ${user.name.split(' ').first}',
      body: 'Signed in as ${user.position} · ${user.orgName}',
      icon: Icons.verified_user_rounded,
      color: AppColors.primary,
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => TreasurerHomeShell(user: user),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        image: AppImages.chamaWomen,
        child: SafeArea(
          child: AuthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Image.asset(AppAssets.logoFull,
                          fit: BoxFit.contain),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'TapVerify',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'One login for everyone who collects — SACCOs, churches, schools and individuals.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.primary, height: 1.5),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Phone (254...)',
                    prefixIcon: Icon(Icons.phone_iphone_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _pin,
                  obscureText: _obscure,
                  keyboardType: TextInputType.number,
                  inputFormatters: [LengthLimitingTextInputFormatter(4)],
                  decoration: InputDecoration(
                    labelText: 'PIN',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                BrightButton(
                  label: 'Sign in',
                  icon: Icons.login_rounded,
                  onPressed: _login,
                ),
                const SizedBox(height: 14),
                Text(
                  'Sample accounts · PIN 1234',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.muted,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _samples)
                      ActionChip(
                        avatar: Icon(s.$3, size: 16, color: s.$4),
                        label: Text(s.$1),
                        onPressed: () => _fillSample(s.$2),
                        labelStyle: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: s.$4.withOpacity(0.4)),
                        ),
                        backgroundColor: s.$4.withOpacity(0.08),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Every payment is verified with a signed receipt you can share.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const WorkforceRegisterScreen()),
                  ),
                  child: Text(
                    'New here? Register to collect',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PaymentLinksScreen()),
                  ),
                  icon: const Icon(Icons.link_rounded, size: 18),
                  label: Text(
                    'TapVerify Pay — generate a payment link',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sasapay,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}