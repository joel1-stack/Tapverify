import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../constants.dart';
import '../workforce/workforce_models.dart';
import '../workforce/workforce_service.dart';
import 'foreman_home_shell.dart';
import 'app_background.dart';
import 'notification_center.dart';

/// Universal registration — one onboarding for every collector.
///
/// Organizations (factory, SACCO, church, school, chama) upload their details
/// and can attach KYC documents. Individuals (someone collecting for a parent's
/// visit, a class project, a family appeal) just give a name + phone, accept
/// the terms and go — no heavy KYC. The collector's name and "terms accepted"
/// always appear on their receipts.
class WorkforceRegisterScreen extends StatefulWidget {
  const WorkforceRegisterScreen({super.key});

  @override
  State<WorkforceRegisterScreen> createState() =>
      _WorkforceRegisterScreenState();
}

class _WorkforceRegisterScreenState extends State<WorkforceRegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController(text: WorkforceService.demoForemanPhone);
  final _monthly = TextEditingController(text: '200');
  final _position = TextEditingController(text: 'Collector');
  UserKind _kind = UserKind.organization;
  String _type = 'Chama / SACCO';
  bool _terms = false;

  static const _types = [
    'Chama / SACCO',
    'Church',
    'School',
    'Factory / Business',
    'Sports club',
    'Funeral / family fund',
    'Other',
  ];

  final List<String> _kycDocs = [];
  List<({String name, String phone, String department})> _imported = [];
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _monthly.dispose();
    _position.dispose();
    super.dispose();
  }

  Future<void> _pickKyc() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (result == null) return;
    setState(() {
      _kycDocs.addAll(result.files.map((f) => f.name));
    });
  }

  Future<void> _pickCsv() async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null) return;
      final bytes = result.files.single.bytes;
      if (bytes == null) return;
      final text = utf8.decode(bytes, allowMalformed: true);
      final rows = const CsvToListConverter().convert(text);
      final parsed = <({String name, String phone, String department})>[];
      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;
        final first = (row[0] ?? '').toString().trim();
        if (i == 0 && first.toLowerCase() == 'name') continue;
        final name = first.isNotEmpty ? first : 'Member ${i + 1}';
        final phone = row.length > 1 ? row[1].toString().trim() : '';
        final dept = row.length > 2 ? row[2].toString().trim() : 'General';
        parsed.add((name: name, phone: phone, department: dept));
      }
      setState(() => _imported = parsed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit() {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty) {
      _warn(_kind == UserKind.organization
          ? 'Enter your organization name.'
          : 'Enter your name.');
      return;
    }
    if (phone.length < 10) {
      _warn('Enter a valid phone number (254...).');
      return;
    }
    if (!_terms) {
      _warn('Accept the terms to start collecting.');
      return;
    }
    final monthly = double.tryParse(_monthly.text.trim()) ?? 0;
    if (_kind == UserKind.organization && monthly <= 0) {
      _warn('Enter a valid monthly contribution.');
      return;
    }
    final org = _kind == UserKind.organization ? name : 'Personal collection';
    final user = WorkforceService.registerUser(
      name: _kind == UserKind.organization
          ? '${name.split(' ').first} ${name.split(' ').length > 1 ? name.split(' ').last : 'Treasurer'}'
          : name,
      phone: phone,
      position: _kind == UserKind.organization
          ? '${_type} · Treasurer'
          : _position.text.trim().isEmpty
              ? 'Collector'
              : _position.text.trim(),
      kind: _kind,
      orgName: org,
      kycApproved: _kind == UserKind.organization && _kycDocs.isNotEmpty,
    );
    if (_kind == UserKind.organization) {
      WorkforceService.registerOrg(
        name: name,
        phone: phone,
        type: _type,
        monthlyContribution: monthly,
      );
      final added = WorkforceService.importWorkers(_imported);
      NotificationCenter.instance.notify(
        title: '${name} is live',
        body: _imported.isNotEmpty
            ? '$added members imported — ready to raise your first collection.'
            : 'Ready to raise your first collection.',
        icon: Icons.storefront_rounded,
        color: AppColors.primary,
      );
    } else {
      NotificationCenter.instance.notify(
        title: 'Account created, $name',
        body: 'Individual collector — terms accepted. You can collect now.',
        icon: Icons.person_rounded,
        color: AppColors.gold,
      );
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => ForemanHomeShell(user: user)),
      (route) => false,
    );
  }

  void _warn(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        image: AppImages.africanMarket,
        child: Column(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Row(
                  children: [
                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.arrow_back_rounded,
                              color: AppColors.primary, size: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Register to collect',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 8),
                            Shadow(color: Colors.black38, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 84,
                      child: Image.asset(AppAssets.logoFull,
                          fit: BoxFit.contain),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: AuthCard(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _step('1', 'Who is collecting?', Icons.person_pin_rounded),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _kindButton(
                              active: _kind == UserKind.organization,
                              icon: Icons.groups_rounded,
                              label: 'Organization',
                              onTap: () =>
                                  setState(() => _kind = UserKind.organization),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _kindButton(
                              active: _kind == UserKind.individual,
                              icon: Icons.person_rounded,
                              label: 'Individual',
                              onTap: () =>
                                  setState(() => _kind = UserKind.individual),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_kind == UserKind.organization) ...[
                      TextField(
                        controller: _name,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Green Valley SACCO',
                          prefixIcon: Icon(Icons.storefront_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final t in _types)
                            ChoiceChip(
                              label: Text(t),
                              selected: _type == t,
                              onSelected: (_) =>
                                  setState(() => _type = t),
                              selectedColor: AppColors.primary,
                              labelStyle: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                color: _type == t
                                    ? Colors.white
                                    : AppColors.text,
                                fontSize: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: AppColors.border),
                              ),
                            ),
                        ],
                      ),
                    ] else ...[
                      TextField(
                        controller: _name,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Mary Njeri',
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _position,
                        decoration: const InputDecoration(
                          labelText: 'What is the collection for?',
                          hintText: 'e.g. Dad\u2019s hospital visit',
                          prefixIcon: Icon(Icons.volunteer_activism_rounded),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone (254...)',
                              prefixIcon: Icon(Icons.phone_iphone_rounded),
                            ),
                          ),
                        ),
                        if (_kind == UserKind.organization) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _monthly,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Monthly (Ksh)',
                                prefixIcon: Icon(Icons.payments_rounded),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (_kind == UserKind.organization) ...[
                      _step('2', 'Members & KYC (optional for small groups)',
                          Icons.verified_user_rounded),
                      const SizedBox(height: 4),
                      Text(
                        'Bigger groups upload a CSV (name, phone, department) and KYC documents to speed up approval. Small chamas can start with the starter roster.',
                        style: GoogleFonts.inter(
                            fontSize: 11.5, color: AppColors.muted, height: 1.5),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _pickCsv,
                        icon: Icon(
                            _busy
                                ? Icons.hourglass_top_rounded
                                : Icons.upload_file_rounded,
                            size: 18),
                        label: Text(
                            _busy
                                ? 'Reading CSV...'
                                : _imported.isEmpty
                                    ? 'Upload members CSV'
                                    : 'Replace CSV'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: const BorderSide(color: AppColors.secondary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      if (_imported.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.secondary.withOpacity(0.25)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  size: 16, color: AppColors.secondary),
                              const SizedBox(width: 8),
                              Text(
                                '${_imported.length} members ready to import',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _pickKyc,
                        icon: const Icon(Icons.badge_rounded, size: 18),
                        label: Text(
                            _kycDocs.isEmpty
                                ? 'Attach KYC documents (ID, reg, utility)'
                                : '${_kycDocs.length} documents attached'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    _step(_kind == UserKind.organization ? '3' : '2',
                        'Payment QR & collector identity',
                        Icons.qr_code_rounded),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          QrImageView(
                            data: WorkforceService.foremanQrPayload,
                            version: QrVersions.auto,
                            size: 148,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${WorkforceService.foremanQrPayload}|${_kind == UserKind.individual ? 'individual' : 'org'}',
                            style: GoogleFonts.inter(
                                fontSize: 9.5, color: AppColors.muted),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _kind == UserKind.individual
                                ? 'Your name, "terms accepted" and the collection purpose appear on every receipt you share.'
                                : 'The collector\u2019s name and KYC status appear on every receipt you share.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.muted,
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    CheckboxListTile(
                      value: _terms,
                      onChanged: (v) => setState(() => _terms = v ?? false),
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        'I accept the TapVerify terms: I collect on behalf of the members listed, I handle their money responsibly, and receipts are the shared proof.',
                        style: GoogleFonts.inter(
                            fontSize: 11.5, color: AppColors.text, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent),
                        icon: const Icon(Icons.rocket_launch_rounded),
                        label: Text(
                            _kind == UserKind.organization
                                ? 'Register ${_type}'
                                : 'Start collecting'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _kind == UserKind.organization
                          ? 'Organizations verify identity; individuals only accept the terms.'
                          : 'No KYC for individuals — you accept the terms and collect.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.muted, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kindButton({
    required bool active,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [AppColors.deep, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)
              : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: active ? Colors.white : AppColors.muted),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(String n, String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              n,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 17, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    );
  }
}