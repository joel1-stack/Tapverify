import 'package:hive/hive.dart';

part 'pending_event.g.dart';

@HiveType(typeId: 2)
class PendingEvent {
  @HiveField(0)
  final String memberId;

  @HiveField(1)
  final String memberCode;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String eventType;

  @HiveField(4)
  final String verificationMethod;

  @HiveField(5)
  final double? gpsLat;

  @HiveField(6)
  final double? gpsLng;

  @HiveField(7)
  final String? notes;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  bool synced;

  PendingEvent({
    required this.memberId,
    required this.memberCode,
    required this.amount,
    this.eventType = 'payment_cash',
    this.verificationMethod = 'manual',
    this.gpsLat,
    this.gpsLng,
    this.notes,
    required this.createdAt,
    this.synced = false,
  });
}
