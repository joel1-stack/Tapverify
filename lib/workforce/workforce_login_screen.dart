import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'treasurer_home_shell.dart';
import 'workforce_register_screen.dart';
import 'workforce_forgot_password_screen.dart';
import '../workforce/workforce_service.dart';
import 'app_background.dart';

/// Login — phone + 6-digit password. Clean, fast, universal.
class WorkforceLoginScreen extends StatefulWidget {
  const WorkforceLoginScreen({super.key});

  @override
  State<WorkforceLoginScreen> createState() => _WorkforceLoginScreenState();
}

class _WorkforceLoginScreenState extends State<WorkforceLoginScreen> {
  final _phone = TextEditingController(text: '254701234567');
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _login() async {
    final phone = _phone.text.trim();
    final password = _password.text.trim();

    if (phone.length < 10) {
      _snack('Enter a valid phone number', AppColors.danger);
      return;
    }
    if (password.length < 6) {
      _snack('Password must be 6 digits', AppColors.danger);
      return;
    }

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final user = WorkforceService.login(phone, password);
    if (!mounted) return;
    setState(() => _loading = false);

    if (user == null) {
      _snack('Wrong phone or password', AppColors.danger);
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => TreasurerHomeShell(user: user)),
      (route) => false,
    );
  }

  void _snack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter()),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        image: AppImages.teamMeeting,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(AppAssets.logoFull, width: 140),
                  const SizedBox(height: 8),
                  Text('TapVerify',
                      style: GoogleFonts.inter(
                          fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text)),
                  const SizedBox(height: 4),
                  Text('Collect. Verify. Trust.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary)),
                  const SizedBox(height: 36),
                  _input('Phone (254...)', Icons.phone_rounded, _phone,
                      keyboard: TextInputType.phone, digits: true, maxLen: 12),
                  const SizedBox(height: 16),
                  _input('Password (6 digits)', Icons.lock_rounded, _password,
                      obscure: true, keyboard: TextInputType.number, maxLen: 6),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                      child: Text('Forgot password?',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Sign in',
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR', style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
                    ),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const WorkforceRegisterScreen())),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Create account',
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(String label, IconData icon, TextEditingController ctrl,
      {bool obscure = false, TextInputType? keyboard, bool digits = false, int? maxLen}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure ? _obscure : false,
      keyboardType: keyboard,
      inputFormatters: [
        if (digits) FilteringTextInputFormatter.digitsOnly,
        if (maxLen != null) LengthLimitingTextInputFormatter(maxLen),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: obscure
            ? IconButton(
                icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                onPressed: () => setState(() => _obscure = !_obscure))
            : null,
      ),
    );
  }
}
