import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/app_background.dart';
import 'pay_models.dart';
import 'pay_service.dart';
import 'payment_links_screen.dart';

/// TapVerify Pay — the seller/merchant creates a universal payment link.
/// Anyone with the token can pay (till, paybill, bank or wallet) and both
/// sides build a verified reputation streak.
class CreatePaymentLinkScreen extends StatefulWidget {
  const CreatePaymentLinkScreen({super.key});

  @override
  State<CreatePaymentLinkScreen> createState() =>
      _CreatePaymentLinkScreenState();
}

class _CreatePaymentLinkScreenState extends State<CreatePaymentLinkScreen> {
  final _seller = TextEditingController(text: '');
  final _amount = TextEditingController();
  final _description = TextEditingController(text: 'September welfare');
  String _channel = 'till';
  final _details = TextEditingController(text: '');
  PaymentLink? _created;

  @override
  void dispose() {
    _seller.dispose();
    _amount.dispose();
    _description.dispose();
    _details.dispose();
    super.dispose();
  }

  void _onChannel(String id) {
    setState(() {
      _channel = id;
      _details.text = switch (id) {
        'till' => '',
        'paybill' => '',
        'bank' => '',
        _ => '',
      };
    });
  }

  void _create() {
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    if (_seller.text.trim().isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Add a seller name and a valid amount',
              style: GoogleFonts.inter()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final link = PayService.instance.createLink(
      sellerName: _seller.text.trim(),
      amount: amount,
      description: _description.text.trim().isEmpty
          ? 'Payment'
          : _description.text.trim(),
      channel: _channel,
      channelDetails: _details.text.trim(),
    );
    setState(() => _created = link);
  }

  void _openList() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PaymentLinksScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        image: AppImages.marketStall,
        child: SafeArea(
          child: AuthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.arrow_back_rounded,
                              color: AppColors.primary, size: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Generate a payment link',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                          Text(
                            'Anyone with the token can pay',
                            style: GoogleFonts.inter(
                                fontSize: 11.5, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_created == null) ...[
                  TextField(
                    controller: _seller,
                    decoration: const InputDecoration(
                      labelText: 'Business / group name',
                      prefixIcon: Icon(Icons.business_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.]'))
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Amount (Ksh)',
                      prefixIcon: Icon(Icons.payments_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _description,
                    decoration: const InputDecoration(
                      labelText: 'What is this for?',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Receive into',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in PayService.channels)
                        ChoiceChip(
                          avatar: Icon(
                            c['icon'] as IconData,
                            size: 15,
                            color: _channel == c['id']
                                ? Colors.white
                                : AppColors.muted,
                          ),
                          label: Text(c['label'] as String),
                          selected: _channel == c['id'],
                          onSelected: (_) => _onChannel(c['id'] as String),
                          selectedColor: AppColors.primary,
                          labelStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: _channel == c['id']
                                ? Colors.white
                                : AppColors.text,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _details,
                    decoration: const InputDecoration(
                      labelText: 'Till / paybill / account details',
                      prefixIcon: Icon(Icons.pin_rounded),
                    ),
                  ),
                  const SizedBox(height: 22),
                  BrightButton(
                    label: 'Generate payment link',
                    icon: Icons.link_rounded,
                    onPressed: _create,
                  ),
                ] else ...[
                  _createdLink(_created!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _createdLink(PaymentLink l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Text(
                'PAYMENT LINK READY',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ksh ${_fmt(l.amount)}',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${l.description} · ${l.sellerName}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.deep,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  l.token,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.robotoMono(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share this token — the buyer enters it in the Pay screen.',
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        BrightButton(
          label: 'Open payment links',
          icon: Icons.list_alt_rounded,
          onPressed: _openList,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _created = null),
          child: Text(
            'Create another',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  static String _fmt(num n) {
    final s = n.toStringAsFixed(n == n.roundToDouble() ? 0 : 2);
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }
}