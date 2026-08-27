import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'web_dashboard.dart';

class WebLoginPage extends StatefulWidget {
  const WebLoginPage({super.key});
  @override
  State<WebLoginPage> createState() => _WebLoginPageState();
}

class _WebLoginPageState extends State<WebLoginPage> {
  final _phone = TextEditingController(text: '0715641339');
  final _pin = TextEditingController(text: '1234');
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _loading = false;
  final _otpControllers = List.generate(4, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    _phone.dispose();
    _pin.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
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
        content: Text('Invalid OTP — use 1234', style: GoogleFonts.inter()),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _login() async {
    if (!_otpVerified) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Verify your phone number first', style: GoogleFonts.inter()),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    if (_pin.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Enter your PIN', style: GoogleFonts.inter()),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WebDashboard()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final narrow = w < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: narrow ? double.infinity : 400,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Image.asset(AppAssets.logoFull, width: 200),
                const SizedBox(height: 30),

                // Phone
                _label('Phone number'),
                const SizedBox(height: 8),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: _decoration('0715641339', Icons.phone_rounded),
                ),
                const SizedBox(height: 12),

                // OTP
                if (!_otpSent) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: _sendOtp,
                      icon: const Icon(Icons.sms_rounded, size: 18),
                      label: Text('Send OTP', style: GoogleFonts.inter(
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
                                    color: _otpVerified ? AppColors.success : AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                    color: _otpVerified ? AppColors.success : AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
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
                          for (final c in _otpControllers) c.clear();
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

                // PIN
                _label('Password'),
                const SizedBox(height: 8),
                TextField(
                  controller: _pin,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: _decoration('1234', Icons.lock_rounded),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('Forgot PIN?',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ),
                const SizedBox(height: 16),

                // Login
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_loading || !_otpVerified) ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.muted.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : Text('Sign in', style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ",
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
                    GestureDetector(
                      onTap: _goToRegister,
                      child: Text('Sign up',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w800,
                              color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Back to home', style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.muted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goToRegister() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RegisterSheet(),
    );
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
    );
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: AppColors.muted.withOpacity(0.5), fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
      filled: true,
      fillColor: Colors.white,
      counterText: '',
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

class _RegisterSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Create Account', style: GoogleFonts.inter(
              fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Start verifying your revenue', style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 20),
          TextField(
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Business name',
              prefixIcon: const Icon(Icons.business_rounded, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Phone number',
              prefixIcon: const Icon(Icons.phone_rounded, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Choose a password',
              prefixIcon: const Icon(Icons.lock_rounded, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Account created! Sign in.', style: GoogleFonts.inter()),
                  backgroundColor: AppColors.success,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Create account', style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Back to login', style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.muted)),
          ),
        ],
      ),
    );
  }
}
