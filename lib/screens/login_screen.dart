import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api.dart';
import '../main.dart';
import '../widgets/app_feedback.dart';
import '../widgets/auth_shell.dart';
import 'create_account_screen.dart';
import 'otp_screen.dart';

/// Login: photo + wave + white card. Sends the OTP and hands off to the
/// code screen, which owns verification from here.
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
    return AuthShell(
      photo: 'assets/screns photos/login-bg-woman.jpg',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Welcome ',
                  style: TextStyle(color: kBrandInk),
                ),
                const TextSpan(
                  text: 'back',
                  style: TextStyle(color: kPrimary),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your phone number to continue',
            style: TextStyle(fontSize: 15.5, color: kMuted, height: 1.5),
          ),
          const SizedBox(height: 26),
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
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            decoration: authInput(
              context,
              hint: '07XX XXX XXX',
              prefix: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.phone_iphone_outlined,
                    color: kPrimary, size: 20),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            ErrorNote(message: _error!),
          ],
          const SizedBox(height: 22),
          PrimaryPill(
            label: 'Send Code',
            busy: _busy,
            onPressed: _sendCode,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'New here? ',
                style: TextStyle(color: kTextDark, fontSize: 14.5),
              ),
              GestureDetector(
                onTap: _openCreateAccount,
                child: const Text(
                  'Create account',
                  style: TextStyle(
                    color: kPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const TrustLine(),
        ],
      ),
    );
  }
}
