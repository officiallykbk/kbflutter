// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_change.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineChangeAdapter extends TypeAdapter<OfflineChange> {
  @override
  final int typeId = 1;

  @override
  OfflineChange read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineChange(
      id: fields[0] as String,
      operation: fields[1] as ChangeOperation,
      jobId: fields[2] as String?,
      jobData: fields[3] as String?,
      timestamp: fields[4] as DateTime,
      fieldChanged: fields[5] as String?,
      oldValue: fields[6] as String?,
      newValue: fields[7] as String?,
      changedBy: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineChange obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.operation)
      ..writeByte(2)
      ..write(obj.jobId)
      ..writeByte(3)
      ..write(obj.jobData)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.fieldChanged)
      ..writeByte(6)
      ..write(obj.oldValue)
      ..writeByte(7)
      ..write(obj.newValue)
      ..writeByte(8)
      ..write(obj.changedBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineChangeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
