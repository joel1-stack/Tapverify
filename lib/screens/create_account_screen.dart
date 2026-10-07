import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api.dart';
import '../main.dart';
import '../widgets/app_feedback.dart';
import '../widgets/auth_shell.dart';
import 'otp_screen.dart';

/// Create Account: name + phone + group. Registers the profile, then the
/// OTP screen takes over to prove the number before any session is issued.
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _groupController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter your full name');
      return;
    }
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
      final result = await Api.register(
        name: name,
        phone: phone,
        group: _groupController.text.trim(),
      );
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

  void _backToLogin() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      photo: 'assets/screns photos/create-account-bg-woman.jpg',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The card column stretches its children to full width, so this
          // badge needs an Align or its circle paints centred; the mockup
          // shows it at the top-left, above the heading.
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: kPrimaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add_alt_1_outlined,
                  color: kPrimaryDark, size: 24),
            ),
          ),
          const SizedBox(height: 18),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                    text: 'Create ', style: TextStyle(color: kBrandInk)),
                const TextSpan(
                    text: 'Account', style: TextStyle(color: kPrimary)),
              ],
            ),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'For treasurers and group secretaries',
            style: TextStyle(fontSize: 15, color: kMuted),
          ),
          const SizedBox(height: 26),

          // Full name
          const FieldLabel(icon: Icons.person_outline, label: 'Full Name'),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            decoration: authInput(context, hint: 'Your full name'),
          ),
          const SizedBox(height: 20),

          // Phone
          const FieldLabel(
              icon: Icons.phone_outlined, label: 'Phone Number'),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
              LengthLimitingTextInputFormatter(16),
            ],
            decoration: authInput(context, hint: '07XX XXX XXX'),
          ),
          const SizedBox(height: 6),
          const Text(
            'This will be the login number',
            style: TextStyle(fontSize: 12, color: kMuted),
          ),
          const SizedBox(height: 20),

          // Group
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const FieldLabel(
                  icon: Icons.groups_outlined, label: 'Group / Chama Name'),
              const Text(
                '(Optional)',
                style: TextStyle(
                    color: kPrimary, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _groupController,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _create(),
            decoration: authInput(context, hint: 'e.g. Umoja Savings Group'),
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            ErrorNote(message: _error!),
          ],
          const SizedBox(height: 24),
          PrimaryPill(
            label: 'Create Account',
            busy: _busy,
            onPressed: _create,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
                style: TextStyle(color: kTextDark, fontSize: 14.5),
              ),
              GestureDetector(
                onTap: _backToLogin,
                child: const Text(
                  'Log in',
                  style: TextStyle(
                    color: kPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const TrustLine(),
        ],
      ),
    );
  }
}
