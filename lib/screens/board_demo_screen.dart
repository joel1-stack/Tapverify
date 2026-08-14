import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../services/hive_service.dart';
import '../widgets/loop_value_strip.dart';
import 'member_list_screen.dart';

/// Animated demo of the board/treasurer journey — creating an organization and
/// taking it through KYC, mirroring the member-payment demo style:
/// create org (type your name live) -> registered -> KYC review -> APPROVED or
/// REJECTED (resubmit) -> collections live. "Start collecting" actually writes
/// the organization into Hive and opens the real member roster, so the demo
/// drops you straight into the product.
class BoardDemoScreen extends StatefulWidget {
  const BoardDemoScreen({super.key});

  @override
  State<BoardDemoScreen> createState() => _BoardDemoScreenState();
}

class _BoardDemoScreenState extends State<BoardDemoScreen> {
  final _orgCtrl = TextEditingController();
  String _type = 'Burial Welfare';
  double _contribution = 5000;
  Timer? _timer;

  /// form -> registered -> pending -> approved / rejected
  String _phase = 'form';
  bool _saving = false;

  static const _types = [
    'Burial Welfare',
    'Chama',
    'SACCO',
    'Church',
    'School',
    'Welfare',
  ];

  static const _timeline = [
    'Treasurer creates the organization',
    'Organization registered · KYC docs attached',
    'KYC review in progress',
    'KYC approved / rejected',
    'Collections live — receipts + ledger',
  ];

  @override
  void dispose() {
    _timer?.cancel();
    _orgCtrl.dispose();
    super.dispose();
  }

  String get _orgName {
    final v = _orgCtrl.text.trim();
    return v.isEmpty ? 'My New Chama' : v;
  }

  String get _orgId {
    return 'TV-ORG-${_orgName.hashCode.abs() % 100000}';
  }

  void _afterCreate() {
    setState(() => _phase = 'registered');
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _phase = 'pending');
    });
  }

  void _approve() {
    setState(() => _phase = 'approved');
  }

  void _reject() {
    setState(() => _phase = 'rejected');
  }

  void _resubmit() {
    setState(() => _phase = 'pending');
  }

  Future<void> _startCollecting() async {
    setState(() => _saving = true);
    final id = 'demo-org-${DateTime.now().millisecondsSinceEpoch % 1000000}';
    await HiveService.addWorkspace({
      'id': id,
      'name': _orgName,
      'type': _type,
      'contribution': _contribution.round(),
      'rails': {'loop': true, 'till': true, 'paybill': true, 'bank': false},
      'till_number': '9415678',
      'paybill_number': '522033',
      'account_number': '',
      'kyc_status': 'verified',
      'created_at': DateTime.now().toIso8601String(),
      'image': 'assets/images/icon_adaptive_foreground.png',
    });
    await HiveService.grantWorkspaceAccess(id, role: 'treasurer');
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MemberListScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Treasurer & KYC Demo',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _TreasurerPhone(
                      phase: _phase,
                      orgName: _orgName,
                      orgType: _type,
                      contribution: _contribution,
                      orgId: _orgId,
                      onType: (t) => setState(() => _type = t),
                      onContribution: (v) =>
                          setState(() => _contribution = v),
                      onResubmit: _resubmit,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(_timeline.length, (i) {
                          final approved = _phase == 'approved';
                          final rejected = _phase == 'rejected';
                          final done = approved
                              ? true
                              : rejected
                                  ? i < 3
                                  : _timelineIndexDone(i);
                          final active = !approved &&
                              !rejected &&
                              _timelineIndexActive(i);
                          final redActive =
                              rejected && i == 3;
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
                                      : redActive
                                          ? AppColors.danger
                                          : active
                                              ? const Color(0xFFC9A227)
                                              : const Color(0xFFCBD5E1),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _timeline[i],
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: active || redActive
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: done || active || redActive
                                          ? AppColors.text
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                                if (redActive)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Icon(Icons.close_rounded,
                                        color: AppColors.danger, size: 16),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.accent.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded,
                              color: AppColors.accent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _note(),
                              style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const LoopValueStrip(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _cta(),
          ],
        ),
      ),
    );
  }

  bool _timelineIndexDone(int i) {
    // during form/registered/pending, everything before the pending step is done
    switch (_phase) {
      case 'form':
        return false;
      case 'registered':
        return i < 1;
      case 'pending':
        return i < 2;
      default:
        return false;
    }
  }

  bool _timelineIndexActive(int i) {
    switch (_phase) {
      case 'form':
        return i == 0;
      case 'registered':
        return i == 1;
      case 'pending':
        return i == 2;
      default:
        return false;
    }
  }

  String _note() {
    switch (_phase) {
      case 'form':
        return 'Every Kenyan group starts the same way — a funeral that needs Ksh 400,000 in 72 hours, or a chama that wants to grow. This is how the board onboards the group and passes KYC so collections go live with proof.';
      case 'registered':
        return 'Organization registered as $_orgName ($_orgId). Registration docs are attached to the KYC record automatically.';
      case 'pending':
        return 'KYC is in the admin review queue — collections stay locked until approved. Decide below what the admin sees next.';
      case 'rejected':
        return 'The admin flagged the registration documents. The treasurer gets a clear reason, resubmits, and the review starts again.';
      case 'approved':
        return 'KYC approved — $_orgName is verified and collections are LIVE. A funeral group that tracks every shilling becomes a SACCO that can offer loans. Start collecting to drop into the real member roster.';
      default:
        return '';
    }
  }

  Widget _cta() {
    if (_saving) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    switch (_phase) {
      case 'form':
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _orgCtrl.text.trim().isEmpty ? null : _afterCreate,
            icon: const Icon(Icons.add_business_rounded),
            label: Text('CREATE ORGANIZATION',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        );
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger, width: 1.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _reject,
                  icon: const Icon(Icons.close_rounded),
                  label: Text('REJECT',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _approve,
                  icon: const Icon(Icons.verified_rounded),
                  label: Text('APPROVE KYC',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
            ),
          ],
        );
      case 'rejected':
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _resubmit,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text('RESUBMIT DOCUMENTS',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        );
      case 'approved':
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _startCollecting,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text('START COLLECTING → REAL APP',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _TreasurerPhone extends StatelessWidget {
  final String phase;
  final String orgName;
  final String orgType;
  final double contribution;
  final String orgId;
  final ValueChanged<String> onType;
  final ValueChanged<double> onContribution;
  final VoidCallback onResubmit;

  const _TreasurerPhone({
    required this.phase,
    required this.orgName,
    required this.orgType,
    required this.contribution,
    required this.orgId,
    required this.onType,
    required this.onContribution,
    required this.onResubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 470,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(36),
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
        borderRadius: BorderRadius.circular(26),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Container(
                color: const Color(0xFF0F172A),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Text('10:12',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const Spacer(),
                    const Icon(Icons.signal_cellular_alt,
                        size: 12, color: Colors.white),
                    const SizedBox(width: 3),
                    const Icon(Icons.wifi, size: 12, color: Colors.white),
                    const SizedBox(width: 3),
                    const Icon(Icons.battery_full,
                        size: 12, color: Colors.white),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: _bodyBg(),
                  padding: const EdgeInsets.all(14),
                  child: _body(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _bodyBg() {
    switch (phase) {
      case 'approved':
        return const Color(0xFFF0FDF4);
      case 'rejected':
        return const Color(0xFFFEF2F2);
      case 'pending':
        return const Color(0xFFFFFBEB);
      default:
        return const Color(0xFFFAF9F6);
    }
  }

  Widget _body() {
    switch (phase) {
      case 'registered':
        return _registered();
      case 'pending':
        return _pending();
      case 'rejected':
        return _rejected();
      case 'approved':
        return _approved();
      default:
        return _form();
    }
  }

  Widget _statusChip(IconData icon, String label, Color color) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ],
        ),
      ),
    );
  }

  Widget _header(String title, String subtitle, Color color) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(color == AppColors.danger
              ? Icons.cancel_rounded
              : color == const Color(0xFFF59E0B)
                  ? Icons.hourglass_top_rounded
                  : Icons.verified_rounded, color: color, size: 24),
        ),
        const SizedBox(height: 10),
        Text(title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.text)),
        const SizedBox(height: 4),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B))),
      ],
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.deep,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.account_balance_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Text('TapVerify · Treasurer',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A))),
          ],
        ),
        const SizedBox(height: 12),
        Text('Create organization',
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A))),
        const SizedBox(height: 2),
        Text('Verify the group, then collections go live.',
            style: GoogleFonts.inter(
                fontSize: 9.5, color: const Color(0xFF64748B))),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.badge_rounded, size: 13, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(orgName.isEmpty ? 'Organization name' : orgName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: orgName.isEmpty
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF0F172A))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text('Group type',
            style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155))),
        const SizedBox(height: 6),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: _BoardDemoScreenState._types.map((t) {
            final selected = t == orgType;
            return GestureDetector(
              onTap: () => onType(t),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(t,
                    style: GoogleFonts.inter(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF334155))),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Text('Monthly contribution',
            style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155))),
        const SizedBox(height: 2),
        Text('Ksh ${contribution.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primary)),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: const Color(0xFFE2E8F0),
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.1),
          ),
          child: Slider(
            value: contribution,
            min: 500,
            max: 20000,
            divisions: 39,
            onChanged: onContribution,
          ),
        ),
        const Spacer(),
        Text('Registration docs auto-attached on create.',
            style: GoogleFonts.inter(
                fontSize: 8.5, color: const Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _registered() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        _statusChip(Icons.task_alt_rounded, 'REGISTERED', AppColors.primary),
        const SizedBox(height: 14),
        _header('$orgName is registered',
            'Organization ID $orgId\nRegistration docs attached.', AppColors.primary),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEDD5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.description_rounded,
                  size: 13, color: AppColors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                    'Certificate of registration · KRA PIN · Contact person — attached',
                    style: GoogleFonts.inter(
                        fontSize: 8, color: const Color(0xFF9A3412))),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pending() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        _statusChip(Icons.hourglass_top_rounded, 'KYC REVIEW', const Color(0xFFF59E0B)),
        const SizedBox(height: 14),
        _header('Review in progress',
            '$orgName docs are with the\nadmin queue — usually under 1 business day.', const Color(0xFFF59E0B)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_rounded, size: 13, color: Color(0xFFB45309)),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Collections locked until KYC is approved.',
                    style: GoogleFonts.inter(
                        fontSize: 8, color: const Color(0xFF92400E))),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rejected() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        _statusChip(Icons.cancel_rounded, 'KYC REJECTED', AppColors.danger),
        const SizedBox(height: 14),
        _header('Documents rejected',
            'Reason: registration certificate is blurry.\nResubmit a clear copy to restart review.', AppColors.danger),
        const SizedBox(height: 12),
        Center(
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9)),
              ),
              onPressed: onResubmit,
              icon: const Icon(Icons.upload_file_rounded, size: 14),
              label: Text('RESUBMIT DOCS',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800, fontSize: 9)),
            ),
          ),
        ),
        const Spacer(),
        Text('The treasurer always sees the exact reason.',
            style: GoogleFonts.inter(
                fontSize: 8, color: const Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _approved() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        _statusChip(Icons.verified_rounded, 'KYC APPROVED', AppColors.primary),
        const SizedBox(height: 14),
        _header('$orgName is verified',
            'Collections are LIVE.\nAdd members, run a contribution, collect via LOOP.', AppColors.primary),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEDD5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 13, color: AppColors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                    'Rails enabled: LOOP · M-Pesa Till · Paybill — receipts for every payment.',
                    style: GoogleFonts.inter(
                        fontSize: 8, color: const Color(0xFF9A3412))),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
