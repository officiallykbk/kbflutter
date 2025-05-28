class JobHistoryEntry {
  final String? id; // Primary key from Supabase
  final String? jobId; // Foreign key to cargo_jobs.id
  final String? fieldChanged; // Renamed from 'field'
  final String? oldValue;
  final String? newValue;
  final String? changedAt; // DateTime from Supabase, stored as String
  final String? changedBy; // User ID (UUID string)

  JobHistoryEntry({
    this.id,
    this.jobId,
    this.fieldChanged,
    this.oldValue,
    this.newValue,
    this.changedAt,
    this.changedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id, // Usually not sent for creation
      'job_id': jobId,
      'field_changed': fieldChanged,
      'old_value': oldValue,
      'new_value': newValue,
      'changed_at': changedAt, // Supabase usually handles this
      'changed_by': changedBy, // Supabase might handle this based on auth
    };
  }

  factory JobHistoryEntry.fromJson(Map<String, dynamic> json) {
    return JobHistoryEntry(
      id: json['id'] as String?,
      jobId: json['job_id'] as String?,
      fieldChanged: json['field_changed'] as String?,
      oldValue: json['old_value'] as String?,
      newValue: json['new_value'] as String?,
      changedAt: json['changed_at'] as String?,
      changedBy: json['changed_by'] as String?,
    );
  }
}
