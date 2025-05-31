import 'dart:convert'; // For jsonEncode and jsonDecode
import 'package:hive/hive.dart';

enum ChangeOperation {
  create,
  update,
  delete,
}

// Adapter for ChangeOperation
class ChangeOperationAdapter extends TypeAdapter<ChangeOperation> {
  @override
  final int typeId = 2; // Assign a unique typeId for this enum adapter

  @override
  ChangeOperation read(BinaryReader reader) {
    return ChangeOperation.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, ChangeOperation obj) {
    writer.writeByte(obj.index);
  }
}

@HiveType(typeId: 1) // Conceptually, actual registration is manual
class OfflineChange extends HiveObject {
  @HiveField(0)
  String id; // Unique ID for the change itself

  @HiveField(1)
  ChangeOperation operation;

  @HiveField(2)
  String? jobId; // ID of the CargoJob being affected

  @HiveField(3)
  String? jobData; // CargoJob data as a JSON string for create/update

  @HiveField(4)
  DateTime timestamp;

  OfflineChange({
    required this.id,
    required this.operation,
    this.jobId,
    this.jobData,
    required this.timestamp,
  });

  Map<String, dynamic>? get jobDataAsMap {
    if (jobData == null) return null;
    return jsonDecode(jobData!) as Map<String, dynamic>;
  }
}

class OfflineChangeAdapter extends TypeAdapter<OfflineChange> {
  @override
  final int typeId = 1; // Matches the conceptual @HiveType typeId

  @override
  OfflineChange read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineChange(
      id: fields[0] as String,
      operation: fields[1] as ChangeOperation, // Assumes ChangeOperationAdapter is registered
      jobId: fields[2] as String?,
      jobData: fields[3] as String?, // Stored as JSON string
      timestamp: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineChange obj) {
    writer
      ..writeByte(5) // Number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.operation) // Assumes ChangeOperationAdapter is registered
      ..writeByte(2)
      ..write(obj.jobId)
      ..writeByte(3)
      ..write(obj.jobData) // jobData is already a JSON string via constructor or setter
      ..writeByte(4)
      ..write(obj.timestamp);
  }
}
