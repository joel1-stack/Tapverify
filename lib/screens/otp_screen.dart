import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api.dart';
import '../main.dart';
import '../widgets/app_feedback.dart';
import '../widgets/auth_shell.dart';

/// Code entry: six boxes over one hidden field, resend countdown, then the
/// session lands and the gate swaps in Home.
class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.phone,
    this.devCode,
    this.smsSent = true,
  });

  final String phone;
  final String? devCode;
  final bool smsSent;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _ticker;
  int _secondsLeft = 45;
  bool _busy = false;
  bool _smsFailed = false;
  String? _devCode;
  String? _error;

  @override
  void initState() {
    super.initState();
    _devCode = widget.devCode;
    _smsFailed = !widget.smsSent;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft > 0 && mounted) {
        setState(() => _secondsLeft -= 1);
      }
    });
    // The keyboard comes up on its own; this screen is about the code.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Pretty display for the number the code went to, e.g. +254 712 345 678.
  String get _prettyPhone {
    final digits = widget.phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('0')) return '+254 ${digits.substring(1)}';
    if (digits.startsWith('254')) return '+${digits.substring(0, 3)} ${digits.substring(3)}';
    if (digits.startsWith('7') || digits.startsWith('1')) {
      return '+254 $digits';
    }
    return widget.phone;
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      setState(() => _error = 'Enter all 6 digits from the SMS');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Api.verifyOtp(widget.phone, code);
      if (!mounted) return;
      // Flipping the shared session state swaps the root over to Home, and
      // unwinding to the first route dismisses login and this screen so the
      // secretary cannot press back onto them.
      AuthState.markSignedIn();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await Api.requestOtp(widget.phone);
      if (!mounted) return;
      setState(() {
        _devCode = result['dev_code'] as String?;
        _smsFailed = result['sent'] == false;
        _secondsLeft = 45;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onChanged(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits != _codeController.text) {
      _codeController.text = digits;
      _codeController.selection =
          TextSelection.collapsed(offset: digits.length);
    }
    setState(() => _error = null);
    if (digits.length == 6) _verify();
  }

  @override
  Widget build(BuildContext context) {
    final code = _codeController.text;
    return AuthShell(
      photo: 'assets/screns photos/otp-bg-woman.jpg',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: kPrimaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded,
                color: kPrimaryDark, size: 24),
          ),
          const SizedBox(height: 18),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                    text: 'Enter the ', style: TextStyle(color: kBrandInk)),
                const TextSpan(
                    text: 'code', style: TextStyle(color: kPrimary)),
              ],
            ),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a 6-digit code to',
            style: TextStyle(fontSize: 15.5, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            _prettyPhone,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: kBrandInk,
            ),
          ),
          const SizedBox(height: 24),
          // Six boxes, one hidden field behind them.
          GestureDetector(
            onTap: () => FocusScope.of(context).requestFocus(_focusNode),
            child: Row(
              children: List.generate(6, (i) {
                final active = code.length == i;
                final filled = i < code.length;
                return Expanded(
                  child: Container(
                    height: 58,
                    margin: EdgeInsets.only(right: i == 5 ? 0 : 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: active ? kPrimary : kHairline,
                        width: active ? 2 : 1.5,
                      ),
                    ),
                    child: Text(
                      filled ? code[i] : '-',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: filled ? kBrandInk : kHairline,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(
            height: 0,
            child: TextField(
              controller: _codeController,
              focusNode: _focusNode,
              autofocus: true,
              showCursor: false,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: _onChanged,
              onSubmitted: (_) => _verify(),
              style: const TextStyle(color: Colors.transparent, fontSize: 16),
              decoration: const InputDecoration.collapsed(hintText: ''),
            ),
          ),
          if (_devCode != null) ...[
            const SizedBox(height: 16),
            DevCodeNote(code: _devCode!),
          ],
          if (_smsFailed) ...[
            const SizedBox(height: 16),
            const ErrorNote(
                message: 'We could not send the SMS. Tap Resend to try again.'),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            ErrorNote(message: _error!),
          ],
          const SizedBox(height: 22),
          PrimaryPill(
            label: 'Verify & Continue',
            busy: _busy,
            onPressed: _verify,
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                "Didn't receive the code? ",
                style: TextStyle(color: kMuted, fontSize: 13.5),
              ),
              GestureDetector(
                onTap: _secondsLeft == 0 && !_busy ? _resend : null,
                child: Text(
                  _secondsLeft > 0
                      ? 'Resend (0:${_secondsLeft.toString().padLeft(2, '0')})'
                      : 'Resend',
                  style: TextStyle(
                    color: _secondsLeft == 0 ? kPrimary : kMuted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const TrustLine(
              text: "This helps us keep your group's payments secure"),
        ],
      ),
    );
  }
}
