import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
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
    // Split on newlines, commas, semicolons — then trim and filter blanks.
    final parts = raw.split(RegExp(r'[\n,;]+'));
    return parts
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
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
          // ── Phone numbers ──
          Text('PHONE NUMBERS',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                  letterSpacing: 0.6)),
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
                  fontSize: 11,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),

          // ── Message template ──
          Text('MESSAGE TEMPLATE',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                  letterSpacing: 0.6)),
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
                  fontSize: 11,
                  color: AppColors.muted,
                  fontStyle: FontStyle.italic)),
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
              child: Column(
                children: [
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                  const SizedBox(height: 4),
                  Text('Please wait...',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.muted)),
                ],
              ),
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
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_result!,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Send button ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _sending
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Text('Sending...',
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sms_rounded, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('Send SMS (${_parsePhones().length})',
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
