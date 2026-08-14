import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'pdf_share.dart' as pdf_share;

/// PDF generation + share/print for TapVerify reports.
///
/// Produces three kinds of printable documents, all laid out for A4:
///  - [buildPdf] / [share] / [printPdf]          — PAID members per campaign,
///    with receipt refs + PINs, served to members who claim "I paid".
///  - [buildOutstandingPdf]/[shareOutstanding]/[printOutstanding] — UNPAID
///    member list for a campaign, handed to the treasurer for follow-up.
///  - [buildRegisterPdf]/[shareRegister]/[printRegister] — the FULL Activity
///    register: every contribution with its type badge, collected/target and
///    a per-member PAID/PARTIAL/NOT PAID table. Print this from the Activity
///    tab for meetings.
///
/// Uses the universal `pdf`/`printing` packages so the same bytes render in
/// the system print preview or share as an attachment.
class PaymentReportService {
  static String _fmt(num n) {
    final s = n.toStringAsFixed(n == n.roundToDouble() ? 0 : 2);
    return s.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  /// Builds the PAID members PDF: green header, summary card (payments count,
  /// total collected, verified count) and a per-row table with member, phone,
  /// amount, rail, receipt ref and PAID/PENDING status.
  static Future<Uint8List> buildPdf({
    required String orgName,
    required String reportTitle,
    required List<Map<String, dynamic>> payments,
  }) async {
    final collected =
        payments.fold<double>(0, (s, p) => s + (p['paid'] as num));
    final verified = payments.where((p) => p['verified'] == true).length;

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('TapVerify',
                      style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.orange800)),
                  pw.Text('Proof of payment for Kenya\'s groups',
                      style:
                          pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
              pw.Text(
                DateTime.now().toString().substring(0, 10),
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(reportTitle,
              style:
                  pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Paid members report · $orgName',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.orange50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(payments.length.toString(),
                        style: pw.TextStyle(
                            fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.Text('PAYMENTS',
                        style: pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Ksh ${_fmt(collected)}',
                        style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.orange800)),
                    pw.Text('TOTAL COLLECTED',
                        style: pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('$verified / ${payments.length}',
                        style: pw.TextStyle(
                            fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.Text('VERIFIED',
                        style: pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: [
              '#',
              'MEMBER',
              'CODE',
              'PHONE',
              'AMOUNT (Ksh)',
              'RAIL / METHOD',
              'REF',
              'STATUS',
            ],
            data: List.generate(payments.length, (i) {
              final p = payments[i];
              return [
                '${i + 1}',
                p['member_name'] ?? '—',
                p['member_code'] ?? '—',
                (p['phone'] ?? '—').toString().replaceFirst('254', '0'),
                _fmt((p['paid'] as num?)?.toDouble() ?? 0),
                (p['method'] ?? '—')
                    .toString()
                    .replaceFirst('M-PESA ', 'M-PESA\n')
                    .replaceFirst('Paybill', 'Paybill\n')
                    .replaceFirst('LOOP', 'LOOP\n'),
                p['ref']?.toString() ?? '—',
                (p['verified'] == true && p['verified'] != null)
                    ? 'PAID ✓'
                    : 'PENDING',
              ];
            }),
            cellStyle: pw.TextStyle(fontSize: 8),
            headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: PdfColors.orange800),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerLeft,
              6: pw.Alignment.centerLeft,
              7: pw.Alignment.center,
            },
            columnWidths: {
              2: const pw.FlexColumnWidth(0.6),
              6: const pw.FlexColumnWidth(0.9),
            },
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Generated by TapVerify — every row carries a receipt ref that the member can quote. '
            'Members dispute a payment? Tap the row in the app ledger and re-verify against the rail SMS.',
            style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
          ),
        ],
      ),
    );
    return doc.save();
  }

  /// Writes the paid report to the app documents dir and returns the path.
  static Future<String> savePdf({
    required String orgName,
    required String reportTitle,
    required List<Map<String, dynamic>> payments,
  }) async {
    final bytes = await buildPdf(
      orgName: orgName,
      reportTitle: reportTitle,
      payments: payments,
    );
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final filename =
        'tapverify_${reportTitle.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}_$stamp';
    return pdf_share.savePdfToFile(bytes, filename);
  }

  static Future<void> share({
    required String orgName,
    required String reportTitle,
    required List<Map<String, dynamic>> payments,
  }) async {
    final bytes = await buildPdf(
      orgName: orgName,
      reportTitle: reportTitle,
      payments: payments,
    );
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final filename =
        'tapverify_${reportTitle.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}_$stamp';
    await pdf_share.sharePdfFile(
      bytes,
      filename,
      'Paid members report — $reportTitle',
      'Paid members report for $reportTitle ($orgName). Generated by TapVerify.',
    );
  }

  static Future<bool> printPdf({
    required String orgName,
    required String reportTitle,
    required List<Map<String, dynamic>> payments,
  }) async {
    final bytes = await buildPdf(
      orgName: orgName,
      reportTitle: reportTitle,
      payments: payments,
    );
    return Printing.layoutPdf(
      name: 'Paid members report — $reportTitle',
      onLayout: (_) => Future.value(bytes),
    );
  }

  // ---- Outstanding / not-yet-paid report (the "who hasn't paid" list) ----

  /// Builds the UNPAID members PDF (red theme) for treasurer follow-up:
  /// count summary, "ACTION REQUIRED" banner and a member table with amount due.
  static Future<Uint8List> buildOutstandingPdf({
    required String orgName,
    required String reportTitle,
    required List<Map<String, dynamic>> members,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('TapVerify',
                      style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red800)),
                  pw.Text('Proof of payment for Kenya\'s groups',
                      style:
                          pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
              pw.Text(
                DateTime.now().toString().substring(0, 10),
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(reportTitle,
              style:
                  pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('UNPAID members report · $orgName',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.red50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(members.length.toString(),
                        style: pw.TextStyle(
                            fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.Text('MEMBERS NOT PAID',
                        style: pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('ACTION REQUIRED',
                        style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red800)),
                    pw.Text('Send reminder + follow up',
                        style: pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: [
              '#',
              'MEMBER',
              'CODE',
              'PHONE',
              'AMOUNT DUE (Ksh)',
              'STATUS'
            ],
            data: List.generate(members.length, (i) {
              final m = members[i];
              return [
                '${i + 1}',
                m['name'] ?? '—',
                m['member_code'] ?? '—',
                (m['phone'] ?? '—').toString().replaceFirst('254', '0'),
                _fmt((m['due'] as num?)?.toDouble() ?? 0),
                'UNPAID',
              ];
            }),
            cellStyle: pw.TextStyle(fontSize: 8),
            headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: PdfColors.red800),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.center,
            },
            columnWidths: {
              2: const pw.FlexColumnWidth(0.6),
            },
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Generated by TapVerify — list of members who still owe this contribution. Hand it to the treasurer for follow-up.',
            style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
          ),
        ],
      ),
    );
    return doc.save();
  }

  static Future<String> saveOutstandingPdf({
    required String orgName,
    required String reportTitle,
    required List<Map<String, dynamic>> members,
  }) async {
    final bytes = await buildOutstandingPdf(
      orgName: orgName,
      reportTitle: reportTitle,
      members: members,
    );
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final filename =
        'tapverify_unpaid_${reportTitle.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}_$stamp';
    return pdf_share.savePdfToFile(bytes, filename);
  }

  static Future<void> shareOutstanding({
    required String orgName,
    required String reportTitle,
    required List<Map<String, dynamic>> members,
  }) async {
    final bytes = await buildOutstandingPdf(
      orgName: orgName,
      reportTitle: reportTitle,
      members: members,
    );
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final filename =
        'tapverify_unpaid_${reportTitle.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}_$stamp';
    await pdf_share.sharePdfFile(
      bytes,
      filename,
      'Unpaid members — $reportTitle',
      'Members who have not paid for $reportTitle ($orgName). Generated by TapVerify.',
    );
  }

  static Future<bool> printOutstanding({
    required String orgName,
    required String reportTitle,
    required List<Map<String, dynamic>> members,
  }) async {
    final bytes = await buildOutstandingPdf(
      orgName: orgName,
      reportTitle: reportTitle,
      members: members,
    );
    return Printing.layoutPdf(
      name: 'Unpaid members — $reportTitle',
      onLayout: (_) => Future.value(bytes),
    );
  }

  // ---- Full Activity Register (printable "contributions book") ----
  //
  // Renders every contribution in the org as a section with its type, target,
  // collected amount, paid/partial/unpaid counts and a per-member status table.
  // Loans get a distinct "LOAN / REPAYMENT" header so a treasurer can hand the
  // register to a meeting. This is what Activity tab prints.

  /// Builds the full Activity register PDF: cover banner with org name + type,
  /// summary strip (total collected / not-yet-paid / report year) and one
  /// section per contribution — title, type badge, deadline/frequency/amount,
  /// collected-vs-target and a per-member PAID / BALANCE / STATUS table.
  /// Loan-type contributions render with a distinct amber "LOAN / REPAYMENT"
  /// badge. This is the document the Activity tab prints.
  static Future<Uint8List> buildRegisterPdf({
    required String orgName,
    required String orgType,
    required List<Map<String, dynamic>> contributions,
  }) async {
    final doc = pw.Document();

    // Totals across all contributions for the cover summary.
    var totalCollected = 0.0;
    var totalCampaigns = contributions.length;
    var totalUnpaid = 0;
    for (final c in contributions) {
      totalCollected += (c['collected'] as num?)?.toDouble() ?? 0;
      totalUnpaid += (c['unpaid_count'] as num?)?.toInt() ?? 0;
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TapVerify',
                    style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange800)),
                pw.Text(
                    'Generated ${DateTime.now().toString().substring(0, 10)}',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(height: 1, color: PdfColors.grey300),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
              'TapVerify · Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ),
        build: (context) => [
          // Cover: org identity
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [PdfColors.orange800, PdfColors.orange600],
              ),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(orgName,
                        style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white)),
                    pw.SizedBox(height: 2),
                    pw.Text('$orgType · Contributions & Repayments Register',
                        style: pw.TextStyle(
                            fontSize: 11, color: PdfColors.orange100)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('$totalCampaigns',
                        style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white)),
                    pw.Text('CONTRIBUTIONS',
                        style: pw.TextStyle(
                            fontSize: 9, color: PdfColors.orange100)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Summary strip
          pw.Row(
            children: [
              _summaryBox(PdfColors.orange700, 'TOTAL COLLECTED',
                  'Ksh ${_fmt(totalCollected)}'),
              pw.SizedBox(width: 10),
              _summaryBox(
                  PdfColors.red700, 'NOT YET PAID', '$totalUnpaid members'),
              pw.SizedBox(width: 10),
              _summaryBox(
                  PdfColors.blue700, 'REPORT', '${DateTime.now().year}'),
            ],
          ),
          pw.SizedBox(height: 20),

          // One section per contribution
          ...contributions.map((c) => _contributionSection(c)),
        ],
      ),
    );
    return doc.save();
  }

  static pw.Widget _summaryBox(PdfColor color, String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          border: pw.Border(left: pw.BorderSide(color: color, width: 4)),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: color)),
            pw.Text(label,
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _contributionSection(Map<String, dynamic> c) {
    final type = c['contrib_type']?.toString() ?? 'Regular';
    final isLoan = type.toLowerCase() == 'loan';
    final accent = isLoan ? PdfColors.amber800 : PdfColors.orange800;
    final collected = (c['collected'] as num?)?.toDouble() ?? 0;
    final target = (c['target'] as num?)?.toDouble() ?? 0;
    final members = (c['members'] as List?) ?? <Map<String, dynamic>>[];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            border: pw.Border(
                bottom: pw.BorderSide(color: accent, width: 2),
                left: pw.BorderSide(color: accent, width: 4)),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(c['title']?.toString() ?? 'Contribution',
                        style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey900)),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: accent,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      isLoan ? 'LOAN / REPAYMENT' : type.toUpperCase(),
                      style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${c['deadline']?.toString() ?? '—'} · ${c['frequency']?.toString() ?? ''} · Ksh ${_fmt((c['amount'] as num?)?.toDouble() ?? 0)}/member'
                '${isLoan ? ' · BORROWER ${c['borrower']?.toString() ?? ''}' : ''}',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                      'Collected: Ksh ${_fmt(collected)} of Ksh ${_fmt(target)}',
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: accent)),
                  pw.Text(
                    '${c['paid_count'] ?? 0} paid · ${c['partial_count'] ?? 0} partial · ${c['unpaid_count'] ?? 0} unpaid',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 6),
        if (members.isNotEmpty)
          pw.TableHelper.fromTextArray(
            headers: ['MEMBER', 'CODE', 'PHONE', 'PAID', 'BALANCE', 'STATUS'],
            data: members.map((m) {
              final paid = (m['paid'] as num?)?.toDouble() ?? 0;
              final due = (m['due'] as num?)?.toDouble() ?? 0;
              final status = m['status']?.toString() ?? 'NOT PAID';
              return [
                m['name'] ?? '—',
                m['member_code'] ?? '—',
                (m['phone'] ?? '—').toString().replaceFirst('254', '0'),
                paid > 0 ? 'Ksh ${_fmt(paid)}' : '—',
                due > 0 ? 'Ksh ${_fmt(due)}' : '—',
                status,
              ];
            }).toList(),
            cellStyle: pw.TextStyle(fontSize: 7.5),
            headerStyle: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: accent),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.center,
            },
            columnWidths: {
              1: const pw.FlexColumnWidth(0.6),
              5: const pw.FlexColumnWidth(0.9),
            },
          )
        else
          pw.Text('No members registered for this contribution yet.',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.SizedBox(height: 18),
      ],
    );
  }

  static Future<String> saveRegisterPdf({
    required String orgName,
    required String orgType,
    required List<Map<String, dynamic>> contributions,
  }) async {
    final bytes = await buildRegisterPdf(
      orgName: orgName,
      orgType: orgType,
      contributions: contributions,
    );
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final filename =
        'tapverify_register_${orgName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}_$stamp';
    return pdf_share.savePdfToFile(bytes, filename);
  }

  static Future<void> shareRegister({
    required String orgName,
    required String orgType,
    required List<Map<String, dynamic>> contributions,
  }) async {
    final bytes = await buildRegisterPdf(
      orgName: orgName,
      orgType: orgType,
      contributions: contributions,
    );
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final filename =
        'tapverify_register_${orgName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}_$stamp';
    await pdf_share.sharePdfFile(
      bytes,
      filename,
      'Activity register — $orgName',
      'Contributions & repayments register for $orgName. Generated by TapVerify.',
    );
  }

  static Future<bool> printRegister({
    required String orgName,
    required String orgType,
    required List<Map<String, dynamic>> contributions,
  }) async {
    final bytes = await buildRegisterPdf(
      orgName: orgName,
      orgType: orgType,
      contributions: contributions,
    );
    return Printing.layoutPdf(
      name: 'Activity register — $orgName',
      onLayout: (_) => Future.value(bytes),
    );
  }
}
