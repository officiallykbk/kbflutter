import 'dart:convert'; // For jsonEncode and jsonDecode
import 'package:hive/hive.dart';

part 'offline_change.g.dart';

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

@HiveType(typeId: 1)
class OfflineChange extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final ChangeOperation operation;

  @HiveField(2)
  final String? jobId;

  @HiveField(3)
  final String? jobData;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final String? fieldChanged;

  @HiveField(6)
  final String? oldValue;

  @HiveField(7)
  final String? newValue;

  @HiveField(8)
  final String? changedBy;

  OfflineChange({
    required this.id,
    required this.operation,
    this.jobId,
    this.jobData,
    required this.timestamp,
    this.fieldChanged,
    this.oldValue,
    this.newValue,
    this.changedBy,
  });

  Map<String, dynamic>? get jobDataAsMap {
    if (jobData == null) return null;
    return jsonDecode(jobData!) as Map<String, dynamic>;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operation': operation.toString(),
      'job_id': jobId,
      'job_data': jobData,
      'timestamp': timestamp.toIso8601String(),
      'field_changed': fieldChanged,
      'old_value': oldValue,
      'new_value': newValue,
      'changed_by': changedBy,
    };
  }
}
