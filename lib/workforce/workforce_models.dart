import 'package:flutter/material.dart';
import '../constants.dart';

/// TapVerify Workforce — data models.
///
/// This mirrors the backend plan (`payments/router.py`, `models.py`) so the
/// mobile app can be shipped first and wired to real rails (LOOP / SasaPay /
/// Africa's Talking) later without changing the UI contract.
///
/// Core idea: an OBLIGATION is created by a foreman, every worker gets a
/// payment task that moves through the 9-state lifecycle
/// CREATED → NOTIFIED → PENDING → COMPLETED → VERIFIED → STREAK → BADGE →
/// REWARD → ARCHIVED, and every state transition is recorded as evidence.

/// A factory worker on the foreman's roster.
class WfWorker {
  const WfWorker({
    required this.id,
    required this.code,
    required this.name,
    required this.phone,
    required this.department,
    required this.avatarHue,
    required this.memberSince,
    required this.currentStreak,
    required this.bestStreak,
    required this.onTimePct,
  });

  final String id;
  final String code;
  final String name;
  final String phone;
  final String department;
  final double avatarHue;
  final String memberSince;
  final int currentStreak;
  final int bestStreak;
  final double onTimePct;
}

/// The 9-state transaction lifecycle. Every payment task lives in exactly one
/// of these states; transitions are what the foreman watches in real time.
enum WfPaymentState {
  created('CREATED', 'Task created', Icons.create_rounded, AppColors.muted),
  notified('NOTIFIED', 'SMS/USSD sent', Icons.notifications_active_rounded,
      const Color(0xFF2563EB)),
  pending('PENDING', 'Awaiting payment', Icons.hourglass_top_rounded,
      AppColors.warning),
  completed('COMPLETED', 'Payment received', Icons.check_circle_rounded,
      const Color(0xFF16A34A)),
  verified('VERIFIED', 'Proof verified', Icons.verified_rounded,
      const Color(0xFF0F766E)),
  streak('STREAK', 'Streak extended', Icons.local_fire_department_rounded,
      AppColors.gold),
  badge('BADGE', 'Badge earned', Icons.military_tech_rounded,
      const Color(0xFF7C3AED)),
  reward('REWARD', 'Reward unlocked', Icons.card_giftcard_rounded,
      const Color(0xFFDB2777)),
  archived('ARCHIVED', 'Archived', Icons.archive_rounded, AppColors.muted);

  const WfPaymentState(this.label, this.desc, this.icon, this.color);

  final String label;
  final String desc;
  final IconData icon;
  final Color color;
}

/// A worker × obligation payment task. `rail` + `txnRef` are the evidence of
/// how the money actually moved.
class WfPaymentTask {
  WfPaymentTask({
    required this.workerId,
    required this.state,
    required this.rail,
    required this.txnRef,
    this.amount = 0,
    this.paidAt,
  });

  final String workerId;
  WfPaymentState state;
  String rail;
  String txnRef;
  double amount;
  DateTime? paidAt;
}

/// An obligation / collection raised by the foreman.
class WfCollection {
  WfCollection({
    required this.id,
    required this.title,
    required this.type,
    required this.amount,
    required this.due,
    required this.railId,
    required this.railName,
    required this.message,
    required this.createdAt,
    required this.tasks,
    this.closed = false,
  });

  final String id;
  final String title;
  final String type; // Welfare / Medical / Emergency / Trip
  final double amount;
  final DateTime due;
  final String railId; // loop-prompt | sasapay | till | paybill
  final String railName;
  final String message;
  final DateTime createdAt;
  final Map<String, WfPaymentTask> tasks;
  bool closed;

  int get paidCount =>
      tasks.values.where((t) => t.state.index >= WfPaymentState.completed.index)
          .length;

  double get collected => tasks.values.fold(
      0.0,
      (sum, t) =>
          sum +
          (t.state.index >= WfPaymentState.completed.index ? t.amount : 0));
}

/// A recognition badge (Avalanche attestation is the optional proof layer for
/// these in production; in the app they are local for now).
class WfBadge {
  const WfBadge({
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.months,
    this.earned = false,
  });

  final String id;
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final int months;
  final bool earned;
}
