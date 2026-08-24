import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_models.dart';
import '../workforce/workforce_service.dart';
import 'workforce_login_screen.dart';
import 'pricing_screen.dart';
import 'collection_settings_screen.dart';
import '../pay/payment_links_screen.dart';

/// Workforce More — product console: rails, the 9-state lifecycle, verified
/// callbacks, pricing and the product tour.
class WorkforceMoreScreen extends StatelessWidget {
  const WorkforceMoreScreen({super.key});

  static const _callbacks = <Map<String, Object>>[
    {
      'title': 'M-Pesa STK Prompt',
      'path': 'checkout · push payment',
      'status': 'VERIFIED',
      'txn': 'TAM202608141181682087',
      'http': '200',
    },
    {
      'title': 'Pay to M-Pesa Till',
      'path': 'checkout · till',
      'status': 'VERIFIED',
      'txn': 'TAM202608144850275747',
      'http': '200',
    },
    {
      'title': 'Pay to M-Pesa Paybill',
      'path': 'checkout · paybill',
      'status': 'VERIFIED',
      'txn': 'TAM202608146269208749',
      'http': '200',
    },
  ];

  static const _rails = [
    ('M-Pesa', 'ACTIVE', 'STK prompt · till · paybill',
        AppColors.success, Icons.swap_vert_rounded),
    ('SasaPay Checkout', 'ACTIVE', 'OAuth + checkout link + webhook',
        AppColors.sasapay, Icons.link_rounded),
    ('Africa\u2019s Talking', 'ACTIVE', 'SMS · USSD · Airtime rewards',
        AppColors.africasTalking, Icons.sms_rounded),
    ('Avalanche', 'ACTIVE', 'Immutable badge attestations',
        AppColors.avalanche, Icons.workspace_premium_rounded),
  ];

  static const _tiers = [
    ('Starter', 'KES 1,500/mo', 'Up to 50 members · SMS · one rail'),
    ('Growth', 'KES 3,500–5,000/mo', 'Up to 200 members · all rails · API'),
    ('Business', 'Custom', 'Unlimited · on-prem proof · onboarding'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.deep, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 96,
                    child:
                        Image.asset(AppAssets.logoFull, fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'TapVerify Workforce',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'OBLIGATION  ·  PAYMENT  ·  PROOF',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Every collection is a trackable obligation. Every payment carries proof you can audit in real time.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (WorkforceService.activePlan != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.success.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded,
                    color: AppColors.success, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${WorkforceService.activePlan!.name} plan active — ${WorkforceService.activePlan!.price}. Raise collections anytime.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PaymentLinksScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.sasapay.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.sasapay.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.link_rounded,
                      color: AppColors.sasapay, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TAPVERIFY PAY',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.sasapay,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Universal payment links — anyone can pay, both sides earn a verified streak.',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.text, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CollectionSettingsScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold.withOpacity(0.45)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: AppColors.gold, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COLLECTION DETAILS',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.gold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Your Till, Paybill, bank & SasaPay details — members pay into these, you never touch the money.',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.text, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'PAYMENT RAILS',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.muted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (int i = 0; i < _rails.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _rails[i].$4.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_rails[i].$5,
                        color: _rails[i].$4, size: 20),
                  ),
                  title: Text(
                    _rails[i].$1,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  subtitle: Text(
                    _rails[i].$3,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.muted),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _rails[i].$4.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      _rails[i].$2,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: _rails[i].$4,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'LIFECYCLE · 9 STATES',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.muted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (final st in WfPaymentState.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Icon(st.icon, size: 17, color: st.color),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 92,
                        child: Text(
                          st.label,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: st.color,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          st.desc,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'VERIFIED CALLBACKS',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.muted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDFA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              for (final s in _callbacks) ...[
                _callbackTile(s),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'PRICING',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.muted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        for (final t in _tiers) ...[
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PricingScreen()),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: WorkforceService.activePlan?.name == t.$1
                        ? AppColors.success
                        : AppColors.border,
                    width: WorkforceService.activePlan?.name == t.$1 ? 1.6 : 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.$1,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.$3,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        t.$2,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: WorkforceService.activePlan?.name == t.$1
                              ? AppColors.success.withOpacity(0.12)
                              : AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          WorkforceService.activePlan?.name == t.$1
                              ? 'ACTIVE'
                              : 'PAY & GO',
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: WorkforceService.activePlan?.name == t.$1
                                ? AppColors.success
                                : AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.handshake_rounded, color: AppColors.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Trust infrastructure for chamas, SACCOs and individuals — a verified financial reputation that follows every member.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WorkforceLoginScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _callbackTile(Map<String, Object> s) {
    final status = s['status']! as String;
    final ok = status == 'VERIFIED';
    final color = ok ? AppColors.primary : AppColors.danger;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_rounded, color: color, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  s['title']! as String,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: AppColors.text),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${s['path']}  ·  ref ${s['txn']}  ·  HTTP ${s['http']}',
            style: GoogleFonts.inter(
                fontSize: 10.5, color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}