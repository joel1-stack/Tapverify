import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../api.dart';
import '../main.dart';
import '../models.dart';
import '../utils/format.dart';
import '../widgets/app_feedback.dart';
import 'live_list_screen.dart';

/// One pasted line, as far as the client can tell.
class _PastedMember {
  const _PastedMember(this.name, this.phone);
  final String name;
  final String phone;
}

/// Mirrors the server's parser closely enough to warn before we send an SMS
/// blast, so nobody discovers that half their list was dropped.
List<_PastedMember> _parsePasted(String text) {
  final members = <_PastedMember>[];
  final seen = <String>{};
  for (final rawLine in text.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    // Same shapes the server normalizer accepts, longest prefix first so that
    // `+254712345678` is not read as `0712345678`.
    final match = RegExp(r'\+?254[17]\d{8}|0[17]\d{8}|\b[17]\d{8}\b').firstMatch(line);
    if (match == null) continue;
    final phone = Format.normalizeKenyanPhone(match.group(0)!);
    if (phone == null || !seen.add(phone)) continue;
    final name = line
        .replaceRange(match.start, match.end, ' ')
        .replaceAll(RegExp(r'[,;\t]'), ' ')
        .trim();
    members.add(_PastedMember(name.replaceAll(RegExp(r'\s+'), ' '), phone));
  }
  return members;
}

class CreateCollectionScreen extends StatefulWidget {
  const CreateCollectionScreen({super.key});

  @override
  State<CreateCollectionScreen> createState() => _CreateCollectionScreenState();
}

class _CreateCollectionScreenState extends State<CreateCollectionScreen>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _membersController = TextEditingController();
  final _tillController = TextEditingController();
  final _paybillController = TextEditingController();
  final _paybillAccountController = TextEditingController();
  final _personalPhoneController = TextEditingController();
  final _bankController = TextEditingController();

  String _payoutMethod = 'till';
  DateTime? _dueDate;
  bool _busy = false;
  String? _error;

  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final c in [
      _titleController, _amountController, _membersController, _tillController,
      _paybillController, _paybillAccountController, _personalPhoneController,
      _bankController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> get _payoutFields {
    switch (_payoutMethod) {
      case 'till':
        return {'till_number': _tillController.text.trim()};
      case 'paybill':
        return {
          'paybill_number': _paybillController.text.trim(),
          'paybill_account': _paybillAccountController.text.trim(),
        };
      case 'personal':
        return {'personal_phone': _personalPhoneController.text.trim()};
      case 'bank':
        return {'bank_details': _bankController.text.trim()};
      default:
        return {};
    }
  }

  bool get _payoutValid {
    switch (_payoutMethod) {
      case 'till':
        return _tillController.text.trim().isNotEmpty;
      case 'paybill':
        return _paybillController.text.trim().isNotEmpty;
      case 'personal':
        return _personalPhoneController.text.trim().isNotEmpty;
      case 'bank':
        return _bankController.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _create() async {
    setState(() => _error = null);
    if (_titleController.text.trim().isEmpty) {
      return setState(() => _error = 'Enter a title, e.g. September Welfare');
    }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || !amount.isFinite || amount <= 0) {
      return setState(() => _error = 'Enter the amount per person, e.g. 500');
    }
    // The API stores two decimal places; sending more would be silently rounded.
    if (amount != double.parse(amount.toStringAsFixed(2))) {
      return setState(() => _error = 'Use at most 2 decimal places');
    }
    final members = _parsePasted(_membersController.text);
    if (members.isEmpty) {
      return setState(() => _error = 'Add at least one valid phone number');
    }
    if (!_payoutValid) {
      return setState(() => _error = 'Fill in where people should send the money');
    }
    setState(() => _busy = true);
    try {
      final detail = await Api.createCollection(
        title: _titleController.text.trim(),
        amount: _amountController.text.trim(),
        dueDate: _dueDate == null
            ? null
            : DateFormat('yyyy-MM-dd').format(_dueDate!),
        payoutMethod: _payoutMethod,
        payoutFields: _payoutFields,
        membersText: _membersController.text.trim(),
      );
      if (!mounted) return;
      await _showCreatedDialog(detail);
      if (!mounted) return;
      // Hand the result back to Home so the new collection appears at once.
      Navigator.of(context).pop(true);
      _openLiveList(detail.summary.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openLiveList(int collectionId) {
    final navigator = Navigator.of(context);
    navigator.push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => LiveListScreen(collectionId: collectionId),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.12, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: AppMotion.enter)),
          child: FadeTransition(opacity: animation, child: child),
        ),
        transitionDuration: AppMotion.medium,
      ),
    );
  }

  /// Reports how many invites actually went out, including failures.
  Future<void> _showCreatedDialog(CollectionDetail detail) {
    final failed = detail.notifyFailed;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kSuccess, Color(0xFF15803D)],
                  ),
                  borderRadius: BorderRadius.circular(36),
                ),
                child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Collection created',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kBrandInk),
              ),
              const SizedBox(height: 10),
              Text(
                '"${detail.summary.title}" is live.\n'
                '${detail.notifySent} of ${detail.summary.memberCount} members notified by SMS.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
              ),
              if (failed.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kDanger.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${failed.length} SMS did not go out. '
                    'You can send reminders from the live list.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: kDanger, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Open Live List',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('New Collection',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Color(0xFF111827))),
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionCard(
                title: 'Collection details',
                icon: Icons.edit_note_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StyledField(
                      controller: _titleController,
                      label: 'Title',
                      hint: 'September Welfare',
                      icon: Icons.title_outlined,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _StyledField(
                            controller: _amountController,
                            label: 'Amount per person',
                            prefix: 'KES ',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            icon: Icons.payments_outlined,
                            formatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                              LengthLimitingTextInputFormatter(12),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            dueDate: _dueDate,
                            onPicked: (d) => setState(() => _dueDate = d),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Who is paying?',
                icon: Icons.people_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StyledField(
                      controller: _membersController,
                      label: 'Phone numbers (paste many at once)',
                      hint: 'Mary Wanjiku, 0712345678\nJohn Otieno 0798765432\n0711000000',
                      maxLines: 6,
                      icon: Icons.phone_iphone,
                      maxLength: 20000,
                      formatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z ,.+\-\n\t]')),
                      ],
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    _MemberPreview(text: _membersController.text),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Where should people send the money?',
                icon: Icons.account_balance_wallet_outlined,
                child: Column(
                  children: [
                    _PayoutOption(
                      value: 'till',
                      groupValue: _payoutMethod,
                      title: 'Till Number',
                      subtitle: 'Payments are detected automatically',
                      recommended: true,
                      onChanged: (v) => setState(() => _payoutMethod = v),
                    ),
                    _PayoutOption(
                      value: 'paybill',
                      groupValue: _payoutMethod,
                      title: 'Paybill',
                      subtitle: 'Payments are detected automatically',
                      recommended: true,
                      onChanged: (v) => setState(() => _payoutMethod = v),
                    ),
                    _PayoutOption(
                      value: 'personal',
                      groupValue: _payoutMethod,
                      title: 'My Personal Number',
                      subtitle: 'You mark payments yourself',
                      onChanged: (v) => setState(() => _payoutMethod = v),
                    ),
                    _PayoutOption(
                      value: 'bank',
                      groupValue: _payoutMethod,
                      title: 'Bank Account',
                      subtitle: 'You mark payments yourself',
                      onChanged: (v) => setState(() => _payoutMethod = v),
                    ),
                    const SizedBox(height: 12),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _payoutFieldsWidgets(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kDanger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: kDanger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(color: kDanger, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              FilledButton.icon(
                onPressed: _busy ? null : _create,
                icon: _busy
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_outlined, size: 20),
                label: Text(
                  _busy ? 'Creating...' : 'Create & Notify Everyone',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: kPrimary.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  shadowColor: kPrimary.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _payoutFieldsWidgets() {
    switch (_payoutMethod) {
      case 'till':
        return [
          _StyledField(
            controller: _tillController,
            label: 'Till Number',
            keyboardType: TextInputType.number,
            icon: Icons.store_outlined,
          ),
        ];
      case 'paybill':
        return [
          _StyledField(
            controller: _paybillController,
            label: 'Paybill Number',
            keyboardType: TextInputType.number,
            icon: Icons.receipt_long_outlined,
          ),
          const SizedBox(height: 14),
          _StyledField(
            controller: _paybillAccountController,
            label: 'Account (e.g. member name)',
            icon: Icons.badge_outlined,
          ),
        ];
      case 'personal':
        return [
          _StyledField(
            controller: _personalPhoneController,
            label: 'Your M-Pesa / Airtel number',
            keyboardType: TextInputType.phone,
            icon: Icons.phone_outlined,
          ),
        ];
      case 'bank':
        return [
          _StyledField(
            controller: _bankController,
            label: 'Bank details (bank, account no., name)',
            icon: Icons.account_balance_outlined,
          ),
        ];
      default:
        return [];
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: kPrimary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StyledField extends StatelessWidget {
  const _StyledField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.prefix,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
    this.formatters,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? prefix;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? formatters;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: formatters,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15, height: 1.5),
            prefixText: prefix,
            prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0D9488)),
            prefixIcon: Icon(icon, color: kPrimary, size: 20),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kPrimary, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: maxLines > 1 ? 14 : 16,
              horizontal: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _MemberPreview extends StatelessWidget {
  const _MemberPreview({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return Row(
        children: [
          Icon(Icons.info_outline, size: 15, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'One person per line. Names are optional.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      );
    }

    final members = _parsePasted(text);
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).length;
    final unreadable = lines - members.length;

    if (members.isEmpty) {
      return _PreviewBox(
        color: kDanger,
        icon: Icons.error_outline,
        text: 'No valid Kenyan phone number found yet.',
      );
    }

    final names = members.where((m) => m.name.isNotEmpty).length;
    return _PreviewBox(
      color: unreadable > 0 ? const Color(0xFFB45309) : kSuccess,
      icon: unreadable > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
      text: [
        '${members.length} ${members.length == 1 ? "person" : "people"} ready'
            '${names > 0 ? " ($names with names)" : ""}',
        if (unreadable > 0) '$unreadable line${unreadable == 1 ? "" : "s"} ignored'
            ' (no valid number or duplicate)',
      ].join('. '),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  const _PreviewBox({required this.color, required this.icon, required this.text});

  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.dueDate, required this.onPicked});

  final DateTime? dueDate;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Due date (optional)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 14)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            );
            if (picked != null) onPicked(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18, color: kPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    dueDate == null ? 'None' : DateFormat('d MMM y').format(dueDate!),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: dueDate == null ? Colors.grey[500] : const Color(0xFF111827),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PayoutOption extends StatelessWidget {
  const _PayoutOption({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.onChanged,
    this.recommended = false,
  });

  final String value;
  final String groupValue;
  final String title;
  final String subtitle;
  final bool recommended;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? kPrimary.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? kPrimary : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: kPrimary.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onChanged(value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? kPrimary : Colors.transparent,
                    border: Border.all(
                      color: selected ? kPrimary : Colors.grey[400]!,
                      width: selected ? 0 : 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF111827))),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                if (recommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Recommended',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
