import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import '../constants.dart';

class RevenueReportScreen extends StatelessWidget {
  const RevenueReportScreen({super.key});

  static const _months = [
    ('Mar', 'March 2026', 320000, 12),
    ('Apr', 'April 2026', 380000, 14),
    ('May', 'May 2026', 420000, 16),
    ('Jun', 'June 2026', 480000, 18),
    ('Jul', 'July 2026', 530000, 22),
    ('Aug', 'August 2026', 270000, 8),
  ];

  @override
  Widget build(BuildContext context) {
    final total = _months.fold<int>(0, (s, m) => s + m.$3);
    final totalTxns = _months.fold<int>(0, (s, m) => s + m.$4);
    final avg = total ~/ _months.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Revenue Report',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(total, totalTxns, avg),
            const SizedBox(height: 24),
            Text('MONTHLY BREAKDOWN',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.muted,
                    letterSpacing: 0.6)),
            const SizedBox(height: 12),
            _buildBarChart(),
            const SizedBox(height: 20),
            _buildTrendBox(avg),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _shareReport(total, totalTxns, avg),
                icon: const Icon(Icons.share_rounded, size: 20),
                label: Text('Share as PDF',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int total, int totalTxns, int avg) {
    return Container(
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
          Text('Total Verified Revenue',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 4),
          Text('Ksh ${_fmt(total)}',
              style: GoogleFonts.inter(
                  fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 14),
          Row(
            children: [
              _pill('$totalTxns transactions'),
              const SizedBox(width: 8),
              _pill('6 months'),
              const SizedBox(width: 8),
              _pill('Avg Ksh ${_fmt(avg)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      height: 260,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 600000,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIdx, rod, rodIdx) {
                final month = _months[group.x.toInt()].$2;
                final value = _fmt(rod.toY.toInt());
                return BarTooltipItem(
                  '$month\nKsh $value',
                  GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _months.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_months[idx].$1,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.muted)),
                  );
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox();
                  final label = value >= 1000 ? '${(value ~/ 1000)}k' : '${value.toInt()}';
                  return Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.muted));
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 100000,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.border,
              strokeWidth: 0.8,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(_months.length, (i) {
            final rev = _months[i].$3;
            final isMax = rev == _months.map((m) => m.$3).reduce((a, b) => a > b ? a : b);
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: rev.toDouble(),
                  width: 32,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  gradient: LinearGradient(
                    colors: isMax
                        ? [AppColors.deep, AppColors.success]
                        : [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTrendBox(int avg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up_rounded, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Revenue Trend: UP',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success)),
                Text('Average monthly: Ksh ${_fmt(avg)}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }

  void _shareReport(int total, int totalTxns, int avg) {
    final report = '''REVENUE REPORT — Peter's Metal Works
Period: March 2026 — August 2026
Total Verified Revenue: Ksh ${_fmt(total)}
Total Transactions: $totalTxns
Average Monthly: Ksh ${_fmt(avg)}
Consistency Score: 94%
Payment Rail: SasaPay (OAuth2 + HMAC-SHA512 verified)
Generated by TapVerify — Revenue Proof System''';

    Share.share(report);
  }

  static String _fmt(int n) {
    return n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }
}
