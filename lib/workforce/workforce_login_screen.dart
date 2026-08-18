import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'foreman_home_shell.dart';
import 'worker_home_screen.dart';
import 'workforce_register_screen.dart';
import '../workforce/workforce_service.dart';
import 'app_background.dart';

/// Workforce role gate. Two-user system: a Foreman runs the factory; a Worker
/// pays. Demo PIN is 1234 for both roles.
class WorkforceLoginScreen extends StatefulWidget {
  const WorkforceLoginScreen({super.key});

  @override
  State<WorkforceLoginScreen> createState() => _WorkforceLoginScreenState();
}

class _WorkforceLoginScreenState extends State<WorkforceLoginScreen> {
  bool _isForeman = true;
  final _phone = TextEditingController(text: WorkforceService.demoForemanPhone);
  final _pin = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _phone.dispose();
    _pin.dispose();
    super.dispose();
  }

  void _roleTap(bool foreman) {
    setState(() {
      _isForeman = foreman;
      _phone.text = foreman
          ? WorkforceService.demoForemanPhone
          : WorkforceService.demoWorkerPhone;
    });
  }

  void _login() {
    final pin = _pin.text.trim();
    if (pin != '1234') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Use the demo PIN 1234', style: GoogleFonts.inter()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => _isForeman
            ? const ForemanHomeShell()
            : const WorkerHomeScreen(),
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
                  'TapVerify Workforce',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  WorkforceService.orgName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _roleButton(
                          active: _isForeman,
                          icon: Icons.supervisor_account_rounded,
                          label: 'Foreman',
                          onTap: () => _roleTap(true),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _roleButton(
                          active: !_isForeman,
                          icon: Icons.badge_rounded,
                          label: 'Worker',
                          onTap: () => _roleTap(false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 22),
                BrightButton(
                  label: _isForeman
                      ? 'Sign in as Foreman'
                      : 'Sign in as Worker',
                  icon: Icons.login_rounded,
                  onPressed: _login,
                ),
                const SizedBox(height: 14),
                Text(
                  'Demo PIN 1234 · Payments rails are simulated here; real keys are wired server-side before launch.',
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
                    'New factory? Register with KYC',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
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

  Widget _roleButton({
    required bool active,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [AppColors.deep, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)
              : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 20,
                color: active ? Colors.white : AppColors.muted),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
