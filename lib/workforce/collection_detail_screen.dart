import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../constants.dart';
import '../workforce/workforce_models.dart';
import '../workforce/workforce_service.dart';

/// Order Detail — payment link, share, status, customer list.
class CollectionDetailScreen extends StatefulWidget {
  const CollectionDetailScreen({required this.collection});
  final WfCollection collection;
  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  WfCollection get c => widget.collection;

  String get _paymentLink =>
      'https://pay.sasapay.app/checkout/${c.id}?amount=${c.amount.round()}&ref=${c.id}';

  @override
  Widget build(BuildContext context) {
    final total = c.tasks.length;
    final paid = c.paidCount;
    final pct = total == 0 ? 0.0 : (paid / total) * 100;
    final daysLeft = c.due.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text(c.title,
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            onPressed: _shareLink,
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share payment link',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Summary card ──
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(c.type.toUpperCase(),
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ),
                          const Spacer(),
                          Text(
                            daysLeft <= 0 ? 'Due today' : '$daysLeft days left',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withOpacity(0.85)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text('Ksh ${_fmt(c.collected)} collected',
                          style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                          'of Ksh ${_fmt(c.amount * total)} expected · ${pct.toStringAsFixed(0)}% · ${c.railName}',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8))),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.primaryLight),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Payment link ──
                Text('PAYMENT LINK',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.muted,
                        letterSpacing: 0.6)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(_paymentLink,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              decoration: TextDecoration.underline)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: _paymentLink));
                                _snack('Link copied to clipboard');
                              },
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              label: Text('Copy',
                                  style: GoogleFonts.inter(
                                      fontSize: 12, fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _shareLink,
                              icon: const Icon(Icons.share_rounded, size: 16),
                              label: Text('WhatsApp',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Customer list ──
                Row(
                  children: [
                    Text('CUSTOMERS · $total',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.muted,
                            letterSpacing: 0.6)),
                    const Spacer(),
                    Text('$paid paid',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success)),
                  ],
                ),
                const SizedBox(height: 10),
                for (final t in c.tasks.values) ...[
                  _customerRow(t),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),

          // ── Bottom actions ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _simulatePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.bolt_rounded, size: 18, color: Colors.white),
                  label: Text('Simulate payment',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerRow(WfPaymentTask t) {
    final paid = t.state.index >= WfPaymentState.completed.index;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: paid ? AppColors.success : AppColors.muted.withOpacity(0.2),
            child: Icon(
              paid ? Icons.check_rounded : Icons.person_rounded,
              size: 16,
              color: paid ? Colors.white : AppColors.muted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer ${t.workerId}',
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                if (paid && t.txnRef.isNotEmpty)
                  Text(t.txnRef,
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (paid ? AppColors.success : AppColors.warning).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              paid ? 'PAID' : 'PENDING',
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: paid ? AppColors.success : AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  void _simulatePayment() {
    for (final t in c.tasks.values) {
      if (t.state.index < WfPaymentState.completed.index) {
        WorkforceService.payNow(c, t.workerId);
        WorkforceService.verify(c, t.workerId);
        break;
      }
    }
    setState(() {});
    _snack('Payment verified!');
  }

  void _shareLink() {
    Share.share(_paymentLink);
  }

  void _shareSummary() {
    Share.share('Check out my revenue proof from Peter\'s Metal Works\nKsh 2,400,000 verified\n94% consistency\nhttps://tverify.co.ke/r/${c.id}');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter()),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  static String _fmt(num n) {
    final s = n.toStringAsFixed(n == n.roundToDouble() ? 0 : 2);
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }
}
