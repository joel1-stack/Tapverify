import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'treasurer_home_shell.dart';

class WorkforceLoginScreen extends StatefulWidget {
  const WorkforceLoginScreen({super.key});
  @override
  State<WorkforceLoginScreen> createState() => _WorkforceLoginScreenState();
}

class _WorkforceLoginScreenState extends State<WorkforceLoginScreen> {
  final _phone = TextEditingController(text: '0715641339');
  final _pass = TextEditingController(text: '1234');
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _phone.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _login() async {
    final phone = _phone.text.trim();
    final pass = _pass.text.trim();
    if (phone.isEmpty) {
      _warn('Enter your phone number');
      return;
    }
    if (pass.length < 4) {
      _warn('Enter your 4-digit PIN');
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const TreasurerHomeShell(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _warn(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter()),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          children: [
            const SizedBox(height: 40),
            // Logo
            Center(
              child: Image.asset(
                AppAssets.logoFull,
                width: 220,
                errorBuilder: (_, __, ___) => Text('TapVerify',
                    style: GoogleFonts.inter(
                        fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.deep)),
              ),
            ),
            const SizedBox(height: 50),

            // Phone field
            Text('Phone number',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 8),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: _inputDecoration('0715641339', Icons.phone_rounded),
            ),
            const SizedBox(height: 20),

            // PIN field
            Text('PIN',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 8),
            TextField(
              controller: _pass,
              obscureText: _obscure,
              keyboardType: TextInputType.number,
              maxLength: 4,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: _inputDecoration('1234', Icons.lock_rounded).copyWith(
                counterText: '',
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: AppColors.muted, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Demo: 1234',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.muted)),
            ),
            const SizedBox(height: 24),

            // Sign in button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.muted.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Text('Sign in',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w700,
                            color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
          color: AppColors.muted.withValues(alpha: 0.5), fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
