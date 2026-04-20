// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_local_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrackPointLocalAdapter extends TypeAdapter<TrackPointLocal> {
  @override
  final int typeId = 0;

  @override
  TrackPointLocal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrackPointLocal(
      id: fields[0] as String,
      trackSessionId: fields[1] as String,
      latitude: fields[2] as double,
      longitude: fields[3] as double,
      altitude: fields[4] as double,
      speed: fields[5] as double,
      timestamp: fields[6] as DateTime,
      isSynced: fields[7] == null ? false : fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TrackPointLocal obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.trackSessionId)
      ..writeByte(2)
      ..write(obj.latitude)
      ..writeByte(3)
      ..write(obj.longitude)
      ..writeByte(4)
      ..write(obj.altitude)
      ..writeByte(5)
      ..write(obj.speed)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackPointLocalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TrackSessionLocalAdapter extends TypeAdapter<TrackSessionLocal> {
  @override
  final int typeId = 1;

  @override
  TrackSessionLocal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrackSessionLocal(
      sessionId: fields[0] as String,
      startedAt: fields[1] as DateTime,
      lastSyncedAt: fields[2] as DateTime?,
      isCompleted: fields[3] == null ? false : fields[3] as bool,
      isSynced: fields[4] == null ? false : fields[4] as bool,
      totalPoints: fields[5] == null ? 0 : fields[5] as int,
      distance: fields[6] == null ? 0 : fields[6] as double,
      steps: fields[7] == null ? 0 : fields[7] as int,
      calories: fields[8] == null ? 0 : fields[8] as int,
      duration: fields[9] == null ? 0 : fields[9] as int,
      serverTrackId: fields[10] == null ? '' : fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TrackSessionLocal obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.sessionId)
      ..writeByte(1)
      ..write(obj.startedAt)
      ..writeByte(2)
      ..write(obj.lastSyncedAt)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.isSynced)
      ..writeByte(5)
      ..write(obj.totalPoints)
      ..writeByte(6)
      ..write(obj.distance)
      ..writeByte(7)
      ..write(obj.steps)
      ..writeByte(8)
      ..write(obj.calories)
      ..writeByte(9)
      ..write(obj.duration)
      ..writeByte(10)
      ..write(obj.serverTrackId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackSessionLocalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
