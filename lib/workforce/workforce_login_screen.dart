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

/// Universal login. One form — phone + PIN. The system resolves the person
/// and greets them by name and position. No role chips, no guessing.
class WorkforceLoginScreen extends StatefulWidget {
  const WorkforceLoginScreen({super.key});

  @override
  State<WorkforceLoginScreen> createState() => _WorkforceLoginScreenState();
}

class _WorkforceLoginScreenState extends State<WorkforceLoginScreen> {
  final _phone = TextEditingController(text: '254701234567');
  final _pin = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _phone.dispose();
    _pin.dispose();
    super.dispose();
  }

  void _login() {
    final user = WorkforceService.login(_phone.text, _pin.text);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No account found. Register first, or check your phone and PIN.',
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
                  'Sign in to your collection dashboard.',
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
                  'New here? Set up your group or personal collection in 60 seconds.',
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
                    'Register to collect',
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