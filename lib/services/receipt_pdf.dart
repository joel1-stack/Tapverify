import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Everything a receipt shows, regardless of who collected.
class ReceiptData {
  const ReceiptData({
    required this.receiptNo,
    required this.timestamp,
    required this.collectorName,
    required this.collectorRole,
    required this.collectorOrg,
    required this.memberName,
    required this.obligation,
    required this.amount,
    required this.rail,
    required this.transferId,
    required this.state,
    this.termsNote = 'Collector has accepted the TapVerify terms.',
  });

  final String receiptNo;
  final String timestamp;
  final String collectorName;
  final String collectorRole;
  final String collectorOrg;
  final String memberName;
  final String obligation;
  final String amount;
  final String rail;
  final String transferId;
  final String state;
  final String termsNote;
}

const _teal = PdfColor.fromInt(0xFF0D9488);
const _deep = PdfColor.fromInt(0xFF0F766E);
const _accent = PdfColor.fromInt(0xFFE84142);
const _ink = PdfColor.fromInt(0xFF0F172A);
const _muted = PdfColor.fromInt(0xFF64748B);
const _success = PdfColor.fromInt(0xFF16A34A);
const _white = PdfColor.fromInt(0xFFFFFFFF);
const _border = PdfColor.fromInt(0xFFD3E6E4);
const _gold = PdfColor.fromInt(0xFFC9A227);

/// Builds the styled TapVerify payment receipt as PDF bytes.
Future<Uint8List> buildReceiptPdf(ReceiptData d) async {
  final doc = pw.Document();
  final logo = await _logoBytes();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      build: (_) => [
        pw.Container(
          color: const PdfColor.fromInt(0xFFF0FDFA),
          padding: const pw.EdgeInsets.all(28),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _header(logo, d),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    vertical: 10, horizontal: 18),
                decoration: pw.BoxDecoration(
                  color: _accent,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('✓', style: pw.TextStyle(color: _white, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'VERIFIED PAYMENT RECEIPT ·  ${d.state}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: pw.FontWeight.bold,
                        color: _white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: _white,
                  borderRadius: pw.BorderRadius.circular(14),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    _row('Receipt no.', d.receiptNo, bold: true),
                    _divider(),
                    _row('Paid on', d.timestamp),
                    _divider(),
                    _sectionTitle('COLLECTOR'),
                    _row('Collected by', d.collectorName),
                    _row('Position', d.collectorRole),
                    _row('Organization', d.collectorOrg),
                    _divider(),
                    _sectionTitle('PAYMENT'),
                    _row('Member / Payer', d.memberName),
                    _row('Obligation', d.obligation),
                    _row('Amount', d.amount, strong: true),
                    _row('Rail', d.rail),
                    _row('Transfer ID', d.transferId),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFE7F5F3),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PROOF',
                      style: pw.TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.2,
                        fontWeight: pw.FontWeight.bold,
                        color: _deep,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'This receipt is the shared proof between collector and payer. '
                      'In production the payment is anchored by a signed rail webhook and an '
                      'Avalanche badge attestation.',
                      style: const pw.TextStyle(
                          fontSize: 10, color: _muted, height: 1.5),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFFFF7E6),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ⓘ', style: pw.TextStyle(color: _gold, fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Text(
                        d.termsNote,
                        style: const pw.TextStyle(fontSize: 10, color: _ink),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: _border, height: 1),
              pw.SizedBox(height: 12),
              pw.Text(
                'TapVerify — verified receipts for chamas, SACCOs, churches, schools, factories and individuals.',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 9, color: _muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  return doc.save();
}

pw.Widget _header(pw.MemoryImage? logo, ReceiptData d) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      if (logo != null)
        pw.Container(
          width: 92,
          height: 44,
          alignment: pw.Alignment.center,
          child: pw.Image(logo, fit: pw.BoxFit.contain),
        ),
      pw.SizedBox(width: 12),
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'TapVerify',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: _deep,
              ),
            ),
            pw.Text(
              'PAYMENT RECEIPT',
              style: pw.TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: pw.FontWeight.bold,
                color: _teal,
              ),
            ),
          ],
        ),
      ),
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: _teal,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          'TAPVERIFY',
          style: pw.TextStyle(
            fontSize: 9,
            letterSpacing: 1,
            fontWeight: pw.FontWeight.bold,
            color: _white,
          ),
        ),
      ),
    ],
  );
}

pw.Widget _divider() => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Divider(color: _border, height: 1),
    );

pw.Widget _sectionTitle(String title) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 9,
          letterSpacing: 1.4,
          fontWeight: pw.FontWeight.bold,
          color: _teal,
        ),
      ),
    );

pw.Widget _row(String label, String value, {bool bold = false, bool strong = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            label,
            style: pw.TextStyle(
                fontSize: 10.5, color: _muted, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: strong ? 14 : 11,
              fontWeight: bold || strong ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: strong ? _success : _ink,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<pw.MemoryImage?> _logoBytes() async {
  try {
    final data = await rootBundle.load('assets/images/logo_transparent.png');
    return pw.MemoryImage(data.buffer.asUint8List());
  } catch (_) {
    return null;
  }
}

/// Opens the system share sheet with the receipt PDF (WhatsApp, email, drive…).
Future<void> shareReceiptPdf(ReceiptData d, {String? filename}) async {
  final bytes = await buildReceiptPdf(d);
  await Printing.sharePdf(
    bytes: bytes,
    filename: filename ?? 'TapVerify_receipt_${d.receiptNo}.pdf',
  );
}

/// Opens the print dialog.
Future<void> printReceiptPdf(ReceiptData d) async {
  final bytes = await buildReceiptPdf(d);
  await Printing.layoutPdf(onLayout: (_) => bytes);
}