import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api.dart';
import '../main.dart';
import '../widgets/app_feedback.dart';
import '../widgets/auth_shell.dart';
import 'create_account_screen.dart';
import 'otp_screen.dart';

/// Login, matching the mockup: the photo runs full height and fades into a
/// deep green panel that holds the welcome line, a white phone pill, the
/// Send Code button and the trust strip. No white card on this screen.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Enter your phone number, e.g. 0712 345 678');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await Api.requestOtp(phone);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            phone: phone,
            devCode: result['dev_code'] as String?,
            smsSent: result['sent'] != false,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openCreateAccount() async {
    await Navigator.of(context)
        .push<void>(MaterialPageRoute(builder: (_) => const CreateAccountScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Scaffold(
      backgroundColor: kDarkGreen,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/screns photos/login-bg-woman.jpg',
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.2),
            cacheWidth: (1400 * dpr).round(),
            errorBuilder: (context, error, stack) =>
                const ColoredBox(color: kDarkGreen),
          ),
          // Photo dissolving into the deep green message panel.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x55005F3C),
                  Color(0xD9004029),
                  Color(0xF2003D28),
                  Color(0xF2003D28),
                ],
                stops: [0.0, 0.28, 0.55, 0.72, 1.0],
              ),
            ),
          ),
          const RepaintBoundary(
            child: CustomPaint(painter: _LoginWavesPainter()),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 42),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppLogo(height: 34, onDark: true),
                        const Spacer(),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Welcome ',
                                style: TextStyle(color: Colors.white),
                              ),
                              const TextSpan(
                                text: 'back',
                                style: TextStyle(color: Color(0xFF6FE7AE)),
                              ),
                            ],
                          ),
                          style: const TextStyle(
                              fontSize: 34, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter your phone number\nto continue',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFC8E6D7),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                            LengthLimitingTextInputFormatter(16),
                          ],
                          onSubmitted: (_) => _sendCode(),
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: kBrandInk),
                          decoration: InputDecoration(
                            hintText: 'Phone number',
                            hintStyle: const TextStyle(color: kMuted),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(Icons.phone_iphone_outlined,
                                  color: kPrimary, size: 20),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide:
                                  const BorderSide(color: kPrimary, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 18, horizontal: 18),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          ErrorNote(message: _error!),
                        ],
                        const SizedBox(height: 20),
                        PrimaryPill(
                          label: 'Send Code',
                          busy: _busy,
                          onPressed: _sendCode,
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'New here? ',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 14.5),
                            ),
                            GestureDetector(
                              onTap: _openCreateAccount,
                              child: const Text(
                                'Create account',
                                style: TextStyle(
                                  color: Color(0xFF6FE7AE),
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const TrustLine(onDark: true),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two faint lighter-green sweeps along the foot of the dark panel, as in
/// the login mockup.
class _LoginWavesPainter extends CustomPainter {
  const _LoginWavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void sweep(double top, double dip, double end, double alpha) {
      final path = Path()
        ..moveTo(0, h * top)
        ..quadraticBezierTo(w * 0.5, h * dip, w, h * end)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(path, Paint()..color = kPrimary.withValues(alpha: alpha));
    }

    sweep(0.80, 0.72, 0.78, 0.28);
    sweep(0.90, 0.85, 0.92, 0.35);
  }

  @override
  bool shouldRepaint(covariant _LoginWavesPainter oldDelegate) => false;
}
