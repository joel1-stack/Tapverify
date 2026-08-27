import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';

/// SMS Test — simulates sending SMS via Africa's Talking.
class SmsTestScreen extends StatefulWidget {
  const SmsTestScreen({super.key});
  @override
  State<SmsTestScreen> createState() => _SmsTestScreenState();
}

class _SmsTestScreenState extends State<SmsTestScreen> {
  final _phone = TextEditingController(text: '0715641339');
  final _message = TextEditingController(
      text: 'TapVerify — Payment Confirmed\n\n'
          'Hello Peter,\n'
          'Ksh 50,000 received by Peter\'s Metal Works.\n\n'
          'Receipt: https://tverify.co.ke/r/TVM-2026-001\n'
          'PIN: 4829\n\n'
          'Save this SMS as proof of payment.');
  bool _sending = false;
  bool _sent = false;
  String? _error;
  final List<_SmsLog> _log = [];

  @override
  void dispose() {
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  void _send() async {
    setState(() {
      _sending = true;
      _sent = false;
      _error = null;
    });

    // Simulate AT API call
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _sending = false;
      _sent = true;
      _log.insert(
          0,
          _SmsLog(
            phone: _phone.text,
            message: _message.text,
            time: DateTime.now(),
            success: true,
            messageId: 'AT-Msg-${DateTime.now().millisecondsSinceEpoch % 100000}',
          ));
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('SMS sent to ${_phone.text}', style: GoogleFonts.inter()),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _sendBulk() async {
    final phones = ['0722345678', '0733456789', '0744567890'];
    setState(() {
      _sending = true;
      _sent = false;
      _error = null;
    });

    for (final p in phones) {
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _log.insert(
            0,
            _SmsLog(
              phone: p,
              message: 'TapVerify bulk reminder',
              time: DateTime.now(),
              success: true,
              messageId: 'AT-Bulk-${DateTime.now().millisecondsSinceEpoch % 100000}',
            ));
      });
    }

    setState(() {
      _sending = false;
      _sent = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Bulk SMS sent to ${phones.length} customers',
          style: GoogleFonts.inter()),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text('SMS Test',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // API status
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 18, color: AppColors.success),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Africa's Talking SMS",
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: AppColors.text)),
                      Text('joelkaunda15 · Sandbox · Shortcode 14434',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Phone
          Text('RECIPIENT',
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: AppColors.muted, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: '0715641339',
              prefixIcon: const Icon(Icons.phone_rounded, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Message
          Text('MESSAGE',
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: AppColors.muted, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          TextField(
            controller: _message,
            maxLines: 6,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Type your SMS message...',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${_message.text.length} / 160 characters',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _message.text.length > 160
                        ? AppColors.danger
                        : AppColors.muted)),
          ),
          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: _sending
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text('Send SMS',
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _sending ? null : _sendBulk,
                    icon: const Icon(Icons.groups_rounded, size: 18),
                    label: Text('Bulk SMS',
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Log
          if (_log.isNotEmpty) ...[
            Text('SEND LOG',
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    color: AppColors.muted, letterSpacing: 0.6)),
            const SizedBox(height: 10),
            ..._log.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          entry.success
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 18,
                          color: entry.success
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.phone,
                                  style: GoogleFonts.inter(
                                      fontSize: 13, fontWeight: FontWeight.w700,
                                      color: AppColors.text)),
                              Text(entry.messageId ?? 'No ID',
                                  style: GoogleFonts.inter(
                                      fontSize: 10, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        Text(
                          '${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _SmsLog {
  final String phone;
  final String message;
  final DateTime time;
  final bool success;
  final String? messageId;
  _SmsLog({
    required this.phone,
    required this.message,
    required this.time,
    required this.success,
    this.messageId,
  });
}
