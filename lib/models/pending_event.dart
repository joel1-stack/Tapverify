import 'package:hive/hive.dart';

part 'pending_event.g.dart';

/// An offline verification awaiting upload.
///
/// When the Treasurer verifies a payment while the server is unreachable the
/// record lands here; [ApiService.syncPending] replays them to the backend and
/// flips [synced] to true. Keeps the exact member, amount, event type,
/// verification method and optional GPS so a late sync is still accurate.
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

  @HiveField(10)
  final String workspaceId;

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
    this.workspaceId = '',
  });
}
