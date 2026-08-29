import 'package:flutter/material.dart';
import '../constants.dart';

/// TapVerify — data models. Replaces the treasurer's notebook.
///
/// Core idea: an order is recorded by a business owner, every customer gets a
/// payment task that moves through the 9-state lifecycle
/// CREATED → NOTIFIED → PENDING → COMPLETED → VERIFIED → STREAK → BADGE →
/// REWARD → ARCHIVED, and every state transition is recorded as evidence.

/// Every business owner is a person — a manufacturer, a workshop manager,
/// a production lead or an individual running one business.
enum UserKind { organization, individual }

class TapVerifyUser {
  TapVerifyUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.pin,
    required this.position,
    required this.kind,
    required this.orgName,
    this.kycApproved = false,
    this.termsAccepted = false,
  });

  final String id;
  final String name;
  final String phone;
  final String pin;
  final String position;
  final UserKind kind;
  final String orgName;
  bool kycApproved;
  bool termsAccepted;

  bool get isCollector => kind == UserKind.individual || !isWorker;
  bool get isWorker => position.toLowerCase().contains('business_owner');

  String get roleLabel => isCollector ? 'Collector · $position' : position;
}

/// How the business owner actually receives money. Customers pay into THESE account
/// details — the business owner never touches cash directly. Partner APIs (SasaPay,
/// SasaPay takes the checkout link rails in production.
class RailsConfig {
  RailsConfig({
    this.till = '',
    this.paybill = '',
    this.paybillAccount = '',
    this.bankName = '',
    this.bankAccount = '',
    this.sasapayMerchant = '',
    this.sasapayAccount = '',
  });

  String till;
  String paybill;
  String paybillAccount;
  String bankName;
  String bankAccount;
  String sasapayMerchant;
  String sasapayAccount;

  int get configuredCount => [
        till.isNotEmpty,
        paybill.isNotEmpty,
        bankAccount.isNotEmpty,
        sasapayMerchant.isNotEmpty,
      ].where((b) => b).length;
}

/// A purchased plan (Pay & go). Once active, the business owner can raise and run
/// orders; they can log in later, edit the description and raise again.
class ActivePlan {
  ActivePlan({
    required this.name,
    required this.price,
    required this.activatedAt,
  });

  final String name;
  final String price;
  final DateTime activatedAt;
}

/// The 9-state transaction lifecycle. Every payment task lives in exactly one
/// of these states; transitions are what the business owner watches in real time.
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

/// A customer on the business owner's roster.
class WfMember {
  const WfMember({
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
    this.status = 'PENDING',
    this.amount = 0,
    this.daysLate = 0,
    this.paidDate,
    this.streakMonths = 0,
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
  final String status;
  final int amount;
  final int daysLate;
  final DateTime? paidDate;
  final int streakMonths;
}

/// A customer × order payment task. `rail` + `txnRef` are the evidence of
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

/// An order raised by the business owner.
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
  final String type;
  final double amount;
  final DateTime due;
  final String railId;
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