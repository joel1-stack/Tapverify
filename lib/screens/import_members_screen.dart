import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../models/member.dart';
import '../services/hive_service.dart';

/// CSV import for the member roster.
///
/// Picks a CSV via [FilePicker], parses it with the `csv` package, shows a
/// preview with row errors and imports valid rows into the active workspace as
/// [Member]s through [HiveService.addMembers].
class ImportMembersScreen extends StatefulWidget {
  const ImportMembersScreen({super.key});

  @override
  State<ImportMembersScreen> createState() => _ImportMembersScreenState();
}

class _ImportMembersScreenState extends State<ImportMembersScreen> {
  bool _picking = false;
  List<Member> _preview = [];
  String? _fileName;
  String? _error;

  Future<void> _pickFile() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _picking = false);
        return;
      }
      final file = result.files.single;
      String content;
      if (file.bytes != null) {
        content = utf8.decode(file.bytes!);
      } else {
        final data = await file.xFile.readAsString();
        content = data;
      }
      final parsed = _parseCsv(content);
      setState(() {
        _preview = parsed.$1;
        _error = parsed.$2;
        _fileName = file.name;
        _picking = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not read file: $e';
        _picking = false;
      });
    }
  }

  Future<void> _pasteCsv() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Paste CSV',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Paste rows as: name,phone,amount',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText:
                    'Grace Wanjiku,254700111222,500\nJohn Otieno,254700222333,500\n...',
                hintStyle: GoogleFonts.inter(
                    color: Colors.grey.shade400, fontSize: 13),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Import',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (text != null && text.trim().isNotEmpty) {
      final parsed = _parseCsv(text);
      setState(() {
        _preview = parsed.$1;
        _error = parsed.$2;
        _fileName = 'Pasted text';
      });
    }
  }

  (List<Member>, String?) _parseCsv(String content) {
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(content);
    final members = <Member>[];
    final wsId = HiveService.activeWorkspaceId ?? 'ws-default';
    final seenCodes = HiveService.getMembersForWorkspace(wsId)
        .map((m) => m.memberCode)
        .toSet();
    int nextNum = seenCodes.isEmpty ? 1 : seenCodes.length + 1;

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 2) continue;
      // Skip header row
      final firstCell = row[0].toString().trim().toLowerCase();
      if (firstCell == 'name' ||
          firstCell == 'member name' ||
          firstCell == 'full name') continue;

      final name = row[0].toString().trim();
      if (name.isEmpty) continue;

      String phone =
          row[1].toString().trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (!phone.startsWith('254') && phone.length == 9) {
        phone = '254$phone';
      } else if (phone.startsWith('0')) {
        phone = '254${phone.substring(1)}';
      }

      double amount = 0;
      if (row.length > 2) {
        amount = double.tryParse(
                row[2].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0;
      }

      String code;
      do {
        code = 'TV${nextNum.toString().padLeft(3, '0')}';
        nextNum++;
      } while (seenCodes.contains(code));
      seenCodes.add(code);

      members.add(Member(
        id: 'member-$code',
        name: name,
        phone: phone,
        memberCode: code,
        balanceDue: amount,
        workspaceId: wsId,
      ));
    }

    if (members.isEmpty) {
      return (members, 'No valid rows found. Use: name,phone,amount');
    }
    return (members, null);
  }

  Future<void> _saveAll() async {
    await HiveService.addMembers(_preview);
    if (mounted) {
      Navigator.pop(context, _preview.length);
    }
  }

  Future<void> _downloadSample() async {
    const sample = 'name,phone,amount\n'
        'Grace Wanjiku,254700111222,500\n'
        'John Otieno,254700222333,500\n'
        'Faith Chebet,254700333444,500\n'
        'David Mwangi,254700444555,500\n'
        'Mary Achieng,254700555666,500\n'
        'Samuel Kiprop,254700666777,500\n';
    await Clipboard.setData(ClipboardData(text: sample));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Sample CSV copied — paste into a file',
                  style: GoogleFonts.inter()),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Import Members',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Hero card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.deep, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.upload_file_rounded,
                    color: Colors.white, size: 32),
                const SizedBox(height: 12),
                Text(
                  'Bulk add your whole group in seconds',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Upload a CSV/Excel export (name, phone, amount) and TapVerify registers every member with a code and balance automatically.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _picking ? null : _pickFile,
              icon: _picking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.folder_open_rounded),
              label: Text(
                _picking ? 'Reading file...' : 'Choose CSV file',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pasteCsv,
                  icon: const Icon(Icons.paste_rounded),
                  label: Text('Paste CSV text',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _downloadSample,
                  icon: const Icon(Icons.description_rounded),
                  label: Text('Sample format',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ],
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: GoogleFonts.inter(
                            color: AppColors.danger, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],

          if (_preview.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Preview — ${_preview.length} members',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text),
                ),
                const Spacer(),
                if (_fileName != null)
                  Flexible(
                    child: Text(
                      _fileName!,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.muted),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: _preview
                    .take(8)
                    .map((m) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              m.name[0].toUpperCase(),
                              style: GoogleFonts.inter(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                          title: Text(m.name,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text('${m.phone} · ${m.memberCode}',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.muted)),
                          trailing: Text(
                            'Ksh ${m.balanceDue.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.danger),
                          ),
                        ))
                    .toList(),
              ),
            ),
            if (_preview.length > 8) ...[
              const SizedBox(height: 8),
              Text(
                '+${_preview.length - 8} more...',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _saveAll,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  'REGISTER ${_preview.length} MEMBERS',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
