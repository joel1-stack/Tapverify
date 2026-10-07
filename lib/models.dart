class CollectionSummary {
  CollectionSummary({
    required this.id,
    required this.title,
    required this.amount,
    required this.payoutMethod,
    required this.memberCount,
    required this.paidCount,
    required this.collected,
    required this.outstanding,
    this.description = '',
    this.dueDate,
    this.autoDetect = false,
    this.payoutDetails = const {},
  });

  factory CollectionSummary.fromJson(Map<String, dynamic> j) => CollectionSummary(
        id: j['id'] as int,
        title: j['title'] as String,
        amount: double.parse(j['amount'].toString()),
        payoutMethod: j['payout_method'] as String,
        memberCount: j['member_count'] as int,
        paidCount: j['paid_count'] as int,
        collected: double.parse(j['collected'].toString()),
        outstanding: double.parse(j['outstanding'].toString()),
        description: (j['description'] as String?) ?? '',
        dueDate: j['due_date'] as String?,
        autoDetect: j['auto_detect'] as bool? ?? false,
        payoutDetails: (j['payout_details'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
            ) ??
            const {},
      );

  final int id;
  final String title;
  final double amount;
  final String payoutMethod;
  final int memberCount;
  final int paidCount;
  final double collected;
  final double outstanding;

  /// Optional line the treasurer wrote, shown on the payment link page.
  final String description;
  final String? dueDate;

  /// True when the API will match Till/Paybill payments on its own.
  final bool autoDetect;

  /// till_number, or paybill_number + paybill_account, or personal_phone, or
  /// bank_details, depending on [payoutMethod].
  final Map<String, String> payoutDetails;

  bool get completed => memberCount > 0 && paidCount == memberCount;

  /// Short human label for where the money goes, e.g. "Till 567890".
  String get payoutLabel {
    switch (payoutMethod) {
      case 'till':
        final till = payoutDetails['till_number'] ?? '';
        return till.isEmpty ? 'Till' : 'Till $till';
      case 'paybill':
        final paybill = payoutDetails['paybill_number'] ?? '';
        final account = payoutDetails['paybill_account'] ?? '';
        if (paybill.isEmpty) return 'Paybill';
        return account.isEmpty ? 'Paybill $paybill' : 'Paybill $paybill, $account';
      case 'personal':
        final phone = payoutDetails['personal_phone'] ?? '';
        return phone.isEmpty ? 'Personal number' : 'Personal $phone';
      case 'bank':
        final bank = payoutDetails['bank_details'] ?? '';
        return bank.isEmpty ? 'Bank account' : bank;
      default:
        return payoutMethod;
    }
  }
}

class Member {
  Member({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    required this.amountMismatch,
    required this.remindersSent,
    this.paidAt,
    this.paidMethod,
    this.paidAmount,
    this.transactionRef,
    this.payLink,
    this.claimStatus,
    this.claimCode,
    this.claimAmount,
    this.claimNote,
  });

  factory Member.fromJson(Map<String, dynamic> j) => Member(
        id: j['id'] as int,
        name: (j['name'] as String?) ?? '',
        phone: j['phone'] as String,
        status: j['status'] as String,
        paidAt: j['paid_at'] as String?,
        paidMethod: j['paid_method'] as String?,
        paidAmount: j['paid_amount'] == null
            ? null
            : double.parse(j['paid_amount'].toString()),
        amountMismatch: j['amount_mismatch'] as bool? ?? false,
        transactionRef: j['transaction_ref'] as String?,
        remindersSent: j['reminders_sent'] as int? ?? 0,
        payLink: j['pay_link'] as String?,
        claimStatus: j['claim_status'] as String?,
        claimCode: j['claim_code'] as String?,
        claimAmount: j['claim_amount'] == null
            ? null
            : double.parse(j['claim_amount'].toString()),
        claimNote: j['claim_note'] as String?,
      );

  final int id;
  final String name;
  final String phone;
  final String status;
  final String? paidAt;
  final String? paidMethod;
  final double? paidAmount;
  final bool amountMismatch;
  final String? transactionRef;
  final int remindersSent;
  final String? payLink;

  /// What this member reported from the payment link page, waiting on the
  /// treasurer: 'claimed', 'partial', 'cancelled' or 'issue'.
  final String? claimStatus;

  /// M-Pesa / transaction code they typed, when they gave one.
  final String? claimCode;

  /// How much a partial claim says was sent.
  final double? claimAmount;

  /// Their note or issue text.
  final String? claimNote;

  bool get isPaid => status == 'paid';
  bool get hasClaim => claimStatus != null && claimStatus!.isNotEmpty;
  String get displayName => name.isNotEmpty ? name : phone;
}

class CollectionDetail {
  CollectionDetail({
    required this.summary,
    required this.members,
    required this.notifySent,
    this.notifyFailed = const [],
  });

  factory CollectionDetail.fromJson(Map<String, dynamic> j) => CollectionDetail(
        summary: CollectionSummary.fromJson(j),
        members: ((j['members'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Member.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        notifySent: (j['notify']?['sent'] as int?) ?? 0,
        notifyFailed: ((j['notify']?['failed'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
      );

  final CollectionSummary summary;
  final List<Member> members;
  final int notifySent;

  /// Members whose invite SMS failed, each {phone, error}. The API has always
  /// returned this; the app used to throw it away and show a green tick anyway.
  final List<Map<String, dynamic>> notifyFailed;
}
