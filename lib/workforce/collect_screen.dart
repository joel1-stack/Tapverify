import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_service.dart';
import 'treasurer_home_shell.dart';

/// Collect screen - Ask for Payment
class CollectScreen extends StatefulWidget {
  const CollectScreen({super.key});
  @override
  State<CollectScreen> createState() => _CollectScreenState();
}

class _CollectScreenState extends State<CollectScreen> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    if (title.isEmpty) {
      _snack('Enter what it is for', AppColors.danger);
      return;
    }
    if (amount <= 0) {
      _snack('Enter a valid amount', AppColors.danger);
      return;
    }

    setState(() => _loading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _loading = false);
      
      // Create collection and navigate back
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const TreasurerHomeShell()),
        (route) => false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Payment links sent to all members',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    });
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter()),
      backgroundColor: color,
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
        title: Text('Ask for Payment',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Every payment recorded builds your group proof. This will be sent to all members via SMS.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.primary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // What for
            Text('What for?',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Sept Welfare',
                hintStyle: GoogleFonts.inter(
                    color: AppColors.muted.withValues(alpha: 0.5), fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

            // How much each
            Text('How much each?',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 8),
            TextField(
              controller: _amount,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'Ksh 500',
                hintStyle: GoogleFonts.inter(
                    color: AppColors.muted.withValues(alpha: 0.5), fontSize: 14),
                prefixText: 'Ksh ',
                prefixStyle: GoogleFonts.inter(
                    color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w700),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            const SizedBox(height: 24),

            // Submit button
            ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: Text(_loading ? 'Sending...' : '📤 SEND PAYMENT LINKS',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 12),
            Text('→ Sends SMS to everyone automatically',
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.muted, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}
