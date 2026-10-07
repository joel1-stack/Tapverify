import 'dart:io';

import 'package:tapverify/models.dart';
import 'package:tapverify/services/report_export.dart';

Future<void> main() async {
  final detail = CollectionDetail.fromJson({
    'id': 7,
    'title': 'Monthly Savings',
    'amount': 500,
    'payout_method': 'till',
    'member_count': 4,
    'paid_count': 2,
    'collected': 1000,
    'outstanding': 1000,
    'due_date': '2026-10-31',
    'payout_details': {'till_number': '567890'},
    'members': [
      {
        'id': 1,
        'name': 'Mary Wanjiku',
        'phone': '0712345678',
        'status': 'paid',
        'paid_at': '2026-10-02T10:00:00Z',
        'paid_method': 'mpesa',
        'paid_amount': 500,
        'amount_mismatch': false,
        'reminders_sent': 1,
      },
      {
        'id': 2,
        'name': 'John "JJ" Otieno',
        'phone': '0790330067',
        'status': 'pending',
        'amount_mismatch': false,
        'reminders_sent': 0,
      },
      {
        'id': 3,
        'name': 'Amina Hassan',
        'phone': '0711222333',
        'status': 'partial',
        'paid_at': '2026-10-05T15:30:00Z',
        'paid_method': 'mpesa',
        'paid_amount': 250,
        'amount_mismatch': false,
        'reminders_sent': 0,
      },
      {
        'id': 4,
        'phone': '0700111222',
        'status': 'pending',
        'amount_mismatch': false,
        'reminders_sent': 2,
      },
    ],
    'notify': {'sent': 4, 'failed': []},
  });

  final dir = Directory.systemTemp.createTempSync('tv-report-');
  for (final format in ReportFormat.values) {
    final bytes = await buildReport(detail, format);
    final file = File(
        '${dir.path}/tapverify-${reportSlug(detail)}.${format.ext}');
    await file.writeAsBytes(bytes, flush: true);
    final head = bytes.take(8).map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(' ');
    stdout.writeln(
        '${format.label.padRight(4)} ${bytes.length.toString().padLeft(7)} bytes  magic=$head  ${file.path}');
  }
}
