import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'workforce_register_screen.dart';
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
  bool _otpSent = false;
  bool _otpVerified = false;
  final _otpControllers = List.generate(4, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    _phone.dispose();
    _pass.dispose();
    for (final c in _otpControllers) { c.dispose(); }
    for (final f in _otpFocusNodes) { f.dispose(); }
    super.dispose();
  }

  void _sendOtp() {
    setState(() => _otpSent = true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('OTP sent to ${_phone.text} — use 1234 for demo',
          style: GoogleFonts.inter()),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _verifyOtp() {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp == '1234') {
      setState(() => _otpVerified = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Phone verified!', style: GoogleFonts.inter()),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Invalid OTP — use 1234 for demo', style: GoogleFonts.inter()),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _login() async {
    if (!_otpVerified) {
      _warn('Verify your phone number first');
      return;
    }
    final pass = _pass.text.trim();
    if (pass.length < 4) {
      _warn('Enter your PIN');
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
            const SizedBox(height: 30),
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
            const SizedBox(height: 40),

            // ── Phone field ──
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
            const SizedBox(height: 12),

            // ── OTP Section ──
            if (!_otpSent) ...[
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _sendOtp,
                  icon: const Icon(Icons.sms_rounded, size: 18),
                  label: Text('Send OTP',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ] else ...[
              // OTP input
              Text(
                _otpVerified ? 'Phone verified' : 'Enter 4-digit OTP',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: _otpVerified ? AppColors.success : AppColors.text),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (int i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _otpControllers[i],
                        focusNode: _otpFocusNodes[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        obscureText: true,
                        style: GoogleFonts.inter(
                            fontSize: 22, fontWeight: FontWeight.w800),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: _otpVerified
                              ? AppColors.success.withOpacity(0.08)
                              : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: _otpVerified
                                    ? AppColors.success
                                    : AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: _otpVerified
                                    ? AppColors.success
                                    : AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                        ),
                        onChanged: (v) {
                          if (v.isNotEmpty && i < 3) {
                            _otpFocusNodes[i + 1].requestFocus();
                          }
                          if (v.isEmpty && i > 0) {
                            _otpFocusNodes[i - 1].requestFocus();
                          }
                          if (i == 3 && v.isNotEmpty) {
                            Future.delayed(
                                const Duration(milliseconds: 200), _verifyOtp);
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
              if (!_otpVerified) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _otpSent = false;
                      for (final c in _otpControllers) { c.clear(); }
                    });
                  },
                  child: Text('Change number',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ],
            ],

            const SizedBox(height: 20),

            // ── PIN field ──
            Text('Password',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 8),
            TextField(
              controller: _pass,
              obscureText: _obscure,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: _inputDecoration('1234', Icons.lock_rounded).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: AppColors.muted, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: Text('Forgot PIN?',
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 8),

            // ── Sign in button ──
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: (_loading || !_otpVerified) ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.muted.withOpacity(0.3),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account? ",
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WorkforceRegisterScreen())),
                  child: Text('Sign up',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ),
              ],
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
          color: AppColors.muted.withOpacity(0.5), fontSize: 14),
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
