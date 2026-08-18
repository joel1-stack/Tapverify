import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../constants.dart';
import '../workforce/workforce_service.dart';
import 'foreman_home_shell.dart';
import 'app_background.dart';

/// Workforce registration — factory details → KYC document upload → members
/// CSV import → payment QR. This is the onboarding a foreman goes through
/// before the first collection; uploads are staged for the backend later.
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
  String _type = 'Metalworks';

  static const _types = [
    'Metalworks',
    'Textile & Garments',
    'Agro-processing',
    'Construction',
    'Logistics',
    'Hospitality',
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
        // Skip header rows like "name,phone,department"
        if (i == 0 && first.toLowerCase() == 'name') continue;
        final name = first.isNotEmpty ? first : 'Worker ${i + 1}';
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
    final monthly = double.tryParse(_monthly.text.trim()) ?? 0;
    if (name.isEmpty) {
      _warn('Enter your factory name.');
      return;
    }
    if (monthly <= 0) {
      _warn('Enter a valid monthly contribution.');
      return;
    }
    WorkforceService.registerOrg(
      name: name,
      phone: _phone.text.trim(),
      type: _type,
      monthlyContribution: monthly,
    );
    final added = WorkforceService.importWorkers(_imported);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ForemanHomeShell()),
      (route) => false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _imported.isNotEmpty
                ? 'Factory registered — $added workers imported from CSV'
                : 'Factory registered — 47 demo workers ready',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    });
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
                        'Register your factory',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
            _step('1', 'Factory details', Icons.factory_rounded),
            const SizedBox(height: 10),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                hintText: 'e.g. Kamau Metalworks',
                prefixIcon: Icon(Icons.factory_rounded),
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
                    onSelected: (_) => setState(() => _type = t),
                    selectedColor: AppColors.primary,
                    labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: _type == t ? Colors.white : AppColors.text,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: AppColors.border),
                    ),
                  ),
              ],
            ),
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
            ),
            const SizedBox(height: 24),

            _step('2', 'KYC — identity documents',
                Icons.verified_user_rounded),
            const SizedBox(height: 4),
            Text(
              'Who collects the money must be verified. Attach your ID, business registration or utility bill — uploads are staged for admin review before collections go live.',
              style:
                  GoogleFonts.inter(fontSize: 11.5, color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 10),
            if (_kycDocs.isNotEmpty) ...[
              for (final d in _kycDocs)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description_rounded,
                          size: 16, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          d,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.text),
                        ),
                      ),
                      const Icon(Icons.check_circle_rounded,
                          size: 15, color: AppColors.success),
                    ],
                  ),
                ),
            ],
            OutlinedButton.icon(
              onPressed: _pickKyc,
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: Text(
                  _kycDocs.isEmpty ? 'Upload KYC documents' : 'Add more documents'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 24),

            _step('3', 'Members — CSV import or demo roster',
                Icons.groups_rounded),
            const SizedBox(height: 4),
            Text(
              'Upload a CSV (name, phone, department) and every worker gets a code and QR card automatically. No CSV? We seed 47 demo workers.',
              style:
                  GoogleFonts.inter(fontSize: 11.5, color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickCsv,
              icon: Icon(_busy
                  ? Icons.hourglass_top_rounded
                  : Icons.upload_file_rounded,
                  size: 18),
              label: Text(_busy
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
                  border:
                      Border.all(color: AppColors.secondary.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 16, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Text(
                      '${_imported.length} workers ready to import',
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
            const SizedBox(height: 24),

            _step('4', 'Payment QR', Icons.qr_code_rounded),
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
                    size: 168,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    WorkforceService.foremanQrPayload,
                    style: GoogleFonts.inter(
                        fontSize: 10.5, color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Printed as the factory card — workers scan it to pay. KYC-approved orgs go live instantly.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.muted, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent),
                icon: const Icon(Icons.rocket_launch_rounded),
                label: const Text('Register & go live'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'KYC uploads are staged locally for now — the backend review queue wires in before launch.',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 11, color: AppColors.muted, height: 1.4),
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
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}