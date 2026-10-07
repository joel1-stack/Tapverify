import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../main.dart';
import '../models.dart';
import '../utils/format.dart';
import '../widgets/app_feedback.dart';
import 'payment_success_screen.dart';

/// Member detail: a bottom sheet on phones, a centred dialog on desktop web.
class MemberDetailSheet extends StatefulWidget {
  const MemberDetailSheet({
    super.key,
    required this.member,
    this.asDialog = false,
    this.collectionTitle = '',
    this.amountLabel = '',
  });

  final Member member;

  /// True when shown inside a [Dialog] on wide displays.
  final bool asDialog;

  /// Shown on the Payment Received confirmation after a manual mark-paid.
  final String collectionTitle;
  final String amountLabel;

  @override
  State<MemberDetailSheet> createState() => _MemberDetailSheetState();
}

class _MemberDetailSheetState extends State<MemberDetailSheet> {
  bool _busy = false;
  bool _changed = false;

  /// [worked] lets an action report a soft failure, like an SMS the provider
  /// refused. That used to show a green "Reminder sent" regardless.
  ///
  /// When [confirmation] is given (mark-paid), it is shown full screen first
  /// and the sheet closes after the secretary taps Done.
  Future<void> _run(
    Future<bool> Function() action,
    String success, {
    bool closeOnSuccess = false,
    String? failureMessage,
    Widget? confirmation,
  }) async {
    setState(() => _busy = true);
    try {
      final ok = await action();
      _changed = true;
      if (!mounted) return;
      if (!ok) {
        showErrorSnack(
          context,
          ApiException(failureMessage ?? 'That did not work. Please try again.'),
        );
        return;
      }
      if (closeOnSuccess) {
        if (confirmation != null) {
          await Navigator.of(context)
              .push<void>(MaterialPageRoute(builder: (_) => confirmation));
        }
        if (mounted) Navigator.pop(context, true);
      } else {
        showSuccessSnack(context, success);
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The full-screen tick shown after a manual mark-paid.
  Widget _paymentConfirmation(Member m) => PaymentSuccessScreen(
        title: widget.collectionTitle.isEmpty ? 'Payment' : widget.collectionTitle,
        amountLabel: widget.amountLabel.isEmpty
            ? (m.paidAmount == null ? '' : Format.kes(m.paidAmount))
            : widget.amountLabel,
        memberName: m.displayName,
      );

  /// WhatsApp's international format: digits only, no "+", never a leading 0.
  static String _waNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('254')) return digits;
    if (digits.startsWith('0')) return '254${digits.substring(1)}';
    if (digits.length == 9) return '254$digits';
    return digits;
  }

  /// Opens this member's chat with the payment link already typed out, so the
  /// secretary just presses send. WhatsApp sends it as the message itself.
  Future<void> _sendWhatsApp(Member m) async {
    final link = (m.payLink ?? '').trim();
    final where = widget.collectionTitle.isEmpty
        ? 'your TapVerify collection'
        : 'your TapVerify collection "${widget.collectionTitle}"';
    final body = link.isEmpty
        ? 'Hi ${m.displayName}, the payment for $where is still due. '
            'Please send it when you can. Thank you!'
        : 'Hi ${m.displayName}, your payment link for $where:\n'
            '$link\nTap the link to open it and pay.';
    final uri = Uri.parse(
        'https://wa.me/${_waNumber(m.phone)}?text=${Uri.encodeComponent(body)}');
    try {
      final ok =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        showErrorSnack(
            context, ApiException('WhatsApp could not be opened.'));
      }
    } catch (_) {
      if (mounted) {
        showErrorSnack(
            context, ApiException('WhatsApp could not be opened.'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    final paid = m.isPaid;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: widget.asDialog
            ? BorderRadius.circular(28)
            : const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: widget.asDialog
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ]
            : null,
      ),
      child: SafeArea(
        top: false,
        // Scrollable so large text settings cannot overflow the sheet.
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 72,
                  height: 72,
                  margin: const EdgeInsets.only(bottom: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: paid
                          ? [kSuccess, kSuccess.withValues(alpha: 0.7)]
                          : [kPrimary, kPrimary.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: (paid ? kSuccess : kPrimary).withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    Format.initial(m.displayName),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(m.displayName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: kBrandInk)),
                const SizedBox(height: 4),
                Text(Format.phone(m.phone),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: (paid ? kSuccess : kDanger).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          paid ? Icons.check_circle : Icons.schedule,
                          color: paid ? kSuccess : kDanger,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          paid ? 'Paid' : 'Not paid',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: paid ? kSuccess : kDanger,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (!paid) ...[
                  FilledButton.icon(
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    onPressed: _busy
                        ? null
                        : () => _run(
                              () => Api.markPaid(m.id, 'cash').then((_) => true),
                              '${m.displayName} marked as Paid (Cash)',
                              closeOnSuccess: true,
                              confirmation: _paymentConfirmation(m),
                            ),
                    label: const Text('Mark as Paid (Cash)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: kSuccess,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: kSuccess.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.swap_horiz_outlined, size: 18),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      foregroundColor: kPrimary,
                      side: const BorderSide(color: kPrimary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _busy
                        ? null
                        : () => _run(
                              () => Api.markPaid(m.id, 'other').then((_) => true),
                              '${m.displayName} marked as Paid (Other)',
                              closeOnSuccess: true,
                              confirmation: _paymentConfirmation(m),
                            ),
                    label: const Text('Mark as Paid (Other)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    icon: const Icon(Icons.sms_outlined, size: 18),
                    onPressed: _busy
                        ? null
                        : () => _run(
                              () => Api.remindMember(m.id),
                              'Reminder sent to ${m.displayName}',
                              failureMessage:
                                  'The SMS could not be sent. Check the number and try again.',
                            ),
                    label: const Text('Send reminder to this person only',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      foregroundColor: kAccentDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    onPressed: _busy ? null : () => _sendWhatsApp(m),
                    label: const Text('Send payment link on WhatsApp',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF075E54),
                      side: const BorderSide(color: Color(0xFF075E54), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ] else ...[
                  _PaidSummary(member: m),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context, _changed),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What was actually received, including a mismatch against the expected amount.
class _PaidSummary extends StatelessWidget {
  const _PaidSummary({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final method = switch (member.paidMethod) {
      'auto' => 'Detected automatically',
      'cash' => 'Marked by you as cash',
      'other' => 'Marked by you as other',
      _ => 'Paid',
    };
    final when = Format.timestampFrom(member.paidAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSuccess.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kSuccess.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: kSuccess, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  member.paidAmount == null
                      ? 'Paid'
                      : 'Paid ${Format.kes(member.paidAmount)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [method, if (when.isNotEmpty) when].join(' · '),
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          if (member.amountMismatch)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'The amount received does not match the expected amount.',
                style: TextStyle(color: kDanger, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          if (member.transactionRef?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Ref: ${member.transactionRef}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
