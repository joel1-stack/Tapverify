import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'pay_models.dart';
import 'pay_service.dart';
import 'create_payment_link_screen.dart';
import 'pay_link_pay_screen.dart';

/// TapVerify Pay — all payment links. A merchant creates a link, a buyer pays
/// it, and both sides build a verified streak.
class PaymentLinksScreen extends StatefulWidget {
  const PaymentLinksScreen({super.key});

  @override
  State<PaymentLinksScreen> createState() => _PaymentLinksScreenState();
}

class _PaymentLinksScreenState extends State<PaymentLinksScreen> {
  final _buyerToken = TextEditingController();

  @override
  void dispose() {
    _buyerToken.dispose();
    super.dispose();
  }

  void _payToken() {
    final t = _buyerToken.text.trim();
    if (t.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter the payment token you received',
              style: GoogleFonts.inter()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final link = PayService.instance.byToken(t);
    if (link == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No payment link found for "$t"',
              style: GoogleFonts.inter()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PayLinkPayScreen(link: link)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final links = PayService.instance.links;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text(
          'TapVerify Pay',
          style: GoogleFonts.inter(
              fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        color: AppColors.accent,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _payCard(),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'PAYMENT LINKS',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.muted,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                Text(
                  '${links.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (links.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.link_off_rounded,
                        size: 34, color: AppColors.muted),
                    const SizedBox(height: 8),
                    Text(
                      'No payment links yet.',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Generate one for a shop, chama, SACCO or any group with many members.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 11.5, color: AppColors.muted, height: 1.4),
                    ),
                  ],
                ),
              )
            else
              for (final l in links) ...[
                _linkCard(l),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 12),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePaymentLinkScreen()),
        ),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_link_rounded),
        label: Text(
          'Generate link',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _payCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'I want to PAY — enter the token',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _buyerToken,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'e.g. KM8T2PFX',
              prefixIcon: Icon(Icons.key_rounded),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _payToken,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              icon: const Icon(Icons.lock_open_rounded, size: 18),
              label: Text(
                'Open payment link',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkCard(PaymentLink l) {
    final channel = PayService.channels
        .firstWhere((c) => c['id'] == l.channel,
            orElse: () => const {'id': 'till', 'label': 'Till'})
        ['label'] as String;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PayLinkPayScreen(link: l)),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l.token,
                      style: GoogleFonts.robotoMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l.closed ? 'Closed' : '${l.paidCount} paid',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: l.closed ? AppColors.muted : AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l.description,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${l.sellerName} · Ksh ${_fmt(l.amount)} · $channel',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(num n) {
    final s = n.toStringAsFixed(n == n.roundToDouble() ? 0 : 2);
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }
}