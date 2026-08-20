import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_service.dart';
import 'notification_center.dart';

/// Pricing — pay & go. A collector activates a plan once; after that they can
/// log in any time, edit the description and raise the next collection. No
/// money moves here in the demo — activation is simulated until real APIs are
/// connected.
class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  static const _tiers = [
    (
      'Starter',
      'KES 1,500',
      '/mo',
      'Up to 50 members · SMS · one rail',
      Icons.rocket_launch_rounded,
      AppColors.primary
    ),
    (
      'Growth',
      'KES 3,500',
      '/mo',
      'Up to 200 members · all rails · API',
      Icons.auto_awesome_rounded,
      AppColors.accent
    ),
    (
      'Business',
      'Custom',
      '',
      'Unlimited · on-prem proof · onboarding',
      Icons.workspace_premium_rounded,
      AppColors.gold
    ),
  ];

  bool _paying = false;

  Future<void> _payAndGo(String name, String price, String cadence) async {
    setState(() => _paying = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _paying = false);
    WorkforceService.activatePlan(name, price);
    NotificationCenter.instance.notify(
      title: '${name.replaceAll('_', ' ')} plan active',
      body: '$price$cadence — pay & go. You can raise collections now.',
      icon: Icons.auto_awesome_rounded,
      color: AppColors.success,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name active — you can now raise collections.',
            style: GoogleFonts.inter()),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final plan = WorkforceService.activePlan;
    final user = WorkforceService.currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text(
          'Pricing',
          style: GoogleFonts.inter(
              fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text),
        ),
      ),
      body: ListView(
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
                Text(
                  'PAY & GO',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Activate once, collect for as long as you need. When a collection ends, log in, change the description and raise the next one.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (plan != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
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
                      '${plan.name} active · ${plan.price} · since ${plan.activatedAt.day}/${plan.activatedAt.month}',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          for (final t in _tiers)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: plan?.name == t.$1
                        ? t.$6
                        : AppColors.border,
                    width: plan?.name == t.$1 ? 1.6 : 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(t.$5, size: 20, color: t.$6),
                      const SizedBox(width: 10),
                      Text(
                        t.$1,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const Spacer(),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: t.$2,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: t.$6,
                              ),
                            ),
                            TextSpan(
                              text: t.$3,
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.$4,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: plan?.name == t.$1 || _paying
                          ? null
                          : () => _payAndGo(t.$1, t.$2, t.$3),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: t.$6),
                      icon: Icon(_paying
                          ? Icons.hourglass_top_rounded
                          : plan?.name == t.$1
                              ? Icons.check_rounded
                              : Icons.payments_rounded),
                      label: Text(
                        _paying
                            ? 'Processing…'
                            : plan?.name == t.$1
                                ? 'Active'
                                : 'Pay & go — ${t.$2}${t.$3}',
                      ),
                    ),
                  ),
                  if (t.$1 == 'Starter')
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Recommended for individuals & small groups',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.handshake_rounded, color: AppColors.gold),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    user != null
                        ? '${user.name} · ${user.position} — collecting as ${user.orgName}.'
                        : 'One subscription, unlimited collections. Pay once, collect forever.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}