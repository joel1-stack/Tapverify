import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'pay_models.dart';
import 'pay_service.dart';
import 'payment_links_screen.dart';

/// TapVerify Pay — the buyer opens a payment link, pays, and gets a verified
/// receipt while both the buyer and the seller advance their reputation streak.
class PayLinkPayScreen extends StatefulWidget {
  const PayLinkPayScreen({super.key, required this.link});

  final PaymentLink link;

  @override
  State<PayLinkPayScreen> createState() => _PayLinkPayScreenState();
}

class _PayLinkPayScreenState extends State<PayLinkPayScreen> {
  final _buyer = TextEditingController(text: PayService.demoBuyerName);
  bool _running = false;
  ({String ref, String attestation})? _receipt;

  @override
  void dispose() {
    _buyer.dispose();
    super.dispose();
  }

  void _pay() {
    if (_buyer.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter the buyer name', style: GoogleFonts.inter()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => _running = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final receipt =
          PayService.instance.payLink(widget.link, _buyer.text.trim());
      setState(() {
        _running = false;
        _receipt = receipt;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.link;
    final seller = PayService.instance.sellerProfile(l.sellerName);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text(
          'Pay a link',
          style: GoogleFonts.inter(
              fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _amountCard(l),
          const SizedBox(height: 16),
          if (_receipt == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Paying as',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _buyer,
                    decoration: const InputDecoration(
                      labelText: 'Your name',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _running ? null : _pay,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent),
                      icon: Icon(_running
                          ? Icons.hourglass_top_rounded
                          : Icons.lock_open_rounded),
                      label: Text(
                        _running
                            ? 'Verifying payment...'
                            : 'Pay Ksh ${_fmt(l.amount)}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Payment is verified end-to-end. Both you and ${l.sellerName} build a verified streak with every on-time payment.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.muted, height: 1.4),
                  ),
                ],
              ),
            )
          else
            _receiptCard(l, _receipt!),
          const SizedBox(height: 16),
          _streakCard(l, seller),
        ],
      ),
    );
  }

  Widget _amountCard(PaymentLink l) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.deep, AppColors.primary, AppColors.sky],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l.token,
                    style: GoogleFonts.robotoMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${l.paidCount} paid',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Ksh ${_fmt(l.amount)}',
              style: GoogleFonts.inter(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${l.description} · ${l.sellerName}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Receive into ${l.channelDetails}',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptCard(PaymentLink l, ({String ref, String attestation}) r) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.success),
              const SizedBox(width: 8),
              Text(
                'PAYMENT VERIFIED',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row('Reference', r.ref),
          _row('Receipt', 'Verified by TapVerify'),
          _row('Attestation', r.attestation),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const PaymentLinksScreen()),
              (route) => false,
            ),
            icon: const Icon(Icons.check_circle_rounded, size: 18),
            label: Text(
              'Done — back to payment links',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _streakCard(PaymentLink l, StreakProfile seller) {
    final buyer = PayService.instance.buyerProfile(_buyer.text.trim());
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                'REPUTATION STREAKS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _streakRow('${l.sellerName} (receiver)',
              seller.streakMonths, seller.badgesEarned),
          const SizedBox(height: 10),
          _streakRow('${_buyer.text.trim()} (payer)',
              buyer.streakMonths, buyer.badgesEarned),
          const SizedBox(height: 12),
          Text(
            'Badges unlock at 3, 6 and 12 months — a portable proof of financial discipline a SACCO can trust.',
            style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _streakRow(String name, int months, int badges) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$months-mo streak',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.gold,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$badges badges',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              k,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(num n) {
    final s = n.toStringAsFixed(n == n.roundToDouble() ? 0 : 2);
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }
}