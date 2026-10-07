import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api.dart';
import '../main.dart';
import '../models.dart';
import '../utils/format.dart';
import '../widgets/app_feedback.dart';
import 'landing_screen.dart';
import 'login_screen.dart';

/// Public payment page opened from a member's pay link:
/// `https://tapverify.vercel.app/#/pay/<collectionId>/<memberId>`.
///
/// No login. The payer sees what the collection is for and where the money
/// goes, can pay by M-Pesa instructions, claim a full or partial payment
/// with their transaction code, raise an issue, or cancel when the link
/// reached the wrong person. Claims show up on the treasurer's Claims tab.
class PayScreen extends StatefulWidget {
  const PayScreen({
    super.key,
    required this.collectionId,
    required this.memberId,
  });

  final int collectionId;
  final int memberId;

  /// Parses `#/pay/<collectionId>/<memberId>` out of the current URL.
  /// Returns null when the app was not opened from a pay link.
  static (int, int)? parseRoute(Uri uri) {
    final parts = uri.fragment.split('/');
    if (parts.length != 4 || parts[1] != 'pay') return null;
    final collectionId = int.tryParse(parts[2]);
    final memberId = int.tryParse(parts[3]);
    if (collectionId == null || memberId == null) return null;
    return (collectionId, memberId);
  }

  @override
  State<PayScreen> createState() => _PayScreenState();
}

/// What the member did after arriving. Each one shows its own message.
enum _Outcome { claim, partialClaim, issue, cancelled }

class _PayScreenState extends State<PayScreen> {
  late final Future<(CollectionDetail, Member)> _future = _load();
  final _codeController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _issueController = TextEditingController();
  bool _busy = false;

  /// Which small form is open: 'paid', 'partial' or 'issue'.
  String? _form;
  bool _confirmCancel = false;
  bool _showHowTo = false;
  bool _howToStk = false;
  _Outcome? _outcome;
  Member? _member;

  Future<(CollectionDetail, Member)> _load() async {
    final detail = await Api.getCollection(widget.collectionId);
    try {
      final member =
          detail.members.firstWhere((m) => m.id == widget.memberId);
      _member = member;
      return (detail, member);
    } on StateError {
      throw ApiException('This payment link is no longer available.');
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _issueController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<Member> Function() action) async {
    setState(() => _busy = true);
    try {
      final updated = await action();
      if (!mounted) return;
      setState(() => _member = updated);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// "I have already paid" - a claim waiting for the treasurer to confirm.
  Future<void> _submitPaidClaim(double expected) {
    final value =
        double.tryParse(_amountController.text.trim().replaceAll(',', ''));
    if (value == null || value <= 0 || value > expected) {
      showErrorSnack(
        context,
        ApiException('Enter an amount between KES 1 and ${Format.kes(expected)}'),
      );
      return Future.value();
    }
    return _run(() => Api.submitClaim(
          widget.memberId,
          status: 'claimed',
          amount: value,
          code: _codeController.text,
          note: _noteController.text,
        ).then((updated) {
          if (mounted) {
            setState(() {
              _outcome = _Outcome.claim;
              _form = null;
            });
          }
          return updated;
        }));
  }

  /// "Partial payment" - amount sent so far, waiting for confirmation.
  Future<void> _submitPartialClaim(double expected) {
    final value =
        double.tryParse(_amountController.text.trim().replaceAll(',', ''));
    if (value == null || value <= 0 || value >= expected) {
      showErrorSnack(
        context,
        ApiException(
            'Enter an amount between KES 1 and ${Format.kes(expected)}'),
      );
      return Future.value();
    }
    return _run(() => Api.submitClaim(
          widget.memberId,
          status: 'partial',
          amount: value,
          code: _codeController.text,
        ).then((updated) {
          if (mounted) {
            setState(() {
              _outcome = _Outcome.partialClaim;
              _form = null;
            });
          }
          return updated;
        }));
  }

  /// "Raise an issue" - a short message for the treasurer.
  Future<void> _submitIssue() {
    if (_issueController.text.trim().isEmpty) {
      showErrorSnack(
          context, ApiException('Describe your issue, then submit it'));
      return Future.value();
    }
    return _run(() => Api.submitClaim(
          widget.memberId,
          status: 'issue',
          note: _issueController.text,
        ).then((updated) {
          if (mounted) {
            setState(() {
              _outcome = _Outcome.issue;
              _form = null;
            });
          }
          return updated;
        }));
  }

  /// "Wrong person / cancel" - records the cancellation on the request.
  Future<void> _cancelRequest() {
    return _run(() => Api.submitClaim(widget.memberId, status: 'cancelled')
        .then((updated) {
      if (mounted) {
        setState(() {
          _outcome = _Outcome.cancelled;
          _confirmCancel = false;
        });
      }
      return updated;
    }));
  }

  void _leave() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => kIsWeb ? const LandingScreen() : const LoginScreen(),
      ),
    );
  }

  /// The till / paybill / phone number the treasurer configured.
  String _payNumber(CollectionSummary s) => switch (s.payoutMethod) {
        'till' => s.payoutDetails['till_number'] ?? '',
        'paybill' => s.payoutDetails['paybill_number'] ?? '',
        'personal' => s.payoutDetails['personal_phone'] ?? '',
        _ => '',
      };

  Future<void> _copyNumber(CollectionSummary s) async {
    final number = _payNumber(s);
    if (number.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: number));
    if (mounted) showSuccessSnack(context, 'Number copied');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: Column(
        children: [
          _PayHeader(),
          Expanded(
            child: FutureBuilder<(CollectionDetail, Member)>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return _messageCard(
                    icon: Icons.link_off_rounded,
                    title: 'This link is not working',
                    body: friendlyError(snap.error!),
                    showLeave: true,
                  );
                }
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: kPrimary),
                  );
                }
                final (detail, member) = snap.data!;
                return _body(detail, member);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(CollectionDetail detail, Member member) {
    final s = detail.summary;
    final expected = s.amount;
    final shown = _member ?? member;
    final paid = shown.isPaid;
    final paidSoFar = shown.paidAmount ?? 0;
    final partial = paid && paidSoFar < expected;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: -28),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Collection information ─────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kPrimary, kPrimaryDark],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.groups_rounded,
                            color: Colors.white, size: 21),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: kBrandInk,
                              ),
                            ),
                            Text(
                              'for ${shown.displayName}',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      _statusPill(paid: paid, partial: partial),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Amount due',
                    style:
                        TextStyle(fontSize: 12.5, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            Format.kes(expected),
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: kPrimary,
                            ),
                          ),
                        ),
                      ),
                      if (s.dueDate != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: kAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Due ${_dueLabel(s.dueDate!)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: kAccentDark,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (s.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      s.description,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),

                  // ── Main payment options ───────────────────────────────
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _showHowTo = true;
                              _howToStk = true;
                            }),
                    icon: const Icon(Icons.phone_iphone, size: 20),
                    label: const Text(
                      'Pay with M-Pesa (STK Push)',
                      style: TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w800),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _showHowTo = true;
                              _howToStk = false;
                            }),
                    icon: const Icon(Icons.point_of_sale_outlined, size: 18),
                    label: Text(
                      switch (s.payoutMethod) {
                        'till' => 'Send to Till / Number',
                        'paybill' => 'Send to Paybill / Number',
                        'personal' => 'Send to Number',
                        _ => 'Send to Till / Number',
                      },
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryDark,
                      side: const BorderSide(color: kPrimary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  if (_showHowTo) ...[
                    const SizedBox(height: 14),
                    _payoutBox(s),
                  ],
                  const SizedBox(height: 18),

                  // ── Outcome / already paid / other actions ─────────────
                  if (_outcome != null)
                    _outcomeBox()
                  else if (paid)
                    _paidBox(paidSoFar, expected, partial)
                  else ...[
                    if (shown.hasClaim) _claimPendingBox(shown),
                    _sectionTitle('Already paid or have an issue?'),
                    const SizedBox(height: 12),
                    _actionButton(
                      icon: Icons.check_circle_outline,
                      label: 'I Have Already Paid',
                      enabled: !_busy && _form == null,
                      onTap: () => setState(() {
                        _form = 'paid';
                        _confirmCancel = false;
                        _amountController.text =
                            expected.toStringAsFixed(0);
                      }),
                    ),
                    const SizedBox(height: 10),
                    _actionButton(
                      icon: Icons.payments_outlined,
                      label: 'Partial Payment',
                      enabled: !_busy && _form == null,
                      onTap: () => setState(() {
                        _form = 'partial';
                        _confirmCancel = false;
                      }),
                    ),
                    const SizedBox(height: 10),
                    _actionButton(
                      icon: Icons.person_off_outlined,
                      label: 'Wrong Person / Cancel',
                      enabled: !_busy && _form == null && !_confirmCancel,
                      onTap: () => setState(() {
                        _confirmCancel = true;
                        _form = null;
                      }),
                    ),
                    const SizedBox(height: 10),
                    _actionButton(
                      icon: Icons.help_outline,
                      label: 'Raise an Issue',
                      enabled: !_busy && _form == null,
                      onTap: () => setState(() {
                        _form = 'issue';
                        _confirmCancel = false;
                      }),
                    ),
                    if (_form != null) ...[
                      const SizedBox(height: 14),
                      _form == 'paid'
                          ? _paidForm(expected)
                          : _form == 'partial'
                              ? _partialForm(expected)
                              : _issueForm(),
                    ],
                    if (_confirmCancel) ...[
                      const SizedBox(height: 14),
                      _cancelConfirm(),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            // ── Footer ───────────────────────────────────────────────────
            Text(
              'Powered by TapVerify',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'This link was sent by your group treasurer',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return OutlinedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: kPrimaryDark,
        side: const BorderSide(color: kPrimary, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        const Expanded(child: Divider(color: kHairline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: kBrandInk,
            ),
          ),
        ),
        const Expanded(child: Divider(color: kHairline)),
      ],
    );
  }

  InputDecoration _fieldInput(String hint, {String? prefix}) => InputDecoration(
        hintText: hint,
        prefixText: prefix,
        filled: true,
        fillColor: kSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kHairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kHairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimary, width: 1.6),
        ),
      );

  Widget _formButtons({required String submitLabel, required VoidCallback onSubmit}) {
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: _busy ? null : onSubmit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(submitLabel,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 10),
        TextButton(
          onPressed: _busy
              ? null
              : () => setState(() {
                    _form = null;
                    _confirmCancel = false;
                  }),
          child: const Text('Close', style: TextStyle(color: kMuted)),
        ),
      ],
    );
  }

  /// Full payment claim: transaction code, amount, optional note.
  Widget _paidForm(double expected) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPrimaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tell the treasurer what you sent',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: kPrimaryDark,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: _fieldInput('Transaction code, e.g. SJ7K2M9PQ'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: _fieldInput('Amount paid', prefix: 'KES '),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            maxLength: 200,
            decoration: _fieldInput('Note (optional)'),
          ),
          const SizedBox(height: 4),
          _formButtons(
            submitLabel: 'Submit Claim',
            onSubmit: () => _submitPaidClaim(expected),
          ),
        ],
      ),
    );
  }

  /// Partial payment claim: amount first, then the transaction code.
  Widget _partialForm(double expected) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPrimaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Record the part you have paid',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: kPrimaryDark,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: _fieldInput('Amount you paid, e.g. 300',
                prefix: 'KES '),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: _fieldInput('Transaction code'),
          ),
          const SizedBox(height: 14),
          _formButtons(
            submitLabel: 'Submit',
            onSubmit: () => _submitPartialClaim(expected),
          ),
        ],
      ),
    );
  }

  /// Free-text issue for the treasurer.
  Widget _issueForm() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPrimaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Describe your issue',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: kPrimaryDark,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _issueController,
            maxLines: 3,
            maxLength: 500,
            decoration: _fieldInput(
                'I already paid cash to the treasurer'),
          ),
          const SizedBox(height: 4),
          _formButtons(
            submitLabel: 'Submit Issue',
            onSubmit: _submitIssue,
          ),
        ],
      ),
    );
  }

  /// Cancel confirmation: two clear choices, nothing is deleted.
  Widget _cancelConfirm() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kDanger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kDanger.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Are you sure you want to cancel this payment request?',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: kBrandInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick this only if the link reached the wrong person.',
            style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _cancelRequest,
                  style: FilledButton.styleFrom(
                    backgroundColor: kDanger,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Yes, Cancel Request',
                      style: TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _confirmCancel = false),
                  child: const Text('No, Go Back',
                      style: TextStyle(
                          color: kMuted,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Shows a claim this member already sent, before they act again.
  Widget _claimPendingBox(Member member) {
    final (label, text) = switch (member.claimStatus) {
      'claimed' => (
          'Claim sent',
          'You reported a full payment. Waiting for treasurer confirmation.'
        ),
      'partial' => (
          'Partial claim',
          'You reported ${Format.kes(member.claimAmount ?? 0)}. '
              'Waiting for treasurer confirmation.'
        ),
      'cancelled' => (
          'Cancelled',
          'This payment request was cancelled.'
        ),
      'issue' => (
          'Issue sent',
          member.claimNote ?? 'Your issue was sent to the treasurer.'
        ),
      _ => ('Claim sent', 'Waiting for treasurer confirmation.'),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hourglass_top_rounded,
                  size: 18, color: kAccentDark),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: kAccentDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill({required bool paid, required bool partial}) {
    final (label, color) = switch ((paid, partial)) {
      (true, true) => ('Partially paid', kAccentDark),
      (true, false) => ('Paid', kPrimaryDark),
      (false, _) => ('Not paid', kAccentDark),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  /// Where the money goes, straight from the collection settings.
  Widget _payoutBox(CollectionSummary s) {
    final hint = switch (s.payoutMethod) {
      'till' => _howToStk
          ? 'STK Push is not connected yet. Enter this till number on '
              'your phone, pay, then tap "I Have Already Paid" below.'
          : 'Enter this till number on your phone, pay, then tap '
              '"I Have Already Paid" below.',
      'paybill' => _howToStk
          ? 'STK Push is not connected yet. Pay the paybill with the '
              'account number shown, then tap "I Have Already Paid" below.'
          : 'Pay the paybill with the account number shown, then tap '
              '"I Have Already Paid" below.',
      'personal' => _howToStk
          ? 'STK Push is not connected yet. Send the money to this '
              'number, then tap "I Have Already Paid" below.'
          : 'Send the money to this number, then tap '
              '"I Have Already Paid" below.',
      _ => 'Send the transfer to the details above, then tap '
          '"I Have Already Paid" below.',
    };
    final number = _payNumber(s);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Where to send the money',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: kPrimaryDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.payoutLabel,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: kBrandInk,
            ),
          ),
          if (number.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _copyNumber(s),
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy number',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimaryDark,
                  side: const BorderSide(color: kPrimary, width: 1.4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            hint,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey[700],
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _outcomeBox() {
    final outcome = _outcome!;
    final cancelled = outcome == _Outcome.cancelled;
    final icon = switch (outcome) {
      _Outcome.claim => Icons.check_circle_rounded,
      _Outcome.partialClaim => Icons.check_circle_rounded,
      _Outcome.issue => Icons.support_agent_rounded,
      _Outcome.cancelled => Icons.block_rounded,
    };
    final color = cancelled ? kMuted : (outcome == _Outcome.issue ? kAccent : kPrimary);
    final title = switch (outcome) {
      _Outcome.claim => 'Claim submitted',
      _Outcome.partialClaim => 'Claim submitted',
      _Outcome.issue => 'Issue submitted',
      _Outcome.cancelled => 'Payment request cancelled',
    };
    final body = switch (outcome) {
      _Outcome.claim || _Outcome.partialClaim =>
        'Waiting for treasurer confirmation.',
      _Outcome.issue => 'The treasurer will review it.',
      _Outcome.cancelled =>
        'Nothing was recorded. The treasurer will see that this link '
            'was cancelled.',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: cancelled
                        ? kBrandInk
                        : (outcome == _Outcome.issue
                            ? kAccentDark
                            : kPrimaryDark),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.grey[700],
              height: 1.45,
            ),
          ),
          if (cancelled) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _leave,
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimaryDark,
                side: const BorderSide(color: kPrimary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Back to TapVerify',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _paidBox(double paidSoFar, double expected, bool partial) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: kPrimary, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Payment already recorded',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: kPrimaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            partial
                ? '${Format.kes(paidSoFar)} of ${Format.kes(expected)} '
                    'received so far. ${Format.kes(expected - paidSoFar)} '
                    'is still due.'
                : '${Format.kes(paidSoFar)} received. Nothing else to do '
                    'here.',
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.grey[700],
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String body,
    bool showLeave = false,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kHairline),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: kPrimaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 30, color: kPrimaryDark),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: kBrandInk,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey[600], height: 1.5),
                ),
                if (showLeave) ...[
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _leave,
                    child: const Text('Back to TapVerify'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _dueLabel(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return iso;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Deep green masthead: logo plus the "Proof of Payment" badge.
class _PayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.paddingOf(context).top + 16, 20, 44),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryDark, kPrimary],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLogo(height: 28, onDark: true),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Proof of Payment',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
