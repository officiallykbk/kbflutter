import 'package:bizorganizer/main.dart'; // Assuming 'supabase' client is available from here
import 'package:bizorganizer/models/cargo_job.dart'; 
import 'package:bizorganizer/models/job_history_entry.dart'; // Import for JobHistoryEntry
import 'package:bizorganizer/models/status_constants.dart'; // Task 1: Import Status Constants
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

      _completedJobs = jobsData.where((job) => job['delivery_status']?.toString().toLowerCase() == deliveryStatusToString(DeliveryStatus.Completed).toLowerCase()).toList();
      _pendingJobs = jobsData.where((job) => 
        job['delivery_status']?.toString().toLowerCase() == deliveryStatusToString(DeliveryStatus.Pending).toLowerCase() || 
        job['delivery_status']?.toString().toLowerCase() == deliveryStatusToString(DeliveryStatus.InProgress).toLowerCase()
      ).toList();
      _cancelledJobs = jobsData.where((job) => 
        job['delivery_status']?.toString().toLowerCase() == deliveryStatusToString(DeliveryStatus.Cancelled).toLowerCase() ||
        job['delivery_status']?.toString().toLowerCase() == 'refunded' // Assuming 'refunded' delivery is a type of cancellation
      ).toList();
      _onHoldJobs = jobsData.where((job) => job['delivery_status']?.toString().toLowerCase() == deliveryStatusToString(DeliveryStatus.Onhold).toLowerCase()).toList();
      _rejectedJobs = jobsData.where((job) => job['delivery_status']?.toString().toLowerCase() == deliveryStatusToString(DeliveryStatus.Rejected).toLowerCase()).toList();
      // Note: 'Overdue' and 'Scheduled' for delivery_status might need specific handling if they are primary statuses from DB
      // For now, they are handled by effectiveDeliveryStatus or directly if set.

      _paidJobs = jobsData.where((job) => job['payment_status']?.toString().toLowerCase() == paymentStatusToString(PaymentStatus.Paid).toLowerCase()).toList();
      _pendingPaymentJobs = jobsData.where((job) => job['payment_status']?.toString().toLowerCase() == paymentStatusToString(PaymentStatus.Pending).toLowerCase()).toList();
      _overduePaymentJobs = jobsData.where((job) => job['payment_status']?.toString().toLowerCase() == paymentStatusToString(PaymentStatus.Overdue).toLowerCase()).toList();
      // Note: 'Refunded' and 'Cancelled' for payment_status
      // _cancelledPaymentJobs = jobsData.where((job) => job['payment_status']?.toString().toLowerCase() == paymentStatusToString(PaymentStatus.Cancelled).toLowerCase()).toList();


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

  Future<void> editJob(int jobId, CargoJob updatedJobData) async { // Renamed for clarity
    try {
      final currentJobSnapshot = await _supabase.from('cargo_jobs').select().eq('id', jobId).single();
      final currentJob = CargoJob.fromJson(currentJobSnapshot);
      final userId = _supabase.auth.currentUser?.id ?? 'system_edit';

      // Prepare the data for update
      Map<String, dynamic> updatePayload = updatedJobData.toJson();

      // Task 3.2: If delivery status is being set to Cancelled, also set payment status to Cancelled
      if (updatedJobData.deliveryStatus == deliveryStatusToString(DeliveryStatus.Cancelled)) {
        updatePayload['payment_status'] = paymentStatusToString(PaymentStatus.Cancelled);
      }
      
      await _supabase.from('cargo_jobs').update(updatePayload).eq('id', jobId);
      
      // Log changes to history
      // Compare currentJob (before update) with updatedJobData (what was intended for update)
      // and updatePayload (what was actually sent, including auto payment cancellation)
      
      final fieldsToCompare = {
        'shipper_name': {'old': currentJob.shipperName, 'new': updatedJobData.shipperName},
        'payment_status': {'old': currentJob.paymentStatus, 'new': updatePayload['payment_status']}, // Compare with actual payload
        'delivery_status': {'old': currentJob.deliveryStatus, 'new': updatedJobData.deliveryStatus},
        'pickup_location': {'old': currentJob.pickupLocation, 'new': updatedJobData.pickupLocation},
        'dropoff_location': {'old': currentJob.dropoffLocation, 'new': updatedJobData.dropoffLocation},
        'pickup_date': {'old': currentJob.pickupDate?.toIso8601String(), 'new': updatedJobData.pickupDate?.toIso8601String()},
        'estimated_delivery_date': {'old': currentJob.estimatedDeliveryDate?.toIso8601String(), 'new': updatedJobData.estimatedDeliveryDate?.toIso8601String()},
        'actual_delivery_date': {'old': currentJob.actualDeliveryDate?.toIso8601String(), 'new': updatedJobData.actualDeliveryDate?.toIso8601String()},
        'agreed_price': {'old': currentJob.agreedPrice?.toString(), 'new': updatedJobData.agreedPrice?.toString()},
        'notes': {'old': currentJob.notes, 'new': updatedJobData.notes},
        'receipt_url': {'old': currentJob.receiptUrl, 'new': updatedJobData.receiptUrl},
      };

      for (var field in fieldsToCompare.entries) {
        String oldValue = field.value['old'] ?? '';
        String newValue = field.value['new'] ?? '';
        if (oldValue != newValue) {
          await addJobHistoryRecord(jobId, field.key, oldValue, newValue, userId);
        }
      }

      await fetchJobsData();
      print('Job updated successfully');
    } catch (e) {
      print('Error updating job: $e');
    }
  }

  Future<void> updateJobDeliveryStatus(int jobId, String newDeliveryStatus) async { // oldDeliveryStatus removed from params
    try {
      final currentJobData = await _supabase.from('cargo_jobs').select('delivery_status, payment_status').eq('id', jobId).single();
      final oldDeliveryStatus = currentJobData['delivery_status'] as String? ?? deliveryStatusToString(DeliveryStatus.Pending);
      final String currentPaymentStatus = currentJobData['payment_status'] as String? ?? paymentStatusToString(PaymentStatus.Pending);
      final userId = _supabase.auth.currentUser?.id ?? 'system_status_change';

      Map<String, dynamic> updatePayload = {'delivery_status': newDeliveryStatus};

      // Task 2.2: If new delivery status is Cancelled, also set payment status to Cancelled
      if (newDeliveryStatus == deliveryStatusToString(DeliveryStatus.Cancelled)) {
        if (currentPaymentStatus != paymentStatusToString(PaymentStatus.Cancelled)) {
          updatePayload['payment_status'] = paymentStatusToString(PaymentStatus.Cancelled);
        }
      }

      await _supabase.from('cargo_jobs').update(updatePayload).eq('id', jobId);
      
      // Log delivery_status change
      if (oldDeliveryStatus != newDeliveryStatus) {
        await addJobHistoryRecord(jobId, 'delivery_status', oldDeliveryStatus, newDeliveryStatus, userId);
      }

      // Log payment_status change if it was auto-updated
      if (updatePayload.containsKey('payment_status') && currentPaymentStatus != updatePayload['payment_status']) {
         await addJobHistoryRecord(
            jobId,
            'payment_status',
            currentPaymentStatus, // This is the oldPaymentStatus before this specific operation
            updatePayload['payment_status'] as String,
            userId // or a more specific changedBy like 'system_auto_cancel_from_delivery'
          );
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
      final userId = _supabase.auth.currentUser?.id ?? 'system_status_change';

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

  Future<List<JobHistoryEntry>> fetchJobHistory(int jobId) async {
    try {
      final response = await _supabase
          .from('job_history')
          .select()
          .eq('job_id', jobId)
          .order('changed_at', ascending: false); 

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => JobHistoryEntry.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error fetching job history for job $jobId: $e');
      return []; 
    }
  }

  Future<void> addJobHistoryRecord(int jobId, String fieldChanged, String oldValue, String newValue, String changedBy) async {
    try {
      final historyEntry = JobHistoryEntry(
        jobId: jobId,
        fieldChanged: fieldChanged,
        oldValue: oldValue,
        newValue: newValue,
        changedAt: DateTime.now().toIso8601String(), 
        changedBy: changedBy,
      );
      await _supabase.from('job_history').insert(historyEntry.toJson());
      print('Job history entry added successfully for job $jobId: $fieldChanged from "$oldValue" to "$newValue" by $changedBy');
    } catch (e) {
      print('Error adding job history entry for job $jobId: $e');
    }
  }
}
