import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';

/// "POWERED BY 8 LOOP APIS" panel — the money story each of the 8 selected
/// LOOP products powers, rendered in LOOP dark/orange so judges instantly see
/// the value the APIs bring. Embedded directly inside the demos so the API
/// value travels with the flow, instead of living in a separate screen.
class LoopValueStrip extends StatelessWidget {
  const LoopValueStrip({super.key, this.title = 'POWERED BY 8 LOOP APIS'});

  final String title;

  static const _apis = [
    ('Mpesa Prompt', Icons.notifications_active_rounded,
        'One tap, 200 prompts. Every member\'s phone buzzes — no till number to memorize, no screenshot to send.'),
    ('Pay to M-Pesa Till', Icons.storefront_rounded,
        'Members keep the Till they already trust; every payment is auto-matched to the member with a receipt.'),
    ('Pay to Paybill', Icons.account_balance_wallet_rounded,
        'SACCO & church Paybills with per-member accounts — official reconciled records, not WhatsApp screenshots.'),
    ('Transaction Inquiry', Icons.fact_check_rounded,
        '"Did it complete?" One tap shows green SUCCESS or red FAILED. No Sunday-evening phone calls.'),
    ('Transaction History', Icons.insert_drive_file_rounded,
        'End of month, one PDF: who paid, every transfer ID, every timestamp. The notebook is dead.'),
    ('Send Money · M-Pesa', Icons.send_rounded,
        'Funeral payout of Ksh 350,000 to the family lands in 30 seconds, every shilling logged.'),
    ('LOOP Prompt', Icons.swap_vert_rounded,
        'Loop-to-Loop in 2 seconds, zero fees — the free rail TapVerify is already built to ride.'),
    ('Send Money · Loop', Icons.account_balance_rounded,
        'Instant, free transfers between groups — chamas, churches and schools become a financial network.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final a in _apis)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(a.$2, size: 15, color: AppColors.accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.$1,
                            style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const SizedBox(height: 1),
                        Text(a.$3,
                            style: GoogleFonts.inter(
                                fontSize: 10.5,
                                height: 1.35,
                                color: Colors.white60)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 2),
          Text(
            'Collect · reconcile · disburse · future rail — and a treasurer who can trust her ledger.',
            style: GoogleFonts.inter(fontSize: 10.5, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}