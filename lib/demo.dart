import 'dart:convert';
import 'dart:math';

import 'api.dart';
import 'models.dart';

/// In-memory backend that powers the web build.
///
/// The mobile app is the real product: it always talks to the Django API.
/// The web build is the public demo (tapverify.vercel.app has no server
/// behind it), so every Api call is answered here. State lives for the
/// browser session, so creating a collection, marking a member paid and the
/// live list all genuinely work end to end.
class Demo {
  Demo._();

  static final Demo instance = Demo._();

  static const String demoToken = 'demo-session-token';
  static const List<String> _names = [
    'Mary Wanjiku',
    'John Otieno',
    'Faith Njeri',
    'Peter Kamau',
    'Grace Achieng',
    'David Ochieng',
    'Sarah Muthoni',
    'Brian Kiprotich',
    'Ann Wairimu',
    'Samuel Otieno',
    'Lydia Chebet',
    'Michael Njoroge',
    'Esther Akinyi',
    'Joseph Mwangi',
    'Mercy Anyango',
    'Daniel Kiptoo',
    'Ruth Wanjala',
    'Victor Omondi',
    'Cynthia Moraa',
    'Alex Maina',
  ];

  final Random _rng = Random(0x7A6B);
  final List<CollectionDetail> _collections = [];
  bool _seeded = false;
  String? _code;
  String? _codePhone;
  String _pendingName = '';
  String _pendingGroup = '';
  int _nextMemberId = 5000;

  String get _phone => _codePhone ?? '';

  // ── Seed data (matches the home mockup numbers exactly) ───────────────

  CollectionDetail _make({
    required int id,
    required String title,
    required double amount,
    required int paidCount,
    required int memberCount,
    String? dueDate,
    String description = '',
    int iconSeed = 0,
  }) {
    final members = <Member>[];
    for (var i = 0; i < memberCount; i++) {
      final paid = i < paidCount;
      final memberId = _nextMemberId++;
      // A few pre-loaded claims so the treasurer's Claims tab has content.
      String? claimStatus;
      String? claimCode;
      double? claimAmount;
      String? claimNote;
      if (id == 1 && !paid) {
        if (i == 18) {
          claimStatus = 'claimed';
          claimCode = 'SJ7K2M9PQ';
        } else if (i == 20) {
          claimStatus = 'partial';
          claimCode = 'SJ8X41LBL';
          claimAmount = 300;
        } else if (i == 22) {
          claimStatus = 'issue';
          claimNote = 'I already paid cash to the treasurer on Friday';
        } else if (i == 24) {
          claimStatus = 'cancelled';
        }
      }
      members.add(Member(
        id: memberId,
        name: _names[(i + iconSeed) % _names.length],
        phone: '07${(11 + ((i + iconSeed) % 80)).toString().padLeft(2, '0')} ${100 + ((i * 37 + iconSeed) % 900)} ${100 + ((i * 53 + iconSeed) % 900)}',
        status: paid ? 'paid' : 'unpaid',
        paidAt: paid ? '2026-10-0${1 + (i % 6)}T10:${(i * 7) % 60}:00+03:00' : null,
        paidMethod: paid ? (i.isEven ? 'mpesa' : 'cash') : null,
        paidAmount: paid ? amount : null,
        amountMismatch: false,
        remindersSent: paid ? 0 : (i % 2),
        payLink: 'https://tapverify.vercel.app/#/pay/$id/$memberId',
        claimStatus: claimStatus,
        claimCode: claimCode,
        claimAmount: claimAmount,
        claimNote: claimNote,
      ));
    }
    final collected =
        members.where((m) => m.isPaid).fold<double>(0, (s, m) => s + (m.paidAmount ?? 0));
    return CollectionDetail(
      summary: CollectionSummary(
        id: id,
        title: title,
        amount: amount,
        payoutMethod: 'till',
        memberCount: memberCount,
        paidCount: paidCount,
        collected: collected,
        outstanding: (memberCount - paidCount) * amount,
        description: description,
        dueDate: dueDate,
        payoutDetails: const {'till_number': '567890'},
      ),
      members: members,
      notifySent: memberCount,
    );
  }

  void _seed() {
    if (_seeded) return;
    _seeded = true;
    // Numbers lifted straight from the home design: 18/40 collected 9,000.
    _collections.addAll([
      _make(
        id: 1,
        title: 'Monthly Savings',
        amount: 500,
        paidCount: 18,
        memberCount: 40,
        dueDate: '2026-10-31',
        description: 'Monthly contribution to the group savings fund',
      ),
      _make(
        id: 2,
        title: 'School Fees',
        amount: 500,
        paidCount: 5,
        memberCount: 20,
        dueDate: '2026-11-15',
        description: 'Helping members pay school fees in time',
        iconSeed: 3,
      ),
      _make(
        id: 3,
        title: 'Christmas Fund',
        amount: 16000 / 12,
        paidCount: 12,
        memberCount: 30,
        dueDate: '2026-12-20',
        description: 'Saving together for the festive season',
        iconSeed: 6,
      ),
      _make(
        id: 4,
        title: 'Emergency Fund',
        amount: 1000,
        paidCount: 8,
        memberCount: 25,
        description: 'Contribution to the group emergency kitty',
        iconSeed: 9,
      ),
      _make(
        id: 5,
        title: 'Phone Purchase',
        amount: 1000,
        paidCount: 6,
        memberCount: 15,
        description: 'Saving towards a group phone',
        iconSeed: 12,
      ),
    ]);
  }

  CollectionDetail _detail(int id) {
    _seed();
    for (final c in _collections) {
      if (c.summary.id == id) return c;
    }
    throw StateError('Collection $id not found');
  }

  // ── Auth ──────────────────────────────────────────────────────────────

  Map<String, dynamic> requestOtp(String phone) {
    _code = (_rng.nextInt(900000) + 100000).toString();
    _codePhone = phone;
    // Same contract as the real API: dev_code only exists in demo/sandbox.
    return {'sent': true, 'dev_code': _code};
  }

  String verifyOtp(String phone, String code) {
    final ok = code == _code || code == '123456';
    if (!ok) {
      throw ApiException('That code is not correct. Try again.', statusCode: 400);
    }
    _codePhone = phone;
    return demoToken;
  }

  Map<String, dynamic> register(
      {required String name, required String phone, String group = ''}) {
    _pendingName = name;
    _pendingGroup = group;
    final res = requestOtp(phone);
    return res;
  }

  Map<String, dynamic> me() => {
        'phone': _phone,
        'name': _pendingName,
        'group_name': _pendingGroup,
      };

  // ── Collections ───────────────────────────────────────────────────────

  List<CollectionSummary> listCollections() {
    _seed();
    return _collections.map((c) => c.summary).toList();
  }

  CollectionDetail getCollection(int id) => _detail(id);

  CollectionDetail createCollection({
    required String title,
    required String amount,
    String? dueDate,
    String description = '',
    required String payoutMethod,
    Map<String, String> payoutFields = const {},
    required String membersText,
  }) {
    _seed();
    final value = double.tryParse(amount.replaceAll(',', '')) ?? 0;
    final lines = membersText
        .split(RegExp(r'[\n,;]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final collectionId = _collections.isEmpty
        ? 1
        : _collections.map((c) => c.summary.id).reduce(max) + 1;
    final members = <Member>[];
    for (final line in lines) {
      // "Mary Wanjiku - 0712345678", "0712345678", "Mary, 0712 345 678"...
      final parts = line.split(RegExp(r'\s*[-–|,;]\s*'));
      String name = '';
      String phone = '';
      for (final p in parts) {
        if (RegExp(r'[0-9+]').hasMatch(p) && p.replaceAll(RegExp(r'[^0-9+]'), '').length >= 9) {
          phone = p.trim();
        } else if (p.trim().isNotEmpty && name.isEmpty) {
          name = p.trim();
        }
      }
      if (phone.isEmpty && name.isNotEmpty && RegExp(r'^[0-9+]').hasMatch(name)) {
        phone = name;
        name = '';
      }
      if (phone.isEmpty) continue;
      final memberId = _nextMemberId++;
      members.add(Member(
        id: memberId,
        name: name,
        phone: phone,
        status: 'unpaid',
        amountMismatch: false,
        remindersSent: 0,
        payLink: 'https://tapverify.vercel.app/#/pay/$collectionId/$memberId',
      ));
    }
    final detail = CollectionDetail(
      summary: CollectionSummary(
        id: collectionId,
        title: title,
        amount: value,
        payoutMethod: payoutMethod,
        memberCount: members.length,
        paidCount: 0,
        collected: 0,
        outstanding: members.length * value,
        description: description,
        dueDate: dueDate,
        payoutDetails: payoutFields,
      ),
      members: members,
      notifySent: members.length,
    );
    _collections.insert(0, detail);
    return detail;
  }

  int remindUnpaid(int collectionId) {
    final detail = _detail(collectionId);
    var sent = 0;
    for (var i = 0; i < detail.members.length; i++) {
      final m = detail.members[i];
      if (m.isPaid) continue;
      detail.members[i] = Member(
        id: m.id,
        name: m.name,
        phone: m.phone,
        status: m.status,
        paidAt: m.paidAt,
        paidMethod: m.paidMethod,
        paidAmount: m.paidAmount,
        amountMismatch: m.amountMismatch,
        transactionRef: m.transactionRef,
        remindersSent: m.remindersSent + 1,
        payLink: m.payLink,
        claimStatus: m.claimStatus,
        claimCode: m.claimCode,
        claimAmount: m.claimAmount,
        claimNote: m.claimNote,
      );
      sent++;
    }
    return sent;
  }

  List<int> exportCsv(int collectionId) {
    final detail = _detail(collectionId);
    final b = StringBuffer('name,phone,status,paid_at,paid_method\n');
    for (final m in detail.members) {
      b.writeln('"${m.name}","${m.phone}",${m.status},${m.paidAt ?? ''},${m.paidMethod ?? ''}');
    }
    return utf8.encode(b.toString());
  }

  // ── Members ───────────────────────────────────────────────────────────

  Member _member(int memberId) {
    _seed();
    for (final c in _collections) {
      final idx = c.members.indexWhere((m) => m.id == memberId);
      if (idx >= 0) return c.members[idx];
    }
    throw StateError('Member $memberId not found');
  }

  void _replace(int memberId, Member updated) {
    for (var ci = 0; ci < _collections.length; ci++) {
      final c = _collections[ci];
      final idx = c.members.indexWhere((m) => m.id == memberId);
      if (idx < 0) continue;
      c.members[idx] = updated;
      final paid = c.members.where((m) => m.isPaid).toList();
      final collected = paid.fold<double>(0, (s, m) => s + (m.paidAmount ?? 0));
      final s = c.summary;
      // Partial payments count: someone still owes the missing difference.
      final outstanding = c.members.fold<double>(0, (acc, m) {
        if (!m.isPaid) return acc + s.amount;
        final got = m.paidAmount ?? s.amount;
        return acc + (got < s.amount ? s.amount - got : 0);
      });
      // CollectionSummary is immutable: rebuild it around the same members.
      _collections[ci] = CollectionDetail(
        summary: CollectionSummary(
          id: s.id,
          title: s.title,
          amount: s.amount,
          payoutMethod: s.payoutMethod,
          memberCount: s.memberCount,
          paidCount: paid.length,
          collected: collected,
          outstanding: outstanding,
          description: s.description,
          dueDate: s.dueDate,
          autoDetect: s.autoDetect,
          payoutDetails: s.payoutDetails,
        ),
        members: c.members,
        notifySent: c.notifySent,
        notifyFailed: c.notifyFailed,
      );
      return;
    }
  }

  Member markPaid(int memberId, String method, {double? amount}) {
    final m = _member(memberId);
    final expected = _collections
        .firstWhere((c) => c.members.any((x) => x.id == memberId))
        .summary
        .amount;
    // A payer can record the full amount or any part of it; anything short
    // of the collection amount is kept as a partial payment. An approved
    // payment retires any claim the member had open.
    final paid = amount ?? m.paidAmount ?? expected;
    final updated = Member(
      id: m.id,
      name: m.name,
      phone: m.phone,
      status: 'paid',
      paidAt: DateTime.now().toIso8601String(),
      paidMethod: method,
      paidAmount: paid,
      amountMismatch: paid < expected,
      transactionRef: 'DEMO${m.id}',
      remindersSent: m.remindersSent,
      payLink: m.payLink,
    );
    _replace(memberId, updated);
    return updated;
  }

  // ── Claims (from the public payment link page) ────────────────────────

  Member submitClaim(int memberId,
      {required String status,
      double? amount,
      String? code,
      String? note}) {
    final m = _member(memberId);
    _replace(
      memberId,
      Member(
        id: m.id,
        name: m.name,
        phone: m.phone,
        status: m.status,
        paidAt: m.paidAt,
        paidMethod: m.paidMethod,
        paidAmount: m.paidAmount,
        amountMismatch: m.amountMismatch,
        transactionRef: m.transactionRef,
        remindersSent: m.remindersSent,
        payLink: m.payLink,
        claimStatus: status,
        claimCode: (code == null || code.trim().isEmpty) ? null : code.trim(),
        claimAmount: amount,
        claimNote: (note == null || note.trim().isEmpty) ? null : note.trim(),
      ),
    );
    return _member(memberId);
  }

  /// The treasurer approves (mark paid) or rejects (drop) a member's claim.
  Member resolveClaim(int memberId, {required bool approve}) {
    final m = _member(memberId);
    if (!approve) {
      // Rejected, cancelled or dismissed: nothing owed changes, claim clears.
      _replace(
        memberId,
        Member(
          id: m.id,
          name: m.name,
          phone: m.phone,
          status: m.status,
          paidAt: m.paidAt,
          paidMethod: m.paidMethod,
          paidAmount: m.paidAmount,
          amountMismatch: m.amountMismatch,
          transactionRef: m.transactionRef,
          remindersSent: m.remindersSent,
          payLink: m.payLink,
        ),
      );
      return _member(memberId);
    }
    if (m.claimStatus == 'claimed') return markPaid(memberId, 'cash');
    if (m.claimStatus == 'partial') {
      return markPaid(memberId, 'cash', amount: m.claimAmount);
    }
    // 'issue' or 'cancelled': approving just clears the notice.
    return resolveClaim(memberId, approve: false);
  }

  bool remindMember(int memberId) {
    final m = _member(memberId);
    _replace(
      memberId,
      Member(
        id: m.id,
        name: m.name,
        phone: m.phone,
        status: m.status,
        paidAt: m.paidAt,
        paidMethod: m.paidMethod,
        paidAmount: m.paidAmount,
        amountMismatch: m.amountMismatch,
        transactionRef: m.transactionRef,
        remindersSent: m.remindersSent + 1,
        payLink: m.payLink,
        claimStatus: m.claimStatus,
        claimCode: m.claimCode,
        claimAmount: m.claimAmount,
        claimNote: m.claimNote,
      ),
    );
    return true;
  }
}
