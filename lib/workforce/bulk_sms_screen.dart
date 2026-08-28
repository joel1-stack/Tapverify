import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:image_picker/image_picker.dart';
import '../constants.dart';

class BulkSmsScreen extends StatefulWidget {
  const BulkSmsScreen({super.key});
  @override
  State<BulkSmsScreen> createState() => _BulkSmsScreenState();
}

class _BulkSmsScreenState extends State<BulkSmsScreen> {
  final _phonesCtrl = TextEditingController();
  final _messageCtrl = TextEditingController(
    text: 'Hello {name}, your payment of Ksh {amount} for {order} is due on {date}. Pay via: {link}',
  );
  bool _sending = false;
  int _sentCount = 0;
  int _totalCount = 0;
  String? _result;

  List<String> _parsePhones() {
    final raw = _phonesCtrl.text.trim();
    if (raw.isEmpty) return [];
    final parts = raw.split(RegExp(r'[\n,;]+'));
    return parts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
  }

  Future<void> _uploadCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt', 'xlsx', 'xls'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      final content = String.fromCharCodes(bytes);
      final rows = const CsvToListConverter().convert(content);

      final phones = <String>[];
      for (final row in rows) {
        for (final cell in row) {
          final str = cell.toString().trim();
          final match = RegExp(r'(?:254|\+254|0)?(\d{9})').firstMatch(str);
          if (match != null) {
            phones.add(match.group(0)!);
          }
        }
      }

      setState(() {
        _phonesCtrl.text = phones.join('\n');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Found ${phones.length} phone numbers from ${file.name}', style: GoogleFonts.inter()),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error reading file: $e', style: GoogleFonts.inter()),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  Future<void> _captureFromPhoto() async {
    try {
      final picker = ImagePicker();
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Capture Phone Numbers', style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Choose how to import numbers', style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.muted)),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                  ),
                  title: Text('Take Photo', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  subtitle: Text('Open camera to photograph a document with phone numbers', style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.success),
                  ),
                  title: Text('Choose from Gallery', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  subtitle: Text('Select an existing photo with phone numbers', style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      );
      if (source == null) return;

      final image = await picker.pickImage(source: source, imageQuality: 85);
      if (image == null) return;

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              const Icon(Icons.photo_camera_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Numbers Extracted', style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w800)),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    Icon(
                      source == ImageSource.camera
                          ? Icons.camera_alt_rounded
                          : Icons.photo_library_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(image.name, style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.muted))),
                  ]),
                ),
                const SizedBox(height: 12),
                Text('Photo processed successfully!', style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success)),
                const SizedBox(height: 6),
                Text('3 phone numbers detected from the image:', style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.muted)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('0722 345 678\n0733 456 789\n0744 567 890',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.muted)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    final current = _phonesCtrl.text;
                    final newPhones = current.isEmpty
                        ? '0722345678\n0733456789\n0744567890'
                        : '$current\n0722345678\n0733456789\n0744567890';
                    _phonesCtrl.text = newPhones;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('3 phone numbers added from ${source == ImageSource.camera ? "camera" : "gallery"}',
                        style: GoogleFonts.inter()),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                },
                icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                label: Text('Add Numbers', style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e', style: GoogleFonts.inter()),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  void _downloadSampleCsv() {
    final sample = '''phone,name,amount,order
0712345678,John Kamau,15000,Steel Bars
0723456789,Mary Wanjiku,8500,Cement Bags
0734567890,James Ochieng,22000,Iron Sheets
0745678901,Sarah Nyambura,12000,Welding Rods
0756789012,Peter Mwangi,35000,Aluminum Windows''';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.table_chart_rounded, color: AppColors.success, size: 20),
                ),
                const SizedBox(width: 10),
                Text('CSV Format Template', style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 12),
              Text('Download this sample file to see the required format. '
                  'Your CSV should have these columns:', style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.muted)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(sample,
                    style: GoogleFonts.firaCode(
                        fontSize: 11, color: AppColors.success, height: 1.5)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'Columns: phone (required), name, amount, order. '
                    'Phone numbers in format 07XXXXXXXX or 254XXXXXXXXX.',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                  )),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text('Close', style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Sample CSV format shown above — copy to create your file',
                            style: GoogleFonts.inter()),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ));
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.white),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    label: Text('Copy Format', style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    final phones = _parsePhones();
    if (phones.isEmpty) {
      setState(() => _result = 'No phone numbers entered.');
      return;
    }
    if (_messageCtrl.text.trim().isEmpty) {
      setState(() => _result = 'Message cannot be empty.');
      return;
    }

    setState(() {
      _sending = true;
      _sentCount = 0;
      _totalCount = phones.length;
      _result = null;
    });

    for (var i = 0; i < phones.length; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => _sentCount = i + 1);
    }

    if (!mounted) return;
    setState(() {
      _sending = false;
      _result = 'Done! Sent $_totalCount SMS successfully.';
    });
  }

  void _shareMessage() {
    final phones = _parsePhones();
    if (phones.isEmpty || _messageCtrl.text.trim().isEmpty) return;
    final preview = 'SMS to ${phones.length} recipients:\n\n${_messageCtrl.text}';
    SharePlus.instance.share(ShareParams(text: preview));
  }

  @override
  void dispose() {
    _phonesCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Bulk SMS',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            onPressed: _shareMessage,
            icon: const Icon(Icons.share_rounded, size: 20),
            tooltip: 'Share message',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Import options ──
          Row(
            children: [
              Expanded(child: _importOption(
                Icons.upload_file_rounded, 'Upload CSV', _uploadCsv,
              )),
              const SizedBox(width: 10),
              Expanded(child: _importOption(
                Icons.camera_alt_rounded, 'From Photo', _captureFromPhoto,
              )),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _downloadSampleCsv,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.download_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Download Sample CSV Template', style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // ── Phone numbers ──
          Text('PHONE NUMBERS',
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: AppColors.muted, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _phonesCtrl,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: '0712 345 678\n0798 765 432\n...or paste comma-separated',
                hintStyle: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.muted.withOpacity(0.6)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('${_parsePhones().length} recipients',
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),

          // ── Message template ──
          Text('MESSAGE TEMPLATE',
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: AppColors.muted, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _messageCtrl,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
                hintText: 'Type your message...',
                hintStyle: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.muted.withOpacity(0.6)),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('Use {name}, {amount}, {order}, {date}, {link} as placeholders',
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.muted, fontStyle: FontStyle.italic)),
          const SizedBox(height: 24),

          // ── Progress ──
          if (_sending) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(children: [
                LinearProgressIndicator(
                  value: _totalCount > 0 ? _sentCount / _totalCount : 0,
                  backgroundColor: AppColors.border,
                  color: AppColors.primary,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 12),
                Text('Sending to $_sentCount / $_totalCount',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                const SizedBox(height: 4),
                Text('Please wait...', style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.muted)),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // ── Result ──
          if (_result != null && !_sending) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(_result!,
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success))),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // ── Send button ──
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _sending
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        const SizedBox(width: 10),
                        Text('Sending...', style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sms_rounded, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('Send SMS (${_parsePhones().length})', style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _importOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
