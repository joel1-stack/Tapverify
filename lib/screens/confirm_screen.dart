import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../models/member.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart';
import 'success_screen.dart';

/// Payment collection step — confirm a member's amount before payout.
///
/// Pre-fills the workspace contribution default, lets the treasurer choose the
/// event type (loop / cash / till / paybill / attendance) and on confirm calls
/// [ApiService.verifyMember] — the LOOP request-to-pay is fired by the backend
/// via the live gateway — landing on [SuccessScreen] with the receipt.
class ConfirmScreen extends StatefulWidget {
  final Member member;
  const ConfirmScreen({super.key, required this.member});

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  final _amountCtrl = TextEditingController();
  String _eventType = 'payment_loop';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final ws = HiveService.getActiveWorkspace();
    _amountCtrl.text = (ws?['contribution'] ?? 5000).toString();
  }

  Future<void> _confirm() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter a valid amount', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final wsId = HiveService.activeWorkspaceId ?? '';

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
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => SuccessScreen(
              memberName: widget.member.name,
              memberPhone: widget.member.phone,
              amount: amount,
              receiptUrl: result['receipt']?['url'] ?? '',
              pin: result['receipt']?['pin'] ?? '',
              queued: result['queued'] == true,
              smsSent: result['sms']?['status'] == 'sent',
            ),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: animation, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              );
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Confirm Collection',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Member Card with Illustration
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C2D12), AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        widget.member.name[0].toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.member.name,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.member.phone,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Image.network(
                    'https://undraw.co/api/illustrations/payment-success.svg',
                    width: 60,
                    height: 60,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.white.withOpacity(0.5),
                        size: 40,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Member Info Bar
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Member Code',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8))),
                      Text(
                        widget.member.memberCode,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade200),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Balance Due',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8))),
                      Text(
                        'Ksh ${widget.member.balanceDue.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFDC2626),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Monthly contribution notice (the "you have to pay" message)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign_rounded,
                      color: AppColors.accent, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You have to pay Ksh ${_contribution()} for ${_orgName()} this month. How did ${widget.member.name} pay?',
                      style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Amount Section
            Text(
              'Amount Collected',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: Text('Ksh',
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent)),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  hintText: '0',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1)),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Quick amount chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _quickChip('+100', 100),
                  const SizedBox(width: 8),
                  _quickChip('+200', 200),
                  const SizedBox(width: 8),
                  _quickChip('+500', 500),
                  const SizedBox(width: 8),
                  _quickChip('+1,000', 1000),
                  const SizedBox(width: 8),
                  _quickChip(
                      'Full balance (Ksh ${widget.member.balanceDue.toStringAsFixed(0)})',
                      widget.member.balanceDue),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment Type
            Text(
              'Payment Type',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _typeChip('payment_cash', 'Cash', Icons.money_rounded),
                _typeChip(
                    'payment_mpesa', 'M-Pesa', Icons.phone_android_rounded),
                _typeChip('payment_till', 'Till', Icons.point_of_sale_rounded),
                _typeChip('payment_loop', 'Loop',
                    Icons.account_balance_wallet_rounded),
                _typeChip(
                    'attendance_only', 'Attendance', Icons.how_to_reg_rounded),
              ],
            ),
            if (_eventType == 'payment_loop') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.primary.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'LOOP Request to Pay (${_tillNumber()}) sent to ${widget.member.name} via NCBA. They approve and pay on their phone.',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Confirm Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, Color(0xFFC2410C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _loading ? null : _confirm,
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            'CONFIRM & SEND SMS',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _contribution() {
    final ws = HiveService.getActiveWorkspace();
    final n = ws?['contribution'];
    if (n is num)
      return n.round().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '500';
  }

  String _orgName() =>
      HiveService.getActiveWorkspace()?['name']?.toString() ?? 'your group';

  String _tillNumber() {
    final ws = HiveService.getActiveWorkspace();
    final n = ws?['till_number']?.toString() ?? '';
    return n.isEmpty ? '9415678' : n;
  }

  Widget _quickChip(String label, double amount) {
    return Material(
      color: const Color(0xFFECFDF5),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () =>
            setState(() => _amountCtrl.text = amount.toStringAsFixed(0)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String value, String label, IconData icon) {
    final selected = _eventType == value;
    return Material(
      color: selected ? AppColors.accent : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _eventType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  selected ? AppColors.accent : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 16,
                color: selected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Icon(icon,
                  size: 16,
                  color: selected ? Colors.white : AppColors.accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
