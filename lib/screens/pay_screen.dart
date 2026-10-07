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
/// No login: the payer sees what is due and where to send it, can record a
/// full or partial payment, or close the link when the number is wrong.
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

enum _Outcome { full, partial, cancelled }

class _PayScreenState extends State<PayScreen> {
  late final Future<(CollectionDetail, Member)> _future = _load();
  final _partialController = TextEditingController();
  bool _busy = false;
  bool _partialOpen = false;
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
    _partialController.dispose();
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

  /// Records the full amount the collection asks for.
  Future<void> _payFull(double expected) => _run(() => Api.markPaid(
        widget.memberId,
        'cash',
        amount: expected,
      ).whenComplete(() {
        if (mounted) setState(() => _outcome = _Outcome.full);
      }));

  /// Records whatever the payer says they sent.
  Future<void> _payPartial(double expected) {
    final value =
        double.tryParse(_partialController.text.trim().replaceAll(',', ''));
    if (value == null || value <= 0 || value >= expected) {
      showErrorSnack(
        context,
        ApiException('Enter an amount between KES 1 and ${Format.kes(expected)}'),
      );
      return Future.value();
    }
    return _run(() => Api.markPaid(widget.memberId, 'cash', amount: value)
        .whenComplete(() {
      if (!mounted) return;
      setState(() {
        _outcome = _Outcome.partial;
        _partialOpen = false;
      });
    }));
  }

  void _cancel() => setState(() => _outcome = _Outcome.cancelled);

  void _leave() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => kIsWeb ? const LandingScreen() : const LoginScreen(),
      ),
    );
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
    final remaining = (expected - paidSoFar).clamp(0.0, expected);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
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
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[600]),
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
              const SizedBox(height: 16),
              _payoutBox(s),
              const SizedBox(height: 16),
              if (_outcome != null)
                _outcomeBox(paidSoFar, expected, remaining)
              else if (paid)
                _paidBox(paidSoFar, expected, partial)
              else ...[
                FilledButton.icon(
                  onPressed: _busy ? null : () => _payFull(expected),
                  icon: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline, size: 20),
                  label: Text(
                    _busy ? 'Recording...' : 'I have paid ${Format.kes(expected)}',
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 10),
                if (!_partialOpen)
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _partialOpen = true),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('I am paying part of it',
                        style: TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryDark,
                      side: const BorderSide(color: kPrimary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  )
                else ...[
                  TextField(
                    controller: _partialController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(
                      hintText: 'Amount you sent, e.g. 300',
                      prefixText: 'KES ',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed:
                              _busy ? null : () => _payPartial(expected),
                          style: FilledButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Record payment',
                              style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() => _partialOpen = false),
                        child: const Text('Cancel',
                            style: TextStyle(color: kMuted)),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: _busy ? null : _cancel,
                  icon: const Icon(Icons.close_rounded,
                      size: 17, color: kMuted),
                  label: const Text(
                    'This is the wrong number',
                    style: TextStyle(
                      color: kMuted,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ],
            ],
          ),
        ),
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
      'till' => 'Enter this till number on your phone, pay, then tap '
          '"I have paid" below.',
      'paybill' => 'Pay the paybill with the account number shown, then tap '
          '"I have paid" below.',
      'personal' => 'Send the money to this number, then tap "I have paid" '
          'below.',
      _ => 'Send the transfer to the details above, then tap "I have paid" '
          'below.',
    };
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

  Widget _outcomeBox(double paidSoFar, double expected, double remaining) {
    final outcome = _outcome!;
    final cancelled = outcome == _Outcome.cancelled;
    final icon = cancelled
        ? Icons.block_rounded
        : Icons.check_circle_rounded;
    final color = cancelled ? kMuted : kPrimary;
    final title = switch (outcome) {
      _Outcome.full => 'Payment recorded',
      _Outcome.partial => 'Partial payment recorded',
      _Outcome.cancelled => 'Link closed',
    };
    final body = switch (outcome) {
      _Outcome.full =>
        'Thank you, ${Format.kes(paidSoFar)} received. The treasurer will '
            'confirm it shortly.',
      _Outcome.partial =>
        '${Format.kes(paidSoFar)} of ${Format.kes(expected)} received. '
            '${Format.kes(remaining)} is still due.',
      _Outcome.cancelled =>
        'Nothing was recorded. This link will not accept a payment from '
            'this page.',
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
                    color: cancelled ? kBrandInk : kPrimaryDark,
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

/// Deep green masthead with the white logo, shared look with the app headers.
class _PayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.paddingOf(context).top + 16, 20, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryDark, kPrimary],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppLogo(height: 30, onDark: true),
          SizedBox(height: 14),
          Text(
            'Make your payment',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Check the details, pay, then confirm below.',
            style: TextStyle(
              color: kSoftGreen,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
