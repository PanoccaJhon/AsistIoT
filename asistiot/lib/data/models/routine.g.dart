// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoutineAdapter extends TypeAdapter<Routine> {
  @override
  final int typeId = 0;

  @override
  Routine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Routine()
      ..id = fields[0] as String
      ..deviceId = fields[7] as String
      ..title = fields[1] as String
      ..hour = fields[2] as int
      ..minute = fields[3] as int
      ..days = (fields[4] as List).cast<int>()
      ..commandPayload = fields[5] as String
      ..isActive = fields[6] as bool;
  }

  @override
  void write(BinaryWriter writer, Routine obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(7)
      ..write(obj.deviceId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.hour)
      ..writeByte(3)
      ..write(obj.minute)
      ..writeByte(4)
      ..write(obj.days)
      ..writeByte(5)
      ..write(obj.commandPayload)
      ..writeByte(6)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
