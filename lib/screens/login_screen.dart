import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart';
import 'home_shell.dart';
import 'org_select_screen.dart';

/// Login screen — phone + PIN for the treasurer.
///
/// Animated hero layout; authenticates via [ApiService.login] (demo creds work
/// offline), saves the session, then routes to org selection or home. Shows
/// inline error styling on failed login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController(text: '2547');
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
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
    super.dispose();
  }

  Future<void> _login() async {
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
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed background cover photo
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF059669)],
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
          // Emerald overlay for legibility
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xCC064E3B),
                  Color(0x99059669),
                  Color(0x66059669),
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
                  const SizedBox(height: 40),
                  // Logo with elastic pop-in
                  ScaleTransition(
                    scale: _logoAnim,
                    child: Container(
                      width: 130,
                      height: 130,
                      padding: const EdgeInsets.all(14),
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
                  const SizedBox(height: 16),
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
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Kenya\u2019s chamas & groups',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 34),

                          // Glass Login Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.96),
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
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            AppColors.deep,
                                            AppColors.primary
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                          Icons.lock_outline_rounded,
                                          color: Colors.white,
                                          size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Welcome Back',
                                            style: GoogleFonts.inter(
                                              fontSize: 21,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF064E3B),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Sign in as a group treasurer',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: Colors.grey.shade500,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Phone Number',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  style: GoogleFonts.inter(fontSize: 16),
                                  decoration: InputDecoration(
                                    hintText: '254712345678',
                                    hintStyle: GoogleFonts.inter(
                                        color: Colors.grey.shade400),
                                    prefixIcon: const Icon(Icons.phone_outlined,
                                        color: AppColors.primary),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: AppColors.primary, width: 1.6),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'PIN Code',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _pinCtrl,
                                  obscureText: true,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  style: GoogleFonts.inter(
                                      fontSize: 16, letterSpacing: 8),
                                  decoration: InputDecoration(
                                    hintText: '••••',
                                    hintStyle: GoogleFonts.inter(
                                        color: Colors.grey.shade400),
                                    prefixIcon: const Icon(Icons.lock_outline,
                                        color: AppColors.primary),
                                    counterText: '',
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: AppColors.primary, width: 1.6),
                                    ),
                                  ),
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFFFECACA)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline,
                                            color: Color(0xFFDC2626), size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(_error!,
                                              style: GoogleFonts.inter(
                                                  color:
                                                      const Color(0xFFDC2626),
                                                  fontSize: 13)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 22),
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      shadowColor: AppColors.primary,
                                    ),
                                    child: _loading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5))
                                        : Text('Sign In',
                                            style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                                letterSpacing: 0.3)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Demo Button
                          OutlinedButton.icon(
                            onPressed: _loading
                                ? null
                                : () async {
                                    setState(() => _loading = true);
                                    try {
                                      await ApiService.createDemo();
                                      _phoneCtrl.text = '254712345678';
                                      _pinCtrl.text = '1234';
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(Icons.check_circle,
                                                    color: Colors.white,
                                                    size: 18),
                                                const SizedBox(width: 8),
                                                Text('Demo ready! PIN: 1234',
                                                    style: GoogleFonts.inter()),
                                              ],
                                            ),
                                            backgroundColor: AppColors.primary,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Could not create demo.',
                                                style: GoogleFonts.inter()),
                                            backgroundColor:
                                                const Color(0xFFDC2626),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                          ),
                                        );
                                      }
                                    }
                                    setState(() => _loading = false);
                                  },
                            icon: const Icon(Icons.star_outline_rounded,
                                color: Colors.white, size: 20),
                            label: Text(
                              'Create Demo Workspace',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1.4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Italic footer
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
                                  'TapVerify \u00b7 Making group money transparent',
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
}
