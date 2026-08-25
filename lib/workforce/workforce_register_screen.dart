import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_models.dart';
import '../workforce/workforce_service.dart';
import 'treasurer_home_shell.dart';
import 'app_background.dart';

/// Register — name, phone (WhatsApp), password. Pick group type or individual.
class WorkforceRegisterScreen extends StatefulWidget {
  const WorkforceRegisterScreen({super.key});

  @override
  State<WorkforceRegisterScreen> createState() => _WorkforceRegisterScreenState();
}

class _WorkforceRegisterScreenState extends State<WorkforceRegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  UserKind _kind = UserKind.organization;
  String _type = 'SACCO / Chama';
  bool _terms = false;

  static const _types = [
    'SACCO / Chama',
    'Church',
    'School',
    'Business',
    'Sports club',
    'Other',
  ];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final password = _password.text.trim();

    if (name.isEmpty) {
      _warn('Enter your name');
      return;
    }
    if (phone.length < 10) {
      _warn('Enter a valid WhatsApp number (254...)');
      return;
    }
    if (password.length < 6) {
      _warn('Password must be 6 digits');
      return;
    }
    if (!_terms) {
      _warn('Accept the terms to continue');
      return;
    }

    final org = _kind == UserKind.organization ? name : 'Personal collection';
    final user = WorkforceService.registerUser(
      name: name,
      phone: phone,
      position: _kind == UserKind.organization ? '$_type · Treasurer' : 'Collector',
      kind: _kind,
      orgName: org,
      pin: password,
    );

    if (_kind == UserKind.organization) {
      WorkforceService.registerOrg(
        name: name,
        phone: phone,
        type: _type,
        monthlyContribution: 0,
      );
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => TreasurerHomeShell(user: user)),
      (route) => false,
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
      body: AppBackground(
        image: AppImages.africanMarket,
        child: Column(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.arrow_back_rounded, color: AppColors.primary, size: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Create account',
                        style: GoogleFonts.inter(
                            fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 8)])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  children: [
                    Text('Who is collecting?',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _kindBtn('Organization', Icons.groups_rounded, UserKind.organization)),
                        const SizedBox(width: 8),
                        Expanded(child: _kindBtn('Individual', Icons.person_rounded, UserKind.individual)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _field('Full name', Icons.person_outline_rounded, _name, hint: _kind == UserKind.organization ? 'e.g. Green Valley SACCO' : 'e.g. Mary Njeri'),
                    const SizedBox(height: 14),
                    _field('WhatsApp number', Icons.phone_rounded, _phone,
                        keyboard: TextInputType.phone, digits: true, maxLen: 12, hint: '2547...'),
                    const SizedBox(height: 14),
                    _field('Password (6 digits)', Icons.lock_outline_rounded, _password,
                        obscure: true, keyboard: TextInputType.number, maxLen: 6),
                    if (_kind == UserKind.organization) ...[
                      const SizedBox(height: 16),
                      Text('Group type',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
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
                                  fontSize: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: AppColors.border)),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    CheckboxListTile(
                      value: _terms,
                      onChanged: (v) => setState(() => _terms = v ?? false),
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        'I accept the TapVerify terms: I collect on behalf of the members listed, I handle their money responsibly, and receipts are the shared proof.',
                        style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.text, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          _kind == UserKind.organization ? 'Create $_type account' : 'Start collecting',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kindBtn(String label, IconData icon, UserKind kind) {
    final active = _kind == kind;
    return GestureDetector(
      onTap: () => setState(() => _kind = kind),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(colors: [AppColors.deep, AppColors.primary])
              : null,
          color: active ? null : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: active ? Colors.white : AppColors.muted),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.muted)),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, IconData icon, TextEditingController ctrl,
      {bool obscure = false, TextInputType? keyboard, bool digits = false, int? maxLen, String? hint}) {
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
        hintText: hint,
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
