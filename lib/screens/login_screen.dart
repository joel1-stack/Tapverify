import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants.dart';
import '../services/api_service.dart';
import '../services/demo_service.dart';
import '../services/hive_service.dart';
import 'home_shell.dart';
import 'member_home_screen.dart';
import 'org_select_screen.dart';

/// Two-user login.
///
/// **Member** — phone + OTP, no password. OTP is simulated on-device for the
/// demo (a real build routes to an SMS/WhatsApp gateway); membership is matched
/// by phone across every group in the app, then drops into [MemberHomeScreen]
/// where the member sees all their groups in one place.
///
/// **Board** — phone + PIN for treasurers / chairpersons, keeping the existing
/// board flow (org selection → [HomeShell]).
enum LoginRole { member, board }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController(text: '2547');
  final _pinCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  LoginRole _role = LoginRole.member;
  bool _otpSent = false;
  bool _loading = false;
  String? _error;
  String? _sentOtp;
  int _otpSeconds = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _logoAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _logoAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      setState(() => _error = 'Enter a valid 254… phone number');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    // Ensure demo data exists so the member demo works offline.
    if (phone == DemoService.demoPhone) {
      await DemoService.seed();
    }
    final otp = (900000 + Random().nextInt(99999 + 999999 - 900000)).toString();
    setState(() {
      _sentOtp = otp;
      _otpSent = true;
      _loading = false;
      _otpSeconds = 30;
    });
    _startOtpCountdown();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.sms_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'OTP sent to $phone via SMS/WhatsApp',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.deep,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _startOtpCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _otpSeconds = max(0, _otpSeconds - 1));
      return _otpSeconds > 0;
    });
  }

  String get _demoOtp => _sentOtp ?? '123456';

  Future<void> _verifyOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final entered = _otpCtrl.text.trim();
    if (entered.length != 6) {
      setState(() {
        _loading = false;
        _error = 'Enter the 6-digit OTP we sent you';
      });
      return;
    }
    var phone = _phoneCtrl.text.trim();
    var name = 'Member';
    if (phone == DemoService.demoPhone) {
      phone = DemoService.memberDemoPhone;
      name = DemoService.memberDemoName;
    } else {
      for (final m in HiveService.getCachedMembers()) {
        if (m.phone == phone) {
          name = m.name;
          break;
        }
      }
    }
    // Demo OTP always accepts; real gateway would validate here.
    if (entered != _demoOtp && phone != DemoService.memberDemoPhone) {
      setState(() {
        _loading = false;
        _error = 'Wrong OTP. Demo OTP is $_demoOtp';
      });
      return;
    }
    await HiveService.saveMemberAuth(phone, name);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MemberHomeScreen(phone: phone, name: name),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _boardLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result =
          await ApiService.login(_phoneCtrl.text.trim(), _pinCtrl.text.trim());
      if (result['success'] == true) {
        await HiveService.saveAuth(result['token'], result['staff']);
        if (mounted) {
          final orgs = HiveService.getAccessibleWorkspaces();
          final needsSelect = orgs.length > 1 && !HiveService.orgSelectionDone;
          final target =
              needsSelect ? const OrgSelectScreen() : const HomeShell();
          if (orgs.isNotEmpty) {
            await HiveService.setActiveWorkspace(needsSelect
                ? orgs.first['id'].toString()
                : (HiveService.activeWorkspaceId ??
                    orgs.first['id'].toString()));
          }
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => target,
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      } else {
        setState(() => _error = result['error'] ?? 'Login failed');
      }
    } catch (e) {
      setState(() => _error = 'Network error. Check connection.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMember = _role == LoginRole.member;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F4C3A), Color(0xFF2D6A4F)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Image.network(
            'https://images.pexels.com/photos/3184360/pexels-photo-3184360.jpeg?auto=compress&cs=tinysrgb&w=1280',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : const SizedBox.shrink(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xCC0F4C3A),
                  Color(0x992D6A4F),
                  Color(0x660F4C3A),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  ScaleTransition(
                    scale: _logoAnim,
                    child: Container(
                      width: 110,
                      height: 110,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child:
                          Image.asset(AppAssets.logoFull, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        children: [
                          Text(
                            'Proof of payment for',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.92),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "Kenya's organized money",
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.92),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 26),
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.97),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.28),
                                  blurRadius: 30,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Who are you?',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.deep,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Members sign in with OTP. Boards use their PIN.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Role toggle
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F0EA),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      _roleTab(
                                        icon: Icons.person_rounded,
                                        label: 'Member',
                                        subtitle: 'I pay',
                                        selected: isMember,
                                        onTap: () => setState(() {
                                          _role = LoginRole.member;
                                          _otpSent = false;
                                          _error = null;
                                        }),
                                      ),
                                      const SizedBox(width: 4),
                                      _roleTab(
                                        icon: Icons.manage_accounts_rounded,
                                        label: 'Board',
                                        subtitle: 'I run a group',
                                        selected: !isMember,
                                        onTap: () => setState(() {
                                          _role = LoginRole.board;
                                          _otpSent = false;
                                          _error = null;
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 22),

                                if (_role == LoginRole.member)
                                  ..._buildMemberForm()
                                else
                                  ..._buildBoardForm(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (isMember)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.25)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.group_add_rounded,
                                      color: Color(0xFFFFB066), size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'New here? Ask your treasurer to add your number — each group invites you by SMS.',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.9),
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 26),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              children: [
                                Text(
                                  'Every payment. One trusted SMS.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'TapVerify · Making group money transparent',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleTab({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.deep : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.deep.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? Colors.white : Colors.grey.shade500),
              const SizedBox(width: 7),
              Column(
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? Colors.white.withOpacity(0.75)
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMemberForm() {
    return [
      if (_error != null) _errorBanner(),
      Text('Phone Number',
          style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700)),
      const SizedBox(height: 8),
      TextField(
        controller: _phoneCtrl,
        keyboardType: TextInputType.phone,
        style: GoogleFonts.inter(fontSize: 16),
        decoration: InputDecoration(
          hintText: '254712345678',
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
          prefixIcon:
              const Icon(Icons.phone_outlined, color: AppColors.primary),
          filled: true,
          fillColor: const Color(0xFFF8F5F0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE6E0D6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
          ),
        ),
      ),
      const SizedBox(height: 10),
      _demoMemberChip(),
      const SizedBox(height: 18),
      if (!_otpSent)
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _loading ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Text('Send OTP',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.3)),
          ),
        )
      else ...[
        Text('6-digit OTP',
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        TextField(
          controller: _otpCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: GoogleFonts.inter(fontSize: 16, letterSpacing: 10),
          decoration: InputDecoration(
            hintText: '••••••',
            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
            prefixIcon:
                const Icon(Icons.password_rounded, color: AppColors.primary),
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFF8F5F0),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE6E0D6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_sentOtp != null)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accent.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.accent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Demo mode — OTP is $_demoOtp',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _loading ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Text('Verify & continue',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.3)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _otpSeconds > 0
                  ? 'Resend in ${_otpSeconds}s'
                  : 'Didn\u2019t get it?',
              style:
                  GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
            ),
            if (_otpSeconds == 0)
              TextButton(
                onPressed: _loading ? null : _sendOtp,
                child: Text('Resend OTP',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent)),
              ),
          ],
        ),
      ],
    ];
  }

  Widget _demoMemberChip() {
    return InkWell(
      onTap: () => _phoneCtrl.text = DemoService.memberDemoPhone,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.deep.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.deep.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_outline_rounded,
                color: AppColors.deep, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Demo: ${DemoService.memberDemoName} · ${DemoService.memberDemoPhone} — open all their groups in one app',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deep,
                ),
              ),
            ),
            const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.deep, size: 16),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBoardForm() {
    return [
      if (_error != null) _errorBanner(),
      Text('Phone Number',
          style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700)),
      const SizedBox(height: 8),
      TextField(
        controller: _phoneCtrl,
        keyboardType: TextInputType.phone,
        style: GoogleFonts.inter(fontSize: 16),
        decoration: InputDecoration(
          hintText: '254712345678',
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
          prefixIcon:
              const Icon(Icons.phone_outlined, color: AppColors.primary),
          filled: true,
          fillColor: const Color(0xFFF8F5F0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE6E0D6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
          ),
        ),
      ),
      const SizedBox(height: 18),
      Text('PIN Code',
          style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700)),
      const SizedBox(height: 8),
      TextField(
        controller: _pinCtrl,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 6,
        style: GoogleFonts.inter(fontSize: 16, letterSpacing: 8),
        decoration: InputDecoration(
          hintText: '••••',
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFF8F5F0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE6E0D6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
          ),
        ),
      ),
      const SizedBox(height: 22),
      SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _loading ? null : _boardLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: AppColors.accent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Text('Sign In',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.3)),
        ),
      ),
    ];
  }

  Widget _errorBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_error!,
                  style:
                      GoogleFonts.inter(color: AppColors.danger, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
