import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_models.dart';
import '../workforce/workforce_service.dart';
import 'treasurer_home_shell.dart';

class WorkforceRegisterScreen extends StatefulWidget {
  const WorkforceRegisterScreen({super.key});
  @override
  State<WorkforceRegisterScreen> createState() => _WorkforceRegisterScreenState();
}

class _WorkforceRegisterScreenState extends State<WorkforceRegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  String _type = 'Business';
  bool _loading = false;

  static const _types = [
    'Business', 'SACCO / Chama', 'Church', 'School', 'Sports club', 'Other',
  ];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final pass = _pass.text.trim();
    if (name.isEmpty) { _snack('Enter your name'); return; }
    if (phone.length < 10) { _snack('Enter a valid phone number'); return; }
    if (pass.length < 4) { _snack('Password must be at least 4 characters'); return; }

    setState(() => _loading = true);
    WorkforceService.registerUser(
      name: name, phone: phone,
      position: '$_type · Owner',
      kind: UserKind.organization, orgName: name, pin: pass,
    );
    WorkforceService.registerOrg(
      name: name, phone: phone, type: _type, monthlyContribution: 0,
    );

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const TreasurerHomeShell()),
          (route) => false,
        );
      }
    });
  }

  void _snack(String msg) {
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
            const SizedBox(height: 20),
            // Logo
            Center(
              child: Image.asset(
                AppAssets.logoFull,
                width: 200,
                errorBuilder: (_, __, ___) => Text('TapVerify',
                    style: GoogleFonts.inter(
                        fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.deep)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text('Create account',
                  style: GoogleFonts.inter(
                      fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text)),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text('Start verifying your revenue',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
            ),
            const SizedBox(height: 30),

            _label('Business name'),
            const SizedBox(height: 8),
            _field("e.g. Peter's Metal Works", Icons.business_rounded, _name),

            const SizedBox(height: 16),
            _label('Phone number'),
            const SizedBox(height: 8),
            _field('0712345678', Icons.phone_rounded, _phone,
                keyboard: TextInputType.phone),

            const SizedBox(height: 16),
            _label('Password'),
            const SizedBox(height: 8),
            _field('Choose a password', Icons.lock_rounded, _pass, obscure: true),

            const SizedBox(height: 16),
            _label('Business type'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                for (final t in _types)
                  ChoiceChip(
                    label: Text(t),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                    selectedColor: AppColors.primary,
                    labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: _type == t ? Colors.white : AppColors.text,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Text('Create account',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account? ',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text('Sign in',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text));
  }

  Widget _field(String hint, IconData icon, TextEditingController ctrl,
      {bool obscure = false, TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure ? _obscure : false,
      keyboardType: keyboard,
      textCapitalization: TextCapitalization.words,
      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
            color: AppColors.muted.withOpacity(0.5), fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
        suffixIcon: obscure
            ? IconButton(
                icon: Icon(
                    _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: AppColors.muted, size: 20),
                onPressed: () => setState(() => _obscure = !_obscure))
            : null,
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
      ),
    );
  }
}
