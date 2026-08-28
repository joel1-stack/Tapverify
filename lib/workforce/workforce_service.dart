import 'package:flutter/material.dart';
import 'workforce_models.dart';

/// TapVerify — core service layer. Revenue proof for manufacturing SMEs.
///
/// This is the single source of truth for the business owner app. It manages:
/// - Universal identity (business owners: manufacturer, workshop, jua kali)
/// - Order lifecycle (create, notify, pay, verify, streak, badge)
/// - Rails configuration (Till, Paybill, Bank, SasaPay)
/// - Subscription plans (Pay & go)
/// - In-memory state; in production this talks to the Django API.
class WorkforceService {
  WorkforceService._();

  // ── Identity ─────────────────────────────────────────────────────────────
  static final List<TapVerifyUser> users = _buildUsers();
  static TapVerifyUser? currentUser;

  static List<TapVerifyUser> _buildUsers() {
    return [
      TapVerifyUser(
        id: 'u-treasurer',
        name: 'Wanjiru Wambui',
        phone: '254701234567',
        pin: '123456',
        position: 'Business Owner',
        kind: UserKind.organization,
        orgName: "Peter's Metal Works",
        kycApproved: true,
        termsAccepted: true,
      ),
      TapVerifyUser(
        id: 'u-church',
        name: 'Peter Maina',
        phone: '254722345678',
        pin: '123456',
        position: 'Workshop Manager',
        kind: UserKind.organization,
        orgName: "Grace's Woodworks",
        kycApproved: true,
        termsAccepted: true,
      ),
      TapVerifyUser(
        id: 'u-school',
        name: 'Grace Otieno',
        phone: '254744567890',
        pin: '123456',
        position: 'Production Lead',
        kind: UserKind.organization,
        orgName: "John's Fabrication",
        kycApproved: true,
        termsAccepted: true,
      ),
      TapVerifyUser(
        id: 'u-individual',
        name: 'Mary Njeri',
        phone: '254733456789',
        pin: '123456',
        position: 'Business Owner',
        kind: UserKind.individual,
        orgName: 'Personal orders',
        termsAccepted: true,
      ),
    ];
  }

  static TapVerifyUser? login(String phone, String pin) {
    final p = phone.trim();
    for (final u in users) {
      if (u.phone == p && u.pin == pin.trim()) {
        currentUser = u;
        return u;
      }
    }
    return null;
  }

  static TapVerifyUser registerUser({
    required String name,
    required String phone,
    required String position,
    required UserKind kind,
    required String orgName,
    String pin = '1234',
    bool kycApproved = false,
  }) {
    final u = TapVerifyUser(
      id: 'u-${users.length + 1}',
      name: name,
      phone: phone.trim(),
      pin: pin.trim(),
      position: position,
      kind: kind,
      orgName: orgName,
      kycApproved: kycApproved,
      termsAccepted: true,
    );
    users.add(u);
    currentUser = u;
    if (kind == UserKind.organization) {
      _registeredOrg = orgName;
      _registeredPhone = phone.trim();
    }
    return u;
  }

  static String collectorDisplay() {
    final u = currentUser;
    if (u == null) return 'Business Owner';
    return '${u.name} · ${u.position}';
  }

  static String get orgName => _registeredOrg.isNotEmpty
      ? _registeredOrg
      : currentUser?.orgName ?? 'TapVerify';

  static bool get isIndividualCollector =>
      currentUser?.kind == UserKind.individual;

  // ── Registration state ─────────────────────────────────────────────────
  static String _registeredOrg = '';
  static String _registeredPhone = '';

  static String get registeredOrg => _registeredOrg;
  static String get registeredPhone => _registeredPhone;

  static void registerOrg({
    required String name,
    required String phone,
    required String type,
    required double monthlyContribution,
  }) {
    _registeredOrg = name;
    _registeredPhone = phone;
    _registeredType = type;
    _monthlyContribution = monthlyContribution;
  }

  static String _registeredType = '';
  static double _monthlyContribution = 0;

  static String get registeredType => _registeredType;
  static double get monthlyContribution => _monthlyContribution;

  // ── Rails & Plan ─────────────────────────────────────────────────────────
  static RailsConfig railsConfig = RailsConfig();
  static ActivePlan? activePlan;

  static void saveRailsConfig(RailsConfig cfg) => railsConfig = cfg;

  static void activatePlan(String name, String price) {
    activePlan = ActivePlan(name: name, price: price, activatedAt: DateTime.now());
  }

  static String get collectorQrPayload =>
      'TAPVERIFY|$_registeredOrg|$_registeredType|$_registeredPhone';

  // ── Collections & Tasks ────────────────────────────────────────────────
  static final List<WfCollection> collections = _seedDemoData();
  static final List<WfBadge> badges = _buildBadges();
  static int _seq = 200;

  static List<WfCollection> _seedDemoData() {
    final now = DateTime.now();
    final orders = [
      ('Order #1048 — St. Mary\'s School', 'School furniture', 50000.0, 3, 15, true),
      ('Order #1049 — Westlands Hardware', 'Steel supplies', 35000.0, 2, 12, true),
      ('Order #1050 — Eastlands Academy', '200 desks', 45000.0, 4, 10, true),
      ('Order #1051 — Pumani Construction', 'Roofing materials', 80000.0, 1, 5, false),
      ('Order #1052 — Donholm Furniture', 'Chairs batch', 25000.0, 3, 20, false),
      ('Order #1053 — Umoja Phase 2 Shop', 'Electrical fittings', 18000.0, 2, 8, true),
    ];

    final list = <WfCollection>[];
    for (int i = 0; i < orders.length; i++) {
      final o = orders[i];
      final tasks = <String, WfPaymentTask>{};
      final memberId = 'w-${i + 1}';
      final isPaid = o.$6 as bool;
      tasks[memberId] = WfPaymentTask(
        workerId: memberId,
        state: isPaid ? WfPaymentState.verified : WfPaymentState.pending,
        rail: 'sasapay',
        txnRef: isPaid ? 'TAM20260814${200 + i}' : '',
        amount: o.$3,
        paidAt: isPaid ? now.subtract(Duration(days: o.$5)) : null,
      );
      list.add(WfCollection(
        id: 'c-demo-${i + 1}',
        title: o.$1,
        type: o.$2,
        amount: o.$3,
        due: now.add(Duration(days: 7 + i * 3)),
        railId: 'sasapay',
        railName: 'sasapay',
        message: 'Payment for ${o.$2}',
        createdAt: now.subtract(Duration(days: 30 - i * 5)),
        tasks: tasks,
        closed: false,
      ));
    }
    return list;
  }

  static List<WfBadge> _buildBadges() {
    return const [
      WfBadge(
        id: 'b-3',
        title: 'Bronze Streak',
        desc: 'Paid on time for 3 months straight.',
        icon: Icons.looks_3_rounded,
        color: Color(0xFFB45309),
        months: 3,
        earned: true,
      ),
      WfBadge(
        id: 'b-6',
        title: 'Silver Streak',
        desc: 'Paid on time for 6 months straight.',
        icon: Icons.looks_6_rounded,
        color: Color(0xFF64748B),
        months: 6,
        earned: true,
      ),
      WfBadge(
        id: 'b-12',
        title: 'Gold Streak',
        desc: 'Paid on time for 12 months straight.',
        icon: Icons.workspace_premium_rounded,
        color: Color(0xFFC9A227),
        months: 12,
        earned: false,
      ),
      WfBadge(
        id: 'b-punctual',
        title: 'On-Time Pro',
        desc: '90%+ on-time record across all obligations.',
        icon: Icons.timer_rounded,
        color: Color(0xFF16A34A),
        months: 0,
        earned: true,
      ),
      WfBadge(
        id: 'b-first',
        title: 'First Payer',
        desc: 'First in the line every collection.',
        icon: Icons.emoji_events_rounded,
        color: Color(0xFF2563EB),
        months: 0,
        earned: false,
      ),
      WfBadge(
        id: 'b-guardian',
        title: 'Guardian',
        desc: 'Backed the emergency fund twice in a year.',
        icon: Icons.volunteer_activism_rounded,
        color: Color(0xFFDB2777),
        months: 0,
        earned: true,
      ),
    ];
  }

  static String _ref() => 'TAM20260814${(_seq++).toString()}';

  static List<WfCollection> get activeCollections =>
      collections.where((c) => !c.closed).toList()
        ..sort((a, b) => a.due.compareTo(b.due));

  static List<WfCollection> get closedCollections =>
      collections.where((c) => c.closed).toList();

  static Map<String, dynamic> stats() {
    // Demo: 48 verified payments, Ksh 2.4M, 94% consistency
    return {
      'members': 48,
      'activeCollections': activeCollections.length,
      'collected': 2400000.0,
      'expected': 2550000.0,
      'rate': 94.0,
      'paidMembers': 43,
      'pendingReminders': 5,
      'streakLeaders': 12,
      'totalTransactions': 48,
      'avgTransaction': 50000.0,
      'consistency': 94.0,
    };
  }

  static WfPaymentTask payNow(WfCollection collection, String workerId) {
    final task = collection.tasks[workerId]!;
    task.state = WfPaymentState.completed;
    task.rail = collection.railName;
    task.txnRef = _ref();
    task.paidAt = DateTime.now();
    return task;
  }

  static void verify(WfCollection collection, String workerId) {
    final task = collection.tasks[workerId]!;
    if (task.state == WfPaymentState.completed) {
      task.state = WfPaymentState.verified;
    }
  }

  static WfCollection createCollection({
    required String title,
    required String type,
    required double amount,
    required DateTime due,
    required String railId,
    required String railName,
    required String message,
    List<Map<String, String>> customers = const [],
  }) {
    final tasks = <String, WfPaymentTask>{};
    final rail = railName;
    for (int i = 0; i < customers.length; i++) {
      final m = customers[i];
      final name = m['name'] ?? 'Customer ${i + 1}';
      final phone = m['phone'] ?? '';
      final memberId = 'w-${i + 1}';
      final member = WfMember(
        id: memberId,
        code: (i + 1).toString().padLeft(2, '0'),
        name: name,
        phone: phone,
        department: 'General',
        avatarHue: (i * 31) % 360,
        memberSince: DateTime.now().year.toString(),
        currentStreak: 0,
        bestStreak: 0,
        onTimePct: 100,
      );
      tasks[member.id] = WfPaymentTask(
        workerId: member.id,
        state: WfPaymentState.notified,
        rail: rail,
        txnRef: '',
        amount: amount,
      );
    }
    final c = WfCollection(
      id: 'c-${_seq++}',
      title: title,
      type: type,
      amount: amount,
      due: due,
      railId: railId,
      railName: rail,
      message: message,
      createdAt: DateTime.now(),
      tasks: tasks,
    );
    collections.insert(0, c);
    return c;
  }

  static WfMember? memberById(String id) {
    // In production this queries the backend.
    // Placeholder — in production this queries the backend.
    return WfMember(
      id: id,
      code: id.replaceFirst('w-', '').padLeft(2, '0'),
      name: 'Customer ${id.replaceFirst("w-", "")}',
      phone: '2547${id.replaceFirst("w-", "").padLeft(8, "0")}',
      department: 'General',
      avatarHue: (int.tryParse(id.replaceFirst('w-', '')) ?? 0) * 31 % 360,
      memberSince: DateTime.now().year.toString(),
      currentStreak: 0,
      bestStreak: 0,
      onTimePct: 100,
    );
  }

  static List<({WfCollection collection, WfPaymentTask task})> tasksForMember(
      String memberId) {
    final out = <({WfCollection collection, WfPaymentTask task})>[];
    for (final c in activeCollections) {
      final t = c.tasks[memberId];
      if (t != null) out.add((collection: c, task: t));
    }
    return out;
  }

}