import 'package:bizorganizer/main.dart'; // Assuming 'supabase' client is available from here
import 'package:bizorganizer/models/cargo_job.dart'; 
import 'package:bizorganizer/models/job_history_entry.dart'; // Import for JobHistoryEntry
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CargoJobProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _image;
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _completedJobs = [];
  List<Map<String, dynamic>> _pendingJobs = [];
  List<Map<String, dynamic>> _cancelledJobs = [];
  List<Map<String, dynamic>> _onHoldJobs = [];
  List<Map<String, dynamic>> _rejectedJobs = [];
  List<Map<String, dynamic>> _paidJobs = [];
  List<Map<String, dynamic>> _pendingPaymentJobs = [];
  List<Map<String, dynamic>> _overduePaymentJobs = [];

  String? get image => _image;
  List<Map<String, dynamic>> get jobs => _jobs;
  List<Map<String, dynamic>> get completedJobs => _completedJobs;
  List<Map<String, dynamic>> get pendingJobs => _pendingJobs;
  List<Map<String, dynamic>> get cancelledJobs => _cancelledJobs;
  List<Map<String, dynamic>> get onHoldJobs => _onHoldJobs;
  List<Map<String, dynamic>> get rejectedJobs => _rejectedJobs;
  List<Map<String, dynamic>> get paidJobs => _paidJobs;
  List<Map<String, dynamic>> get pendingPayments => _pendingPaymentJobs;
  List<Map<String, dynamic>> get overduePayments => _overduePaymentJobs;

  Future<void> fetchJobsData() async {
    try {
      final response = await _supabase
          .from('cargo_jobs')
          .select()
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> jobsData = (response as List).cast<Map<String, dynamic>>();
      _jobs = jobsData;

      _completedJobs = jobsData.where((job) => job['delivery_status']?.toString().toLowerCase() == 'completed').toList();
      _pendingJobs = jobsData.where((job) => 
        job['delivery_status']?.toString().toLowerCase() == 'pending' || 
        job['delivery_status']?.toString().toLowerCase() == 'in progress'
      ).toList();
      _cancelledJobs = jobsData.where((job) => 
        job['delivery_status']?.toString().toLowerCase() == 'cancelled' ||
        job['delivery_status']?.toString().toLowerCase() == 'refunded'
      ).toList();
      _onHoldJobs = jobsData.where((job) => job['delivery_status']?.toString().toLowerCase() == 'onhold').toList();
      _rejectedJobs = jobsData.where((job) => job['delivery_status']?.toString().toLowerCase() == 'rejected').toList();

      _paidJobs = jobsData.where((job) => job['payment_status']?.toString().toLowerCase() == 'paid').toList();
      _pendingPaymentJobs = jobsData.where((job) => job['payment_status']?.toString().toLowerCase() == 'pending').toList();
      _overduePaymentJobs = jobsData.where((job) => job['payment_status']?.toString().toLowerCase() == 'overdue').toList();

      notifyListeners();
    } catch (e) {
      print('Error fetching jobs data: $e');
    }
  }

  Future<void> addJob(CargoJob job) async {
    try {
      if (job.shipperName != null && job.shipperName!.isNotEmpty) {
        await _supabase.from('customer').upsert({'clientName': job.shipperName});
      }
      await _supabase.from('cargo_jobs').insert(job.toJson());
      await fetchJobsData();
    } catch (e) {
      print('Error adding job: $e');
    }
  }

  Future<void> removeJob(int jobId) async {
    try {
      await _supabase.from('cargo_jobs').delete().eq('id', jobId);
      await fetchJobsData(); 
      print('Job removed successfully');
    } catch (e) {
      print('Error removing job: $e');
    }
  }

  Future<void> editJob(int jobId, CargoJob updatedJob) async {
    try {
      // Fetch current job to compare for history logging
      final currentJobData = await _supabase.from('cargo_jobs').select().eq('id', jobId).single();
      final currentJob = CargoJob.fromJson(currentJobData);

      await _supabase.from('cargo_jobs').update(updatedJob.toJson()).eq('id', jobId);
      
      // Log changes to history
      // This is a simplified example; a more robust solution would iterate over changed fields.
      // For now, let's assume we know which fields are editable and might change.
      // A more generic approach would compare currentJob and updatedJob field by field.

      if (currentJob.deliveryStatus != updatedJob.deliveryStatus && updatedJob.deliveryStatus != null) {
        await addJobHistoryRecord(jobId, 'delivery_status', currentJob.deliveryStatus ?? '', updatedJob.deliveryStatus!, updatedJob.createdBy ?? 'system');
      }
      if (currentJob.paymentStatus != updatedJob.paymentStatus && updatedJob.paymentStatus != null) {
         await addJobHistoryRecord(jobId, 'payment_status', currentJob.paymentStatus ?? '', updatedJob.paymentStatus!, updatedJob.createdBy ?? 'system');
      }
      if (currentJob.agreedPrice != updatedJob.agreedPrice && updatedJob.agreedPrice != null) {
         await addJobHistoryRecord(jobId, 'agreed_price', currentJob.agreedPrice?.toString() ?? '', updatedJob.agreedPrice!.toString(), updatedJob.createdBy ?? 'system');
      }
      // Add more field comparisons as needed...

      await fetchJobsData();
      print('Job updated successfully');
    } catch (e) {
      print('Error updating job: $e');
    }
  }

  Future<void> updateJobDeliveryStatus(int jobId, String newStatus) async {
    try {
      final currentJobData = await _supabase.from('cargo_jobs').select().eq('id', jobId).single();
      final oldStatus = currentJobData['delivery_status'] as String?;
      final userId = _supabase.auth.currentUser?.id ?? 'system'; // Get current user or default to system

      await _supabase.from('cargo_jobs').update({'delivery_status': newStatus}).eq('id', jobId);
      
      if (oldStatus != newStatus) {
        await addJobHistoryRecord(jobId, 'delivery_status', oldStatus ?? '', newStatus, userId);
      }
      await fetchJobsData();
      print('Job delivery status updated successfully for job $jobId');
    } catch (e) {
      print('Error changing job delivery_status: $e');
    }
  }

  Future<void> updateJobPaymentStatus(int jobId, String newStatus) async {
    try {
      final currentJobData = await _supabase.from('cargo_jobs').select().eq('id', jobId).single();
      final oldStatus = currentJobData['payment_status'] as String?;
      final userId = _supabase.auth.currentUser?.id ?? 'system';

      await _supabase.from('cargo_jobs').update({'payment_status': newStatus}).eq('id', jobId);

      if (oldStatus != newStatus) {
         await addJobHistoryRecord(jobId, 'payment_status', oldStatus ?? '', newStatus, userId);
      }
      await fetchJobsData();
      print('Job payment status updated successfully for job $jobId');
    } catch (e) {
      print('Error changing job payment_status: $e');
    }
  }

  void addImage(String imageRef) {
    _image = imageRef;
    notifyListeners();
  }

  // New method to fetch job history
  Future<List<JobHistoryEntry>> fetchJobHistory(int jobId) async {
    try {
      final response = await _supabase
          .from('job_history')
          .select()
          .eq('job_id', jobId)
          .order('changed_at', ascending: false); // Newest first

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => JobHistoryEntry.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error fetching job history for job $jobId: $e');
      return []; // Return empty list on error
    }
  }

  // New simpler method to add a job history record
  Future<void> addJobHistoryRecord(int jobId, String fieldChanged, String oldValue, String newValue, String changedBy) async {
    try {
      final historyEntry = JobHistoryEntry(
        jobId: jobId,
        fieldChanged: fieldChanged,
        oldValue: oldValue,
        newValue: newValue,
        changedAt: DateTime.now().toIso8601String(), // Set current time
        changedBy: changedBy,
      );
      await _supabase.from('job_history').insert(historyEntry.toJson());
      print('Job history entry added successfully for job $jobId: $fieldChanged');
    } catch (e) {
      print('Error adding job history entry for job $jobId: $e');
    }
  }
}
