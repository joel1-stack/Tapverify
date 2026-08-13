import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../services/hive_service.dart';
import '../services/contribution_service.dart';
import 'home_shell.dart';
import 'member_list_screen.dart';

/// Onboarding / settings form to create a new organization (workspace).
///
/// Collects name, type (from [OrgRules.orgTypes]), default contribution,
/// payment rails (LOOP, till, paybill, bank) and the till/paybill/account
/// details, then persists the workspace via [HiveService.addWorkspace] and
/// drops the treasurer into the [MemberListScreen] embedded mode to add
/// members.
class CreateOrganizationScreen extends StatefulWidget {
  const CreateOrganizationScreen({super.key, this.onboarding = false});

  final bool onboarding;

  @override
  State<CreateOrganizationScreen> createState() =>
      _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState extends State<CreateOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _contribCtrl = TextEditingController(text: '5000');
  final _tillCtrl = TextEditingController();
  final _paybillCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();

  final _types = OrgRules.orgTypes;
  String _type = 'Chama';

  bool _loop = true;
  bool _till = true;
  bool _paybill = false;
  bool _bank = false;
  bool _contribPerMonth = true;

  static const _covers = [
    'https://images.pexels.com/photos/8613092/pexels-photo-8613092.jpeg?auto=compress&cs=tinysrgb&w=1200',
    'https://images.pexels.com/photos/3184388/pexels-photo-3184388.jpeg?auto=compress&cs=tinysrgb&w=1200',
    'https://images.pexels.com/photos/6664174/pexels-photo-6664174.jpeg?auto=compress&cs=tinysrgb&w=1200',
    'https://images.pexels.com/photos/8613084/pexels-photo-8613084.jpeg?auto=compress&cs=tinysrgb&w=1200',
  ];

  static String _coverFor(String type) {
    final i = OrgRules.orgTypes.indexOf(type);
    return i >= 0 ? _covers[i % _covers.length] : _covers.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contribCtrl.dispose();
    _tillCtrl.dispose();
    _paybillCtrl.dispose();
    _accountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final id = 'org-${DateTime.now().millisecondsSinceEpoch}';
    final rails = {
      'loop': _loop,
      'till': _till,
      'paybill': _paybill,
      'bank': _bank,
    };
    final ws = {
      'id': id,
      'name': _nameCtrl.text.trim(),
      'type': _type,
      'contribution': int.tryParse(_contribCtrl.text.trim()) ?? 5000,
      'contribution_cycle': _contribPerMonth ? 'monthly' : 'one-off',
      'rails': rails,
      'till_number': _tillCtrl.text.trim(),
      'paybill_number': _paybillCtrl.text.trim(),
      'account_number': _accountCtrl.text.trim(),
      'rules': OrgRules.rulesFor(_type),
      'created_at': DateTime.now().toIso8601String(),
      'created_by': HiveService.getStaff()?['name'] ?? 'Treasurer',
      'image': _coverFor(_type),
    };
    await HiveService.addWorkspace(ws);
    await HiveService.grantWorkspaceAccess(id, role: 'treasurer');
    if (widget.onboarding) {
      // Welcome: jump straight to adding members
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => const MemberListScreen(embedded: false)),
          (route) => false,
        );
      }
    } else {
      if (mounted) Navigator.pop(context, ws);
    }
  }

  Widget _railToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:
            value ? AppColors.primary.withOpacity(0.06) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color:
                value ? AppColors.primary.withOpacity(0.4) : AppColors.border),
      ),
      child: SwitchListTile(
        activeColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: value
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 19,
                  color: value ? AppColors.primary : Colors.grey.shade600),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.text)),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w400)),
              ],
            ),
          ],
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text(
          widget.onboarding ? 'Create your organization' : 'New Organization',
          style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text),
        ),
        actions: [
          if (widget.onboarding)
            TextButton(
              onPressed: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const HomeShell())),
              child: Text('Skip',
                  style: GoogleFonts.inter(
                      color: AppColors.muted, fontWeight: FontWeight.w600)),
            ),
        ],
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
                      _coverFor(_type),
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: AppColors.primary.withOpacity(0.15),
                        child: const Center(
                            child: Icon(Icons.groups_rounded,
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
                      child: Text(_type.toUpperCase(),
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.deep)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Type', style: _sectionTitle()),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _types.map((t) {
                  final active = _type == t;
                  return ChoiceChip(
                    label: Text(t,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    selected: active,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                        color: active ? Colors.white : AppColors.text),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                        color: active ? AppColors.primary : AppColors.border),
                    onSelected: (_) => setState(() => _type = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        OrgRules.rulesFor(_type)['description'],
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Organization name', style: _sectionTitle()),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _input('e.g. Umoja Chama, Pamoja SACCO'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter organization name'
                    : null,
              ),
              const SizedBox(height: 16),
              Text('Monthly contribution', style: _sectionTitle()),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contribCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration:
                    _input('Amount per member per cycle (Ksh)', prefix: 'Ksh '),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                  'Some groups collect over Ksh 1,000,000 per month. TapVerify handles it.',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.muted,
                      fontStyle: FontStyle.italic)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.payment_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('How members will pay', style: _sectionTitle()),
                ],
              ),
              const SizedBox(height: 8),
              _railToggle(
                icon: Icons.swap_vert_circle_rounded,
                title: 'LOOP (NCBA) Request-to-Pay',
                subtitle: 'Top rail - instant bank request to each member',
                value: _loop,
                onChanged: (v) => setState(() => _loop = v),
              ),
              _railToggle(
                icon: Icons.point_of_sale_rounded,
                title: 'M-PESA / Till',
                subtitle: 'Big-ticket mobile money via your till number',
                value: _till,
                onChanged: (v) => setState(() => _till = v),
              ),
              if (_till)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TextFormField(
                    controller: _tillCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _input('Till number'),
                  ),
                ),
              _railToggle(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Buy Goods / Paybill',
                subtitle: 'For members paying via their Safaricom app',
                value: _paybill,
                onChanged: (v) => setState(() => _paybill = v),
              ),
              if (_paybill)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _paybillCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: _input('Paybill no.'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _accountCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: _input('Acc. no.'),
                      ),
                    ),
                  ],
                ),
              _railToggle(
                icon: Icons.account_balance_rounded,
                title: 'Bank transfer',
                subtitle: 'Co-op / Equity / KCB corporate account',
                value: _bank,
                onChanged: (v) => setState(() => _bank = v),
              ),
              const SizedBox(height: 24),
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
                      const Icon(Icons.add_business_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                          widget.onboarding
                              ? 'Create & add members'
                              : 'Create organization',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (!widget.onboarding)
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: GoogleFonts.inter(color: AppColors.muted)),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _sectionTitle() => GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text);

  InputDecoration _input(String hint, {String? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
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
