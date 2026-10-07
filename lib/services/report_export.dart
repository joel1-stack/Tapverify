import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models.dart';
import '../utils/format.dart';

/// The file formats a collection can be exported to from the Live List, so a
/// secretary can print it or hand it over as a document people already use.
enum ReportFormat { pdf, word, excel, csv }

extension ReportFormatInfo on ReportFormat {
  String get label => switch (this) {
        ReportFormat.pdf => 'PDF',
        ReportFormat.word => 'Word',
        ReportFormat.excel => 'Excel',
        ReportFormat.csv => 'CSV',
      };

  String get ext => switch (this) {
        ReportFormat.pdf => 'pdf',
        ReportFormat.word => 'doc',
        ReportFormat.excel => 'xlsx',
        ReportFormat.csv => 'csv',
      };

  String get mime => switch (this) {
        ReportFormat.pdf => 'application/pdf',
        ReportFormat.word => 'application/msword',
        ReportFormat.excel =>
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ReportFormat.csv => 'text/csv',
      };

  String get hint => switch (this) {
        ReportFormat.pdf => 'Best for printing and sharing',
        ReportFormat.word => 'Open and edit in Word or Google Docs',
        ReportFormat.excel => 'Open in Excel or Google Sheets',
        ReportFormat.csv => 'Raw data for any spreadsheet',
      };
}

/// URL-safe title used as the shared file name, e.g. `tapverify-monthly-savings.pdf`.
String reportSlug(CollectionDetail detail) {
  final slug = detail.summary.title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'collection-${detail.summary.id}' : slug;
}

Future<List<int>> buildReport(CollectionDetail detail, ReportFormat format) {
  switch (format) {
    case ReportFormat.pdf:
      return _buildPdf(detail);
    case ReportFormat.word:
      return Future.value(_buildWord(detail));
    case ReportFormat.excel:
      return Future.value(_buildExcel(detail));
    case ReportFormat.csv:
      return Future.value(_buildCsv(detail));
  }
}

// â”€â”€ Shared layout â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

const List<String> _columns = [
  'Name',
  'Phone',
  'Status',
  'Paid (KES)',
  'Paid on',
  'Method',
];

List<String> _rowFor(Member m) => [
      m.displayName,
      m.phone,
      _statusLabel(m),
      m.paidAmount == null ? '-' : Format.kes(m.paidAmount),
      _paidOn(m.paidAt),
      _methodLabel(m),
    ];

String _methodLabel(Member m) {
  final method = m.paidMethod;
  if (method == null || method.isEmpty) return '-';
  return method;
}

String _statusLabel(Member m) => switch (m.status) {
      'paid' => 'Paid',
      'partial' => 'Partial',
      'pending' => 'Not paid',
      '' => 'Not paid',
      final other => other[0].toUpperCase() + other.substring(1),
    };

String _paidOn(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  return Format.dueDate(parsed);
}

String _generatedAt() =>
    DateFormat('d MMM yyyy, h:mm a').format(DateTime.now());

List<String> _summaryLines(CollectionDetail detail) {
  final s = detail.summary;
  return [
    '${Format.kes(s.amount)} per person  |  ${s.payoutLabel}',
    'Paid: ${s.paidCount} / ${s.memberCount}   '
        'Collected: ${Format.kes(s.collected)}   '
        'Outstanding: ${Format.kes(s.outstanding < 0 ? 0 : s.outstanding)}',
    'Due: ${_paidOn(s.dueDate)}',
  ];
}

String _esc(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

// â”€â”€ PDF â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

Future<List<int>> _buildPdf(CollectionDetail detail) async {
  final doc = pw.Document();
  final s = detail.summary;
  final green = PdfColor.fromHex('#00A86B');
  final paleGreen = PdfColor.fromHex('#F3FAF6');
  final ink = PdfColor.fromHex('#1A1A1A');
  final rows = detail.members.map(_rowFor).toList();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ),
      build: (ctx) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 34,
              height: 34,
              color: green,
              alignment: pw.Alignment.center,
              child: pw.Text(
                'T',
                style: pw.TextStyle(
                  fontSize: 19,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TapVerify',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: green,
                  ),
                ),
                pw.Text(
                  'Proof of Payment',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 22),
        pw.Text(
          s.title,
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
            color: ink,
          ),
        ),
        pw.SizedBox(height: 6),
        for (final line in _summaryLines(detail)) ...[
          pw.Text(line,
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
        ],
        pw.SizedBox(height: 6),
        pw.Text(
          'Generated by TapVerify  ${_generatedAt()}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
        ),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: _columns,
          data: rows,
          headerCellDecoration: pw.BoxDecoration(color: green),
          headerStyle: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          cellStyle: pw.TextStyle(fontSize: 10, color: ink),
          oddRowDecoration: pw.BoxDecoration(color: paleGreen),
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          cellPadding: const pw.EdgeInsets.all(6),
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(2.4),
            2: pw.FlexColumnWidth(1.6),
            3: pw.FlexColumnWidth(1.8),
            4: pw.FlexColumnWidth(1.8),
            5: pw.FlexColumnWidth(1.6),
          },
        ),
      ],
    ),
  );
  return doc.save();
}

// â”€â”€ Word (.doc written as HTML, which Word, WPS and Google Docs open) â”€â”€â”€â”€â”€

List<int> _buildWord(CollectionDetail detail) {
  final s = detail.summary;
  final buffer = StringBuffer()
    ..writeln('<!DOCTYPE html>')
    ..writeln('<html><head><meta charset="utf-8">')
    ..writeln('<title>${_esc(s.title)} - TapVerify</title>')
    ..writeln('<style>'
        'body { font-family: Calibri, Arial, sans-serif; color: #1A1A1A; }'
        'h1 { color: #00A86B; font-size: 22pt; margin-bottom: 2pt; }'
        '.brand { color: #00A86B; font-size: 13pt; font-weight: bold; }'
        '.muted { color: #6B7280; font-size: 10pt; }'
        '.summary { margin-top: 8pt; font-size: 11pt; }'
        'table { border-collapse: collapse; width: 100%; margin-top: 14pt; }'
        'th { background: #00A86B; color: #FFFFFF; border: 1px solid #00A86B;'
        ' padding: 6pt 8pt; text-align: left; font-size: 10.5pt; }'
        'td { border: 1px solid #E5E7EB; padding: 6pt 8pt; font-size: 10.5pt; }'
        'tr:nth-child(even) td { background: #F3FAF6; }'
        '</style></head><body>')
    ..writeln('<div class="brand">TapVerify &ndash; Proof of Payment</div>')
    ..writeln('<h1>${_esc(s.title)}</h1>')
    ..writeln('<div class="summary">');
  for (final line in _summaryLines(detail)) {
    buffer.writeln('<div>${_esc(line)}</div>');
  }
  buffer
    ..writeln('</div>')
    ..writeln('<div class="muted">Generated by TapVerify &nbsp; ${_generatedAt()}</div>')
    ..writeln('<table><thead><tr>');
  for (final col in _columns) {
    buffer.writeln('<th>${_esc(col)}</th>');
  }
  buffer.writeln('</tr></thead><tbody>');
  for (final m in detail.members) {
    buffer.writeln('<tr>');
    for (final cell in _rowFor(m)) {
      buffer.writeln('<td>${_esc(cell)}</td>');
    }
    buffer.writeln('</tr>');
  }
  buffer.writeln('</tbody></table></body></html>');
  return utf8.encode('\uFEFF${buffer.toString()}');
}

// â”€â”€ Excel (.xlsx) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

const _greenHex = '#00A86B';

List<int> _buildExcel(CollectionDetail detail) {
  final excel = Excel.createExcel();
  final sheet = excel['TapVerify'];
  excel.delete('Sheet1');

  final headerStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString(_greenHex),
    fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    bold: true,
    fontSize: 11,
  );
  final zebraStyle =
      CellStyle(backgroundColorHex: ExcelColor.fromHexString('#F3FAF6'));
  final titleStyle = CellStyle(
    fontColorHex: ExcelColor.fromHexString(_greenHex),
    bold: true,
    fontSize: 14,
  );
  final mutedStyle =
      CellStyle(fontColorHex: ExcelColor.fromHexString('#6B7280'));

  void appendStyled(List<CellValue?> cells, CellStyle? style) {
    // Address the row the append will land on (appendRow writes at maxRows).
    final row = sheet.maxRows;
    sheet.appendRow(cells);
    // Only overwrite the style when we actually have one: assigning null
    // wipes the auto-applied default (and its number format) and Excel.encode
    // then throws on numeric cells.
    if (style != null) {
      for (var col = 0; col < cells.length; col++) {
        if (cells[col] == null) continue;
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
            .cellStyle = style;
      }
    }
  }

  appendStyled([TextCellValue('TapVerify - ${detail.summary.title}')],
      titleStyle);
  for (final line in _summaryLines(detail)) {
    appendStyled([TextCellValue(line)], mutedStyle);
  }
  appendStyled(
      [for (final col in _columns) TextCellValue(col)], headerStyle);

  final members = detail.members;
  for (var i = 0; i < members.length; i++) {
    final m = members[i];
    final paid = m.paidAmount;
    appendStyled(
      [
        TextCellValue(m.displayName),
        TextCellValue(m.phone),
        TextCellValue(_statusLabel(m)),
        paid == null ? TextCellValue('-') : DoubleCellValue(paid),
        TextCellValue(_paidOn(m.paidAt)),
        TextCellValue(_methodLabel(m)),
      ],
      i.isOdd ? zebraStyle : null,
    );
  }

  sheet.setColumnWidth(0, 26);
  sheet.setColumnWidth(1, 16);
  sheet.setColumnWidth(2, 12);
  sheet.setColumnWidth(3, 14);
  sheet.setColumnWidth(4, 16);
  sheet.setColumnWidth(5, 14);

  final bytes = excel.encode();
  if (bytes == null) {
    throw StateError('Could not build the Excel file');
  }
  return bytes;
}

// â”€â”€ CSV â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

String _csvCell(String value) =>
    '"${value.replaceAll('"', '""')}"';

List<int> _buildCsv(CollectionDetail detail) {
  final buffer = StringBuffer('name,phone,status,paid_amount,paid_at,paid_method\n');
  for (final m in detail.members) {
    buffer.writeln([
      _csvCell(m.displayName),
      _csvCell(m.phone),
      _csvCell(_statusLabel(m)),
      m.paidAmount == null ? '' : m.paidAmount.toString(),
      _csvCell(m.paidAt ?? ''),
      _csvCell(m.paidMethod ?? ''),
    ].join(','));
  }
  return utf8.encode(buffer.toString());
}
