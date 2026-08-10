import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/member.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart';
import 'success_screen.dart';

class ConfirmScreen extends StatefulWidget {
  final Member member;
  const ConfirmScreen({super.key, required this.member});

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  final _amountCtrl = TextEditingController();
  String _eventType = 'payment_cash';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = widget.member.balanceDue.toStringAsFixed(0);
  }

  Future<void> _confirm() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter a valid amount', style: GoogleFonts.inter()),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final staff = HiveService.getStaff();
    final wsId = staff?['workspace']?['id'] ?? '';

    try {
      final result = await ApiService.verifyMember(
        workspaceId: wsId,
        memberId: widget.member.id,
        amount: amount,
        eventType: _eventType,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SuccessScreen(
              memberName: widget.member.name,
              amount: amount,
              receiptUrl: result['receipt']?['url'] ?? '',
              pin: result['receipt']?['pin'] ?? '',
              queued: result['queued'] == true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.inter())),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Collection')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Member Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF059669).withOpacity(0.1),
                        child: Text(
                          widget.member.name[0].toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.member.name,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0f172a),
                              ),
                            ),
                            Text(
                              widget.member.phone,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Code', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                            Text(
                              widget.member.memberCode,
                              style: GoogleFonts.inter(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Balance Due', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                            Text(
                              'Ksh ${widget.member.balanceDue.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFDC2626),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Amount
            Text(
              'Amount Collected',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                prefixText: 'Ksh ',
                hintText: '0',
              ),
            ),
            const SizedBox(height: 20),

            // Payment Type
            Text(
              'Payment Type',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _eventType,
              items: [
                DropdownMenuItem(value: 'payment_cash', child: Text('Cash', style: GoogleFonts.inter())),
                DropdownMenuItem(value: 'payment_mpesa', child: Text('M-Pesa', style: GoogleFonts.inter())),
                DropdownMenuItem(value: 'payment_till', child: Text('Till Payment', style: GoogleFonts.inter())),
                DropdownMenuItem(value: 'attendance_only', child: Text('Attendance Only', style: GoogleFonts.inter())),
              ],
              onChanged: (v) => setState(() => _eventType = v!),
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 32),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _confirm,
                child: _loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text('CONFIRM & SEND SMS', style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
