import 'dart:math';
import 'package:flutter/material.dart';
import 'workforce_models.dart';

/// TapVerify Workforce — in-memory demo source of truth.
///
/// Seeds the Kamau Metalworks demo: 47 workers across five departments, four
/// collections (welfare / medical / emergency / trip), and every payment task
/// positioned somewhere in the 9-state lifecycle so the foreman dashboard and
/// the web demo can render realistic proof. No network calls — payment rails
/// are wired later with real keys; here they are simulated labels + TAM-style
/// reference numbers.
class WorkforceService {
  WorkforceService._();

  static final _rng = Random(7);

  static const String demoForemanName = 'Juma Kamau';
  static const String demoForemanPhone = '254712345678';
  static const String demoWorkerName = 'Ochieng Odhiambo';
  static const String demoWorkerPhone = '254715641339';
  static const String orgName = 'Kamau Metalworks';
  static const String orgCode = 'KM';

  /// Mutable registration state — set by the WorkforceRegistrationScreen.
  static String registeredOrg = orgName;
  static String registeredPhone = demoForemanPhone;

  static final List<WfWorker> workers = _buildWorkers();
  static final List<WfCollection> collections = _buildCollections(workers);
  static final List<WfBadge> badges = _buildBadges();
  static int _seq = 100;

  static final List<String> _firstNames = [
    'Ochieng', 'Wanjiru', 'Kipchoge', 'Achieng', 'Mwangi', 'Chebet', 'Otieno',
    'Njeri', 'Kiprop', 'Muthoni', 'Omondi', 'Wambui', 'Koech', 'Akinyi',
    'Njoroge', 'Jebet', 'Oduya', 'Nyambura', 'Kiptoo', 'Adhiambo', 'Kimani',
    'Chepkoech', 'Onyango', 'Wairimu', 'Rono', 'Anyango', 'Mutua', 'Kosgei',
    'Auma', 'Ndungu', 'Chelangat', 'Odhiambo', 'Waithera', 'Kipyego',
    'Ogalo', 'Njoki', 'Langat', 'Apiyo', 'Karanja', 'Cherono', 'Odongo',
    'Nekesa', 'Maina', 'Rotich', 'Adoyo', 'Mburu', 'Kendi',
  ];

  static final List<String> _lastNames = [
    'Odhiambo', 'Wanjiku', 'Kiprop', 'Okoth', 'Mwangi', 'Kiplagat', 'Onyango',
    'Njoroge', 'Rono', 'Chepkemoi', 'Otieno', 'Kimani', 'Kosgei', 'Omondi',
    'Mutua', 'Jepkorir', 'Ochieng', 'Wambugu', 'Langat', 'Ouko', 'Ndegwa',
    'Cheruiyot', 'Awuor', 'Maina', 'Kemei', 'Achieng', 'Gitau', 'Kibet',
  ];

  static final List<String> _departments = [
    'Foundry', 'Machining', 'Assembly', 'Fabrication', 'Admin',
  ];

  static List<WfWorker> _buildWorkers() {
    final list = <WfWorker>[];
    for (int i = 0; i < 47; i++) {
      final first = _firstNames[i];
      final last = _lastNames[_rng.nextInt(_lastNames.length)];
      list.add(WfWorker(
        id: 'w-${i + 1}',
        code: '$orgCode${(i + 1).toString().padLeft(2, '0')}',
        name: '$first $last',
        phone: '2547${(10000000 + _rng.nextInt(89999999)).toString()}',
        department: _departments[i % _departments.length],
        avatarHue: (i * 31) % 360,
        memberSince: '${2020 + (i % 5)}-${(i % 12) + 1}',
        currentStreak: i % 13, // 0..12
        bestStreak: 3 + (i % 10),
        onTimePct: 60 + (i % 40),
      ));
    }
    return list;
  }

  static String _ref() => 'TAM20260814${(_seq++).toString()}';

  static List<WfCollection> _buildCollections(List<WfWorker> all) {
    final now = DateTime.now();
    final startIdx = {
      'foundry': 0,
      'machining': 9,
      'assembly': 18,
      'fabrication': 27,
      'admin': 36,
    };

    WfPaymentTask task(String wId, String rail, WfPaymentState st,
        {String ref = '', double amount = 0}) {
      return WfPaymentTask(
        workerId: wId,
        state: st,
        rail: rail,
        txnRef: ref.isEmpty ? _ref() : ref,
        amount: amount,
        paidAt: st.index >= WfPaymentState.completed.index ? now : null,
      );
    }

    /// Worker ids for a department slice of `size`.
    List<String> slice(String dept, int size) =>
        all.skip(startIdx[dept]!).take(size).map((w) => w.id).toList();

    final collections = <WfCollection>[];

    // 1. ACTIVE — August welfare levy (LOOP Prompt). Mix of states so the
    //    "who paid" grid and the 9-state stepper look alive.
    {
      final ids = all.map((w) => w.id).toList();
      final rail = 'M-Pesa STK Prompt';
      final tasks = <String, WfPaymentTask>{};
      for (int i = 0; i < ids.length; i++) {
        final id = ids[i];
        WfPaymentState st;
        if (i < 24) {
          st = WfPaymentState.completed;
        } else if (i < 30) {
          st = WfPaymentState.pending;
        } else if (i < 36) {
          st = WfPaymentState.notified;
        } else if (i < 42) {
          st = WfPaymentState.created;
        } else {
          st = WfPaymentState.pending;
        }
        tasks[id] = task(id, rail, st, amount: 200);
      }
      collections.add(WfCollection(
        id: 'c-aug-welfare',
        title: 'August welfare levy',
        type: 'Welfare',
        amount: 200,
        due: now.add(const Duration(days: 5)),
        railId: 'mpesa-prompt',
        railName: rail,
        message:
            'KM welfare for August — Ksh 200. Pay via your checkout link.',
        createdAt: now.subtract(const Duration(days: 2)),
        tasks: tasks,
      ));
    }

    // 2. ACTIVE — Medical fund top-up (SasaPay Checkout links). Mostly
    //    pending/notified so the foreman can send reminders.
    {
      final ids = slice('machining', 20);
      final rail = 'SasaPay Checkout link';
      final tasks = <String, WfPaymentTask>{};
      for (int i = 0; i < ids.length; i++) {
        final id = ids[i];
        WfPaymentState st;
        if (i < 6) {
          st = WfPaymentState.completed;
        } else if (i < 11) {
          st = WfPaymentState.pending;
        } else {
          st = WfPaymentState.notified;
        }
        tasks[id] = task(id, rail, st, amount: 500);
      }
      collections.add(WfCollection(
        id: 'c-medical',
        title: 'Medical fund top-up',
        type: 'Medical',
        amount: 500,
        due: now.add(const Duration(days: 3)),
        railId: 'sasapay',
        railName: rail,
        message:
            'Medical fund top-up — Ksh 500. Checkout link sent by SMS; MPESA/Equity accepted.',
        createdAt: now.subtract(const Duration(days: 1)),
        tasks: tasks,
      ));
    }

    // 3. CLOSED — Emergency (Mwangi family). All paid + verified, some with
    //    streaks so the badge section has earned badges.
    {
      final ids = all.map((w) => w.id).toList();
      final rail = 'M-Pesa STK Prompt';
      final tasks = <String, WfPaymentTask>{};
      for (int i = 0; i < ids.length; i++) {
        final id = ids[i];
        WfPaymentState st;
        if (i % 7 == 0) {
          st = WfPaymentState.streak;
        } else if (i % 13 == 0) {
          st = WfPaymentState.badge;
        } else {
          st = WfPaymentState.completed;
        }
        tasks[id] = task(id, rail, st, amount: 1000);
      }
      final c = WfCollection(
        id: 'c-emergency',
        title: 'Emergency — Mwangi family',
        type: 'Emergency',
        amount: 1000,
        due: now.subtract(const Duration(days: 3)),
        railId: 'sasapay',
        railName: rail,
        message:
            'EMERGENCY — support for the Mwangi family. Contribute Ksh 1,000 before the deadline.',
        createdAt: now.subtract(const Duration(days: 7)),
        tasks: tasks,
      )
        ..closed = true;
      collections.add(c);
    }

    // 4. ACTIVE — End-year trip deposit (Paybill). Mixed partial progress.
    {
      final ids = slice('fabrication', 25);
      final rail = 'M-PESA Paybill 522033';
      final tasks = <String, WfPaymentTask>{};
      for (int i = 0; i < ids.length; i++) {
        final id = ids[i];
        WfPaymentState st;
        if (i < 9) {
          st = WfPaymentState.completed;
        } else if (i < 15) {
          st = WfPaymentState.verified;
        } else if (i < 20) {
          st = WfPaymentState.pending;
        } else {
          st = WfPaymentState.created;
        }
        tasks[id] = task(id, rail, st, amount: 2500);
      }
      collections.add(WfCollection(
        id: 'c-trip',
        title: 'End-year trip deposit',
        type: 'Trip',
        amount: 2500,
        due: now.add(const Duration(days: 12)),
        railId: 'paybill',
        railName: rail,
        message:
            'End-year staff trip — deposit Ksh 2,500. Paybill 522033, account KM01.',
        createdAt: now.subtract(const Duration(days: 4)),
        tasks: tasks,
      ));
    }

    return collections;
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

  // ── queries ───────────────────────────────────────────────────────────────

  /// Registers a new factory and updates the demo foreman identity.
  static void registerOrg({
    required String name,
    required String phone,
    required String type,
    required double monthlyContribution,
  }) {
    registeredOrg = name;
    registeredPhone = phone;
    _registeredType = type;
    _monthlyContribution = monthlyContribution;
  }

  static String _registeredType = 'Metalworks';
  static double _monthlyContribution = 200;

  static String get registeredType => _registeredType;
  static double get monthlyContribution => _monthlyContribution;

  /// Bulk-adds workers from a CSV import (name, phone, department).
  static int importWorkers(
      List<({String name, String phone, String department})> rows) {
    var added = 0;
    for (final row in rows) {
      if (row.name.trim().isEmpty) continue;
      final n = workers.length + 1;
      workers.add(WfWorker(
        id: 'w-$n',
        code: '${orgCode}${n.toString().padLeft(2, '0')}',
        name: row.name.trim(),
        phone: row.phone.trim().replaceAll(RegExp(r'\s+'), ''),
        department: row.department.trim().isEmpty ? 'General' : row.department.trim(),
        avatarHue: (n * 31) % 360,
        memberSince: DateTime.now().year.toString(),
        currentStreak: 0,
        bestStreak: 0,
        onTimePct: 100,
      ));
      added++;
    }
    return added;
  }

  /// Payload encoded in the factory's payment QR card.
  static String get foremanQrPayload =>
      'TAPVERIFY|$registeredOrg|${_registeredType}|$registeredPhone';

  static List<WfCollection> get activeCollections =>
      collections.where((c) => !c.closed).toList()
        ..sort((a, b) => a.due.compareTo(b.due));

  static List<WfCollection> get closedCollections =>
      collections.where((c) => c.closed).toList();

  static WfWorker? workerById(String id) {
    for (final w in workers) {
      if (w.id == id) return w;
    }
    return null;
  }

  /// Aggregate stats for the foreman dashboard.
  static Map<String, dynamic> stats() {
    final active = activeCollections;
    final totalCollected = active.fold<double>(
        0.0, (s, c) => s + c.collected);
    final totalExpected =
        active.fold<double>(0.0, (s, c) => s + c.amount * c.tasks.length);
    final paidMembers = <String>{};
    for (final c in active) {
      c.tasks.forEach((wid, t) {
        if (t.state.index >= WfPaymentState.completed.index) paidMembers.add(wid);
      });
    }
    final rate = totalExpected == 0 ? 0.0 : (totalCollected / totalExpected) * 100;
    return {
      'workers': workers.length,
      'paidMembers': paidMembers.length,
      'activeCollections': active.length,
      'collected': totalCollected,
      'expected': totalExpected,
      'rate': rate,
      'pendingReminders': active.fold<int>(
          0,
          (s, c) =>
              s +
              c.tasks.values
                  .where((t) =>
                      t.state == WfPaymentState.pending ||
                      t.state == WfPaymentState.created)
                  .length),
      'streakLeaders': workers.where((w) => w.currentStreak >= 6).length,
    };
  }

  /// Payment tasks that belong to a worker across all active collections.
  static List<({WfCollection collection, WfPaymentTask task})> tasksForWorker(
      String workerId) {
    final out = <({WfCollection collection, WfPaymentTask task})>[];
    for (final c in activeCollections) {
      final t = c.tasks[workerId];
      if (t != null) out.add((collection: c, task: t));
    }
    return out;
  }

  /// Simulates a worker paying now: CREATED/NOTIFIED/PENDING → COMPLETED →
  /// VERIFIED, bumps streak, possibly earns a badge. Returns the payment task.
  static WfPaymentTask payNow(WfCollection collection, String workerId) {
    final task = collection.tasks[workerId]!;
    task.state = WfPaymentState.completed;
    task.rail = collection.railName;
    task.txnRef = _ref();
    task.paidAt = DateTime.now();
    return task;
  }

  /// Simulates the proof layer: VERIFIED (in production, a signed webhook /
  /// Avalanche attestation). Completes the journey to proof.
  static void verify(WfCollection collection, String workerId) {
    final task = collection.tasks[workerId]!;
    if (task.state == WfPaymentState.completed) {
      task.state = WfPaymentState.verified;
    }
  }

  /// Creates a new obligation and notifies every worker (simulated SMS).
  static WfCollection createCollection({
    required String title,
    required String type,
    required double amount,
    required DateTime due,
    required String railId,
    required String railName,
    required String message,
  }) {
    final tasks = <String, WfPaymentTask>{};
    final rail = railName;
    for (final w in workers) {
      tasks[w.id] = WfPaymentTask(
        workerId: w.id,
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
}
