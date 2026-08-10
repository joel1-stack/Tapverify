import 'package:flutter/material.dart';
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

  Future<void> _confirm() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Collection')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.member.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(widget.member.phone, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text('Code: ${widget.member.memberCode}', style: const TextStyle(fontFamily: 'monospace')),
                    Text('Balance Due: Ksh ${widget.member.balanceDue.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Amount Collected', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: 'Ksh ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Payment Type', style: TextStyle(fontWeight: FontWeight.w600)),
            DropdownButtonFormField<String>(
              value: _eventType,
              items: const [
                DropdownMenuItem(value: 'payment_cash', child: Text('Cash')),
                DropdownMenuItem(value: 'payment_mpesa', child: Text('M-Pesa')),
                DropdownMenuItem(value: 'payment_till', child: Text('Till Payment')),
                DropdownMenuItem(value: 'attendance_only', child: Text('Attendance Only')),
              ],
              onChanged: (v) => setState(() => _eventType = v!),
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _confirm,
                child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('CONFIRM & SEND SMS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
