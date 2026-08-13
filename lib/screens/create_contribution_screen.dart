import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../services/hive_service.dart';
import '../services/contribution_service.dart';

/// Form to launch a new contribution campaign in the active workspace.
///
/// Picks the contribution type (Regular / One-Time / Emergency / Trip /
/// Project / Loan), amount, frequency, deadline, reminder SMS message, payment
/// rail (LOOP / till / paybill / bank / cash) and partial-payment rules, then
/// persists via [ContributionService.create]. Partial/cycle defaults come from
/// the workspace's own rules ([OrgRules.rulesForWorkspace]) — not just the
/// org-type preset — so every organization enforces what its treasurer set up.
class CreateContributionScreen extends StatefulWidget {
  const CreateContributionScreen({super.key});

  @override
  State<CreateContributionScreen> createState() =>
      _CreateContributionScreenState();
}

class _CreateContributionScreenState extends State<CreateContributionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _deadlineCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  String _contribType = 'Regular';
  String _frequency = 'monthly';
  bool _allowPartial = true;
  double _minPartialPercent = 0;

  String? _selectedRail;
  String? _selectedTill;
  String? _selectedPaybill;
  String? _selectedAccount;

  @override
  void initState() {
    super.initState();
    final ws = HiveService.getActiveWorkspace();
    final rules = OrgRules.rulesForWorkspace(ws);
    final defaultLabel = (rules['labels'] as List).first;
    _titleCtrl.text = defaultLabel.toString();
    _amountCtrl.text = (ws?['contribution'] ?? 5000).toString();
    _allowPartial = rules['allow_partial'] == true;
    _minPartialPercent =
        (rules['min_partial_percent'] as num?)?.toDouble() ?? 0;
    _frequency = rules['frequency']?.toString() ?? 'monthly';
    _messageCtrl.text = TechGroupHelper.defaultMessage(
      defaultLabel.toString(),
      ws?['name']?.toString() ?? 'your group',
      double.tryParse(_amountCtrl.text) ?? 5000,
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _deadlineCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(
          () => _deadlineCtrl.text = picked.toIso8601String().substring(0, 10));
    }
  }

  void _refreshMessage() {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    _messageCtrl.text = TechGroupHelper.defaultMessage(
      _titleCtrl.text.trim(),
      HiveService.getActiveWorkspace()?['name']?.toString() ?? 'your group',
      amount,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Choose how members will pay', style: GoogleFonts.inter()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final ws = HiveService.getActiveWorkspace();
    final amount = double.parse(_amountCtrl.text);
    final campaign = ContributionService.create(
      title: _titleCtrl.text.trim(),
      contribType: _contribType,
      amount: amount,
      frequency: _frequency,
      deadline: _deadlineCtrl.text.isEmpty
          ? DateTime.now().add(const Duration(days: 7)).toIso8601String()
          : DateTime.parse(_deadlineCtrl.text).toIso8601String(),
      message: _messageCtrl.text.trim(),
      paymentMethod: {'rail': _selectedRail, 'label': _methodLabel()},
      allowPartial: _allowPartial,
      minPartial: amount * (_minPartialPercent / 100),
      workspaceId: ws?['id'] ?? '',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Notification sent to ${HiveService.getMembersForWorkspace(ws?['id'] ?? '').length} members',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context, campaign);
  }

  String _methodLabel() {
    final ws = HiveService.getActiveWorkspace();
    switch (_selectedRail) {
      case 'loop':
        return 'LOOP Request-to-Pay (NCBA)';
      case 'till':
        return 'M-PESA Till ${_selectedTill ?? ws?['till_number'] ?? ''}';
      case 'paybill':
        return 'Paybill ${_selectedPaybill ?? ws?['paybill_number'] ?? ''} · Acc ${_selectedAccount ?? '001'}';
      case 'bank':
        return 'Bank transfer · Acc ${_selectedAccount ?? ws?['account_number'] ?? ''}';
      case 'cash':
        return 'Cash on meeting day';
      default:
        return 'LOOP Request-to-Pay (NCBA)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ws = HiveService.getActiveWorkspace();
    final orgType = ws?['type']?.toString() ?? 'Chama';
    final cover = OrgRules.imageFor(orgType);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text('New Contribution',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      cover,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: AppColors.primary.withOpacity(0.15),
                        child: const Center(
                            child: Icon(Icons.campaign_rounded,
                                color: AppColors.primary, size: 48)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 8)
                        ],
                      ),
                      child: Text(orgType.toUpperCase(),
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.deep)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Contribution type', style: _sectionTitle()),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ContributionService.contributionTypes.map((t) {
                  final active = _contribType == t;
                  return ChoiceChip(
                    label: Text(t,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 12.5)),
                    selected: active,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                        color: active ? Colors.white : AppColors.text),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                        color: active ? AppColors.primary : AppColors.border),
                    onSelected: (_) => setState(() {
                      _contribType = t;
                      _refreshMessage();
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Frequency', style: _sectionTitle()),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ContributionService.frequencies.map((f) {
                  final active = _frequency == f;
                  return ChoiceChip(
                    label: Text(
                        f[0].toUpperCase() +
                            f.substring(1).replaceAll('_', ' '),
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 12.5)),
                    selected: active,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                        color: active ? Colors.white : AppColors.text),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                        color: active ? AppColors.primary : AppColors.border),
                    onSelected: (_) => setState(() => _frequency = f),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Title', style: _sectionTitle()),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: _input('e.g. August contribution, Class trip'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
                onChanged: (_) => _refreshMessage(),
              ),
              const SizedBox(height: 16),
              Text('Amount per member', style: _sectionTitle()),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _input('Full amount (Ksh)', prefix: 'Ksh '),
                onChanged: (_) => _refreshMessage(),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              if (_allowPartial && _minPartialPercent > 0)
                Text(
                  'This ${orgType.toLowerCase()} requires at least ${_minPartialPercent.round()}% per partial payment.',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.muted,
                      fontStyle: FontStyle.italic),
                )
              else if (_allowPartial)
                Text(
                    'Members can pay in partials if they can\'t afford the full amount.',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.muted,
                        fontStyle: FontStyle.italic))
              else
                Text(
                    'This ${orgType.toLowerCase()} does not allow partial payments.',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.danger,
                        fontStyle: FontStyle.italic)),
              const SizedBox(height: 16),
              if (!_allowPartial)
                const SizedBox()
              else
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Allow partial payments',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                  subtitle: Text(
                      'Members pay as much as they can, tracked to full settlement',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.muted)),
                  value: _allowPartial,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) => setState(() => _allowPartial = v),
                ),
              const SizedBox(height: 16),
              Text('Deadline', style: _sectionTitle()),
              const SizedBox(height: 8),
              TextFormField(
                controller: _deadlineCtrl,
                readOnly: true,
                onTap: _pickDeadline,
                decoration: _input('Tap to pick deadline date',
                    suffixIcon: Icons.calendar_month_rounded),
              ),
              const SizedBox(height: 16),
              Text('How members will pay', style: _sectionTitle()),
              const SizedBox(height: 8),
              _railChip('loop', Icons.swap_vert_circle_rounded,
                  'LOOP (NCBA) — request to their phone'),
              _railChip('till', Icons.point_of_sale_rounded,
                  'M-PESA Till — big-ticket mobile money'),
              _railChip('paybill', Icons.account_balance_wallet_rounded,
                  'Buy Goods / Paybill'),
              _railChip('bank', Icons.account_balance_rounded, 'Bank transfer'),
              _railChip('cash', Icons.money_rounded, 'Cash on meeting day'),
              if (_selectedRail == 'till') ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: TextEditingController(
                      text: ws?['till_number']?.toString() ?? ''),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _input('Till number'),
                  onChanged: (v) => _selectedTill = v,
                ),
              ],
              if (_selectedRail == 'paybill') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: TextEditingController(
                            text: ws?['paybill_number']?.toString() ?? ''),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: _input('Paybill no.'),
                        onChanged: (v) => _selectedPaybill = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: TextEditingController(text: '001'),
                        keyboardType: TextInputType.number,
                        decoration: _input('Acc no.'),
                        onChanged: (v) => _selectedAccount = v,
                      ),
                    ),
                  ],
                ),
              ],
              if (_selectedRail == 'bank') ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: TextEditingController(
                      text: ws?['account_number']?.toString() ?? ''),
                  keyboardType: TextInputType.number,
                  decoration: _input('Bank account number'),
                  onChanged: (v) => _selectedAccount = v,
                ),
              ],
              const SizedBox(height: 16),
              Text('Message sent to members', style: _sectionTitle()),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageCtrl,
                maxLines: 3,
                decoration: _input('SMS / notification text'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _submit,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text('SEND TO ALL MEMBERS',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 0.4)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _railChip(String value, IconData icon, String title) {
    final selected = _selectedRail == value;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: selected ? AppColors.primary : AppColors.border),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: _selectedRail,
        activeColor: AppColors.primary,
        onChanged: (v) => setState(() => _selectedRail = v),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 19,
                  color: selected ? AppColors.primary : Colors.grey.shade600),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _sectionTitle() => GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text);

  InputDecoration _input(String hint, {String? prefix, IconData? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      suffixIcon: suffixIcon != null
          ? Icon(suffixIcon, color: AppColors.primary)
          : null,
      hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.muted),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6)),
    );
  }
}
