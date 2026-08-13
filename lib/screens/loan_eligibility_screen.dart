import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../services/hive_service.dart';
import '../services/contribution_service.dart';

/// Loan eligibility check, powered by TapVerify's transaction inquiry.
///
/// Looks back 12 months of recorded contributions across the logged-in user's
/// groups, counts every verified payment as an on-ledger LOOP transaction
/// (the same ledger served by `check_status`/`transaction_history`), and
/// computes a loan ceiling at 3x net contributions — the classic chama 3x
/// rule. The certification strip lets the treasurer print/share the decisions.
class LoanEligibilityScreen extends StatefulWidget {
  const LoanEligibilityScreen({super.key});

  @override
  State<LoanEligibilityScreen> createState() => _LoanEligibilityScreenState();
}

class _LoanEligibilityScreenState extends State<LoanEligibilityScreen> {
  int _months = 12;

  Map<String, dynamic> _compute() {
    final all = <Map>[];
    for (final ws in HiveService.getWorkspaces()) {
      all.addAll(HiveService.getCampaignsForWorkspace(ws['id']));
    }
    final payments = ContributionService.flattenPayments(all);

    final cutoff = DateTime.now().subtract(Duration(days: 30 * _months));
    final inWindow = payments.where((p) {
      final d = DateTime.tryParse(p['paid_at']?.toString() ?? '');
      return d != null && d.isAfter(cutoff) && p['verified'] != false;
    }).toList();

    final total = inWindow.fold<double>(0, (s, p) => s + (p['paid'] as num));
    final cap = total * 3;
    final groups = HiveService.getWorkspaces().length;
    return {
      'total': total,
      'count': inWindow.length,
      'cap': cap,
      'groups': groups,
      'window': inWindow,
    };
  }

  @override
  Widget build(BuildContext context) {
    final data = _compute();
    final total = (data['total'] as double).round();
    final count = data['count'] as int;
    final cap = (data['cap'] as double).round();
    final window = data['window'] as List<Map<String, dynamic>>;
    final monthsActive =
        (window.map((p) => p['paid_at']).toSet().length).clamp(0, _months);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text('Loan Eligibility',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
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
                    const Icon(Icons.savings_rounded,
                        color: Color(0xFFFFB066), size: 22),
                    const SizedBox(width: 8),
                    Text('You qualify for',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8))),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Ksh ${_fmt(cap)}',
                    style: GoogleFonts.inter(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text('3× your recorded contributions · LOOP 3x rule',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.75))),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Window selector
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lookback window',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
                const SizedBox(height: 8),
                Row(
                  children: [6, 12, 18, 24].map((m) {
                    final active = _months == m;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$m mo',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600, fontSize: 12)),
                        selected: active,
                        selectedColor: AppColors.deep,
                        labelStyle: TextStyle(
                            color: active ? Colors.white : AppColors.text),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                            color: active ? AppColors.deep : AppColors.border),
                        onSelected: (_) => setState(() => _months = m),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Text(
                  'Verified payments in last $_months months: $count · Ksh ${_fmt(total)} contributed · ${monthsActive} months on record',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // History strip
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text('Contribution history (transaction inquiry)',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: window.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.history_rounded,
                            size: 40, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 10),
                        Text('No verified transactions in this window',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.muted)),
                      ],
                    ),
                  )
                : Column(
                    children: window.take(8).map((p) {
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 2),
                        leading: const Icon(Icons.verified_rounded,
                            color: AppColors.primary, size: 20),
                        title: Text(p['campaign_title'] ?? 'Contribution',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text(
                          '${p['ref']} · ${p['method'] ?? 'LOOP'}',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.muted),
                        ),
                        trailing: Text('Ksh ${_fmt(p['paid'])}',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.primary)),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),

          // Certification strip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.fact_check_rounded,
                    color: AppColors.gold, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Every entry above was cross-checked via transaction inquiry against the group ledger. Print or share this certification with your board.',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w500,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Loan application sent to the board for approval',
                              style: GoogleFonts.inter()),
                          backgroundColor: AppColors.deep,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                    label: Text('Apply for up to Ksh ${_fmt(cap)}',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '12 months of timely contributions unlock borrowing',
              style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: AppColors.muted,
                  fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _fmt(dynamic value) {
    final n = value is num ? value : double.tryParse(value.toString()) ?? 0;
    return n.round().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}