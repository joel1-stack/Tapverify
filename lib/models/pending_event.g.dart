// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingEventAdapter extends TypeAdapter<PendingEvent> {
  @override
  final int typeId = 2;

  @override
  PendingEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingEvent(
      memberId: fields[0] as String,
      memberCode: fields[1] as String,
      amount: fields[2] as double,
      eventType: fields[3] as String,
      verificationMethod: fields[4] as String,
      gpsLat: fields[5] as double?,
      gpsLng: fields[6] as double?,
      notes: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      synced: fields[9] as bool,
      workspaceId: fields[10] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, PendingEvent obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.memberId)
      ..writeByte(1)
      ..write(obj.memberCode)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.eventType)
      ..writeByte(4)
      ..write(obj.verificationMethod)
      ..writeByte(5)
      ..write(obj.gpsLat)
      ..writeByte(6)
      ..write(obj.gpsLng)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.synced)
      ..writeByte(10)
      ..write(obj.workspaceId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
