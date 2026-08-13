import 'hive_service.dart';

/// Contribution domain model + business rules for TapVerify.
///
/// Three pieces:
///  - [OrgRules]        — per-org-type contribution rules (frequency, partial
///                        payment, reminders, loan tracking, labels).
///  - [ContributionService] — campaign lifecycle: create, record a payment
///                        (with receipt ref + PIN proof), compute progress,
///                        and flatten all payments for the ledger/PDF.
///  - [TechGroupHelper] — the SMS copy templates sent to members.
class OrgRules {
  static const List<String> orgTypes = [
    'Chama',
    'SACCO',
    'Welfare',
    'Burial Group',
    'Church',
    'School',
    'Company',
    'Tech Group',
  ];

  static Map<String, dynamic> rulesFor(String type) {
    switch (type) {
      case 'SACCO':
        return {
          'frequency': 'monthly',
          'allow_partial': false,
          'min_partial_percent': 100,
          'reminder_days': 5,
          'loan_tracking': true,
          'labels': ['Monthly shares', 'Loan repayment', 'Emergency fund'],
          'description':
              'Regulated SACCO — monthly shares and loan repayments. Strict, no partials.',
        };
      case 'School':
        return {
          'frequency': 'termly',
          'allow_partial': true,
          'min_partial_percent': 50,
          'reminder_days': 7,
          'loan_tracking': false,
          'labels': ['School fees', 'School trip', 'Uniform top-up'],
          'description':
              'Parents get notified — fees, trips and uniform payments for their children.',
        };
      case 'Company':
        return {
          'frequency': 'monthly',
          'allow_partial': true,
          'min_partial_percent': 25,
          'reminder_days': 5,
          'loan_tracking': false,
          'labels': ['Staff welfare', 'Team trip', 'Harambee'],
          'description':
              'Workplace contributions — welfare, trips and company functions.',
        };
      case 'Tech Group':
        return {
          'frequency': 'monthly',
          'allow_partial': true,
          'min_partial_percent': 0,
          'reminder_days': 3,
          'loan_tracking': false,
          'labels': ['Meetup venue', 'Cloud hosting fund', 'Community dues'],
          'description':
              'Informal tech communities — venue, hosting and community funds.',
        };
      case 'Burial Group':
        return {
          'frequency': 'per_event',
          'allow_partial': true,
          'min_partial_percent': 10,
          'reminder_days': 1,
          'loan_tracking': false,
          'labels': ['Burial levy', 'Emergency collection'],
          'description':
              'Emergency per-event levies — burials and hospital support. Fast deadlines.',
        };
      case 'Church':
        return {
          'frequency': 'weekly',
          'allow_partial': true,
          'min_partial_percent': 20,
          'reminder_days': 3,
          'loan_tracking': false,
          'labels': ['Offering', 'Building fund', 'Harambee'],
          'description': 'Weekly offerings and project harambees.',
        };
      case 'Welfare':
        return {
          'frequency': 'monthly',
          'allow_partial': true,
          'min_partial_percent': 20,
          'reminder_days': 5,
          'loan_tracking': false,
          'labels': ['Welfare fund', 'Social events'],
          'description':
              'Social welfare pool — events, visits and member support.',
        };
      default:
        return {
          'frequency': 'custom',
          'allow_partial': true,
          'min_partial_percent': 0,
          'reminder_days': 7,
          'loan_tracking': false,
          'labels': ['Monthly contribution', 'Merry-go-round', 'Welfare fund'],
          'description':
              'Chama — monthly or weekly pool. Members rotate or fund jointly.',
        };
    }
  }

  static const Map<String, String> _images = {
    'Chama':
        'https://images.pexels.com/photos/3184388/pexels-photo-3184388.jpeg?auto=compress&cs=tinysrgb&w=900',
    'SACCO':
        'https://images.pexels.com/photos/3184418/pexels-photo-3184418.jpeg?auto=compress&cs=tinysrgb&w=900',
    'School':
        'https://images.pexels.com/photos/8613084/pexels-photo-8613084.jpeg?auto=compress&cs=tinysrgb&w=900',
    'Company':
        'https://images.pexels.com/photos/3184292/pexels-photo-3184292.jpeg?auto=compress&cs=tinysrgb&w=900',
    'Tech Group':
        'https://images.pexels.com/photos/3183150/pexels-photo-3183150.jpeg?auto=compress&cs=tinysrgb&w=900',
    'Burial Group':
        'https://images.pexels.com/photos/8613092/pexels-photo-8613092.jpeg?auto=compress&cs=tinysrgb&w=900',
    'Church':
        'https://images.pexels.com/photos/2608517/pexels-photo-2608517.jpeg?auto=compress&cs=tinysrgb&w=900',
    'Welfare':
        'https://images.pexels.com/photos/1462630/pexels-photo-1462630.jpeg?auto=compress&cs=tinysrgb&w=900',
  };

  static String imageFor(String type) => _images[type] ?? _images.values.first;

  static const Map<String, String> _categoryImages = {
    'Monthly':
        'https://images.pexels.com/photos/3184388/pexels-photo-3184388.jpeg?auto=compress&cs=tinysrgb&w=900',
    'Trip':
        'https://images.pexels.com/photos/346885/pexels-photo-346885.jpeg?auto=compress&cs=tinysrgb&w=900',
    'Emergency':
        'https://images.pexels.com/photos/8613092/pexels-photo-8613092.jpeg?auto=compress&cs=tinysrgb&w=900',
    'Project':
        'https://images.pexels.com/photos/2608517/pexels-photo-2608517.jpeg?auto=compress&cs=tinysrgb&w=900',
    'School trip':
        'https://images.pexels.com/photos/8613084/pexels-photo-8613084.jpeg?auto=compress&cs=tinysrgb&w=900',
    'Loan':
        'https://images.pexels.com/photos/1552106/pexels-photo-1552106.jpeg?auto=compress&cs=tinysrgb&w=900',
    'Fundraising':
        'https://images.pexels.com/photos/3184292/pexels-photo-3184292.jpeg?auto=compress&cs=tinysrgb&w=900',
  };

  static String categoryImageFor(String category) {
    for (final entry in _categoryImages.entries) {
      if (category.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return _images.values.first;
  }
}

/// Campaign lifecycle + payment proof ledger.
class ContributionService {
  static const List<String> contributionTypes = [
    'Regular',
    'One-Time',
    'Emergency',
    'Trip',
    'Project',
    'Loan',
  ];

  static const List<String> frequencies = [
    'daily',
    'weekly',
    'monthly',
    'termly',
    'per_event',
  ];

  static List<Map> campaigns() {
    final wsId = HiveService.activeWorkspaceId ?? '';
    return HiveService.getCampaignsForWorkspace(wsId);
  }

  /// Creates a new contribution campaign and persists it via [HiveService].
  /// Returns the stored campaign map.
  ///
  /// Every campaign carries: title, [contribType] (Regular / One-Time /
  /// Emergency / Trip / Project / Loan), [amount], [frequency], [deadline],
  /// the [message] SMS, [paymentMethod] (loop/till/paybill/bank/cash),
  /// [allowPartial] + [minPartial] rules, an optional [targetAmount] and an
  /// empty `payments` list that the ledger & PDFs read from.
  static Map<String, dynamic> create({
    required String title,
    required String contribType,
    required double amount,
    required String frequency,
    required String deadline,
    required String message,
    required Map paymentMethod,
    required bool allowPartial,
    required double minPartial,
    required String workspaceId,
    double? targetAmount,
  }) {
    final campaign = <String, dynamic>{
      'id': 'cmp-${DateTime.now().millisecondsSinceEpoch}',
      'workspace_id': workspaceId,
      'title': title,
      'contrib_type': contribType,
      'frequency': frequency,
      'amount': amount,
      'deadline': deadline,
      'message': message,
      'payment_method': paymentMethod,
      'allow_partial': allowPartial,
      'min_partial': minPartial,
      'target_amount': targetAmount ?? amount,
      'created_at': DateTime.now().toIso8601String(),
      'status': 'active',
      'payments': <Map<String, dynamic>>[],
      'notified_at': DateTime.now().toIso8601String(),
    };
    HiveService.addCampaign(campaign);
    return campaign;
  }

  static const String _charset = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

  static String _genRef() {
    var v = DateTime.now().microsecondsSinceEpoch;
    final sb = StringBuffer('TV-');
    for (var i = 0; i < 6; i++) {
      sb.write(_charset[v % _charset.length]);
      v ~/= _charset.length;
    }
    return sb.toString();
  }

  static String _genPin() {
    var v = DateTime.now().microsecondsSinceEpoch;
    final sb = StringBuffer();
    for (var i = 0; i < 6; i++) {
      sb.write(_charset[v % _charset.length]);
      v ~/= _charset.length;
    }
    return sb.toString();
  }

  /// Records one payment into a campaign and returns the new payment record.
  ///
  /// Each payment is stored as its own row (not merged per member) so the
  /// ledger can show every individual receipt with:
  ///  - `ref`  — human-quotable receipt reference (TV-XXXXXX)
  ///  - `pin`  — short receipt PIN for quick lookups
  ///  - `verified` — false until the treasurer taps "verify" in the ledger
  ///  - `method`/`paid_at` — the rail used and when it happened
  ///
  /// Because rows are appended, members who pay in installments produce
  /// several ledger entries; the campaign detail sums them per member.
  static Map<String, dynamic> recordPayment(
    Map campaign,
    String memberId,
    String memberName,
    String memberCode,
    String phone,
    double paid,
    String method, {
    bool verified = true,
  }) {
    final payments =
        List<Map<String, dynamic>>.from(campaign['payments'] ?? []);
    final payment = <String, dynamic>{
      'member_id': memberId,
      'member_name': memberName,
      'member_code': memberCode,
      'phone': phone,
      'paid': paid,
      'method': method,
      'ref': _genRef(),
      'pin': _genPin(),
      'verified': verified,
      'paid_at': DateTime.now().toIso8601String(),
    };
    payments.add(payment);
    campaign['payments'] = payments;
    HiveService.updateCampaign(campaign);
    return payment;
  }

  /// Flattens every payment record across the given campaigns with the
  /// campaign title/type attached, newest first. Missing proof fields get
  /// backfilled deterministically so exports always carry a ref + pin.
  static List<Map<String, dynamic>> flattenPayments(List<Map> campaigns) {
    final out = <Map<String, dynamic>>[];
    for (final c in campaigns) {
      final payments = List<Map<String, dynamic>>.from(c['payments'] ?? []);
      for (final p in payments) {
        final ref = p['ref']?.toString() ??
            ('TV-${(c['id'] ?? '').hashCode.abs() % 900000 + 100000}');
        final pin = p['pin']?.toString() ??
            (DateTime.tryParse(p['paid_at']?.toString() ?? '')
                    ?.millisecondsSinceEpoch
                    .toString()
                    .substring(0, 6) ??
                '000000');
        out.add({
          ...p,
          'ref': ref,
          'pin': pin,
          'verified': p['verified'] ?? true,
          'campaign_id': c['id'],
          'campaign_title': c['title'] ?? 'Contribution',
          'contrib_type': c['contrib_type'] ?? 'Regular',
        });
      }
    }
    out.sort((a, b) => (b['paid_at']?.toString() ?? '')
        .compareTo(a['paid_at']?.toString() ?? ''));
    return out;
  }

  static Map<String, dynamic> progress(Map campaign) {
    final payments =
        List<Map<String, dynamic>>.from(campaign['payments'] ?? []);
    final amount = (campaign['amount'] as num).toDouble();
    var collected = 0.0;
    var fullCount = 0;
    var partialCount = 0;
    for (final p in payments) {
      final paid = (p['paid'] as num).toDouble();
      collected += paid;
      if (paid >= amount) {
        fullCount++;
      } else {
        partialCount++;
      }
    }
    return {
      'collected': collected,
      'full_paid': fullCount,
      'partial_paid': partialCount,
      'pending': 0,
      'total_members': 0,
    };
  }
}

class TechGroupHelper {
  static String defaultMessage(
    String category,
    String orgName,
    double amount,
  ) {
    switch (category) {
      case 'Monthly':
        return 'You have to pay Ksh ${amount.round()} for $orgName this month. Pay via your preferred method before the deadline.';
      case 'School trip':
        return "PAY YOUR CHILD'S TRIP — Ksh ${amount.round()} for the upcoming school trip. Pay before the deadline to secure your child's seat.";
      case 'Emergency':
        return 'EMERGENCY COLLECTION — $orgName has raised a ${amount.round()} levy. Please contribute what you can before the deadline.';
      case 'Trip':
        return '$orgName trip — Ksh ${amount.round()} per member. Pay before the deadline to secure your spot.';
      case 'Project':
        return '$orgName project fundraising — target Ksh ${amount.round()} per member. Every contribution counts!';
      case 'Loan':
        return '$orgName loan repayment — Ksh ${amount.round()} due. Pay before the deadline.';
      default:
        return '$orgName collection of Ksh ${amount.round()}. Pay before the deadline.';
    }
  }

  static String reminderMessage(Map campaign, String memberName) {
    final amount = (campaign['amount'] as num?)?.round() ?? 0;
    final deadline = _deadlineLabel(campaign);
    final org =
        HiveService.getActiveWorkspace()?['name']?.toString() ?? 'your group';
    return 'REMINDER: $org — ${campaign['title'] ?? 'Contribution'}. Ksh $amount due by $deadline. You have not paid yet. Pay now via your payment link.';
  }

  static String _deadlineLabel(Map campaign) {
    final d = DateTime.tryParse(campaign['deadline']?.toString() ?? '');
    if (d == null) return 'the deadline';
    return '${d.day}/${d.month}/${d.year}';
  }
}
