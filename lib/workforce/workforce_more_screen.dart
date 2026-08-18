import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_models.dart';
import 'workforce_login_screen.dart';
import 'web_demo_screen.dart';

/// Workforce More — the evidence console: product contract, rail status (LOOP
/// already proven live), pricing and the web-demo launch point.
class WorkforceMoreScreen extends StatelessWidget {
  const WorkforceMoreScreen({super.key});

  static const _snapshots = <Map<String, Object>>[
    {
      'title': 'LOOP M-Pesa Prompt',
      'path': 'POST mpesa-prompt/2.0/services/process-request',
      'status': 'COMPLETED',
      'txn': 'TAM202608141181682087',
      'http': '200',
    },
    {
      'title': 'Pay to M-Pesa Till',
      'path': 'POST pay-to-mpesa-till/1.0/services/process-request',
      'status': 'COMPLETED',
      'txn': 'TAM202608144850275747',
      'http': '200',
    },
    {
      'title': 'Pay to M-Pesa Paybill',
      'path': 'POST pay-to-paybill/1.0/services/process-request',
      'status': 'COMPLETED',
      'txn': 'TAM202608146269208749',
      'http': '200',
    },
  ];

  static const _rails = [
    ('LOOP', 'LIVE · proven on sandbox', '4 of 4 products COMPLETED',
        AppColors.loop, Icons.bolt_rounded),
    ('SasaPay', 'READY · keys pending', 'OAuth + Checkout link + webhook',
        AppColors.sasapay, Icons.link_rounded),
    ('Africa\u2019s Talking', 'READY · keys pending', 'SMS / USSD / Airtime',
        AppColors.africasTalking, Icons.sms_rounded),
    ('Avalanche', 'PLANNED', 'Optional proof attestation for badges',
        AppColors.avalanche, Icons.workspace_premium_rounded),
  ];

  static const _tiers = [
    ('Starter', 'KES 1,500/mo', 'Up to 50 workers · SMS · one rail'),
    ('Growth', 'KES 3,500–5,000/mo', 'Up to 200 workers · all rails · API'),
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
                'Every collection is a trackable obligation. Every payment carries proof the foreman can audit in real time.',
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

        // Web demo launch
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WebDemoScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.play_circle_fill_rounded,
                      color: AppColors.accent, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WEB DEMO — what this app serves',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Auto-plays the factory story end-to-end: raise, notify, pay, prove.',
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
          'LIVE LOOP PROOF · REAL RESPONSES',
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
            color: const Color(0xFFFFF3E8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              for (final s in _snapshots) ...[
                _snapshotTile(s),
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
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
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
                Text(
                  t.$2,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
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
              const Icon(Icons.emoji_events_rounded, color: AppColors.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Africa\u2019s Talking Hackathon Aug 27 · Avalanche Mini Hack Aug 28–30',
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
            label: const Text('Back to role selection'),
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

  Widget _snapshotTile(Map<String, Object> s) {
    final status = s['status']! as String;
    final ok = status == 'COMPLETED';
    final color = ok ? AppColors.accent : AppColors.danger;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: color, size: 15),
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
            '${s['path']}  ·  transferOrderId ${s['txn']}  ·  HTTP ${s['http']}',
            style: GoogleFonts.inter(
                fontSize: 10.5, color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
