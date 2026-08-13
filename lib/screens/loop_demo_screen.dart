import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../models/member.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart';
import 'success_screen.dart';

/// Animated LOOP rail demo: shows the request-to-pay journey step by step.
///
/// Walks Request to Pay → M-Pesa prompt → PIN → IPN confirm → receipt, with a
/// mocked phone UI. On completion hands off to [SuccessScreen] with the
/// verification result from [ApiService.verifyMember].
class LoopDemoScreen extends StatefulWidget {
  final Member member;
  final double amount;
  final String eventType;

  const LoopDemoScreen({
    super.key,
    required this.member,
    required this.amount,
    this.eventType = 'payment_loop',
  });

  @override
  State<LoopDemoScreen> createState() => _LoopDemoScreenState();
}

class _LoopDemoScreenState extends State<LoopDemoScreen> {
  int _step = 0;
  bool _loading = false;
  Timer? _timer;

  static const _steps = [
    'Sending Request to Pay via LOOP...',
    'Member sees M-Pesa prompt on their phone',
    'Member enters M-Pesa PIN',
    'LOOP confirms payment (IPN)',
    'SMS receipt sent to member',
  ];

  @override
  void initState() {
    super.initState();
    _advance();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _advance() {
    if (_step < _steps.length - 1) {
      _timer = Timer(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => _step++);
        _advance();
      });
    } else {
      _timer = Timer(const Duration(milliseconds: 1400), _confirmPayment);
    }
  }

  Future<void> _confirmPayment() async {
    setState(() => _loading = true);
    final wsId = HiveService.activeWorkspaceId ?? '';
    try {
      final result = await ApiService.verifyMember(
        workspaceId: wsId,
        memberId: widget.member.id,
        amount: widget.amount,
        eventType: widget.eventType,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => SuccessScreen(
              memberName: widget.member.name,
              memberPhone: widget.member.phone,
              amount: widget.amount,
              receiptUrl: result['receipt']?['url'] ?? '',
              pin: result['receipt']?['pin'] ?? '',
              queued: result['queued'] == true,
              smsSent: result['sms']?['status'] == 'sent',
            ),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgName =
        HiveService.getActiveWorkspace()?['name']?.toString() ?? 'your group';
    final till = HiveService.getActiveWorkspace()?['till_number']?.toString() ??
        '9415678';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text('LOOP Payment (NCBA)',
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17)),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: AppColors.text,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Phone mockup showing the M-Pesa style prompt
              _PhoneMockup(
                  member: widget.member,
                  amount: widget.amount,
                  org: orgName,
                  till: till),
              const SizedBox(height: 36),
              // Live status tracker
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(_steps.length, (i) {
                    final done = i < _step;
                    final active = i == _step;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Icon(
                            done
                                ? Icons.check_circle_rounded
                                : active
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                            size: 18,
                            color: done
                                ? AppColors.primary
                                : active
                                    ? const Color(0xFFC9A227)
                                    : const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _steps[i],
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight:
                                    active ? FontWeight.w700 : FontWeight.w500,
                                color: done || active
                                    ? AppColors.text
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'LIVE LOOP DEMO · sandbox.looponline.co.ke',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.muted,
                ),
              ),
              const Spacer(),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneMockup extends StatefulWidget {
  final Member member;
  final double amount;
  final String org;
  final String till;

  const _PhoneMockup({
    required this.member,
    required this.amount,
    required this.org,
    required this.till,
  });

  @override
  State<_PhoneMockup> createState() => _PhoneMockupState();
}

class _PhoneMockupState extends State<_PhoneMockup>
    with SingleTickerProviderStateMixin {
  late AnimationController _shake;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _offset =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, 0.004)).animate(
      CurvedAnimation(parent: _shake, curve: Curves.easeInOut),
    );
    _shake.repeat(reverse: true);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offset,
      child: Container(
        width: 230,
        height: 380,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.grey.shade300, width: 3),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 12)),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('12:06',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B))),
                    const Spacer(),
                    const Icon(Icons.signal_cellular_alt,
                        size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    const Icon(Icons.wifi, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    const Icon(Icons.battery_full,
                        size: 13, color: Color(0xFF64748B)),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A651),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'M-PESA',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Request to Pay',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.org,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ksh ${widget.amount.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == 0
                            ? const Color(0xFF00A651)
                            : const Color(0xFFCBD5E1),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter M-PESA PIN',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A651),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'CANCEL',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFFE2E8F0), width: 3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
