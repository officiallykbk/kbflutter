import 'package:bizorganizer/main.dart'; // Assuming 'supabase' client is available from here
import 'package:bizorganizer/models/cargo_job.dart'; 
import 'package:bizorganizer/models/job_history_entry.dart';
import 'package:bizorganizer/models/status_constants.dart'; 
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CargoJobProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _image;
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _completedJobs = []; // Will filter for Delivered
  List<Map<String, dynamic>> _pendingJobs = [];   // Will include Scheduled, InProgress
  List<Map<String, dynamic>> _cancelledJobs = [];
  List<Map<String, dynamic>> _onHoldJobs = [];    // This is an explicit status from DB if used
  List<Map<String, dynamic>> _rejectedJobs = [];  // This is an explicit status from DB if used
  List<Map<String, dynamic>> _delayedJobs = [];   // For jobs explicitly marked as Delayed or calculated as such

  List<Map<String, dynamic>> _paidJobs = [];
  List<Map<String, dynamic>> _pendingPaymentJobs = [];
  List<Map<String, dynamic>> _overduePaymentJobs = []; // For payment status

  String? get image => _image;
  List<Map<String, dynamic>> get jobs => _jobs;
  List<Map<String, dynamic>> get completedJobs => _completedJobs; // Getter for Delivered jobs
  List<Map<String, dynamic>> get pendingJobs => _pendingJobs;
  List<Map<String, dynamic>> get cancelledJobs => _cancelledJobs;
  List<Map<String, dynamic>> get onHoldJobs => _onHoldJobs; // Keep for explicit 'Onhold' if used
  List<Map<String, dynamic>> get rejectedJobs => _rejectedJobs; // Keep for explicit 'Rejected' if used
  List<Map<String, dynamic>> get delayedJobs => _delayedJobs; // Getter for Delayed jobs

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

      // Filter based on Delivery Status using new enum values
      _completedJobs = jobsData.where((job) => job['delivery_status']?.toString().toLowerCase() == deliveryStatusToString(DeliveryStatus.Delivered).toLowerCase()).toList();
      
      _pendingJobs = jobsData.where((job) {
        final status = job['delivery_status']?.toString().toLowerCase();
        return status == deliveryStatusToString(DeliveryStatus.Scheduled).toLowerCase() || 
               status == deliveryStatusToString(DeliveryStatus.InProgress).toLowerCase();
      }).toList();

      _cancelledJobs = jobsData.where((job) => job['delivery_status']?.toString().toLowerCase() == deliveryStatusToString(DeliveryStatus.Cancelled).toLowerCase()).toList();
      
      _delayedJobs = jobsData.where((job) => job['delivery_status']?.toString().toLowerCase() == deliveryStatusToString(DeliveryStatus.Delayed).toLowerCase()).toList();

      // Explicit statuses from DB if they exist and are used (Onhold, Rejected were from previous broader enum)
      // If these are not actual DB statuses, these lists might often be empty or could be removed.
      // For now, assuming they might be set manually if those enum values are used.
      _onHoldJobs = jobsData.where((job) {
          final ds = deliveryStatusFromString(job['delivery_status']?.toString());
          return ds == DeliveryStatus.Onhold; // Assuming Onhold is a valid DeliveryStatus enum value if needed
      }).toList();

      _rejectedJobs = jobsData.where((job) {
          final ds = deliveryStatusFromString(job['delivery_status']?.toString());
          return ds == DeliveryStatus.Rejected; // Assuming Rejected is a valid DeliveryStatus enum value if needed
      }).toList();


      // Payment Status (remains unchanged by this task)
      _paidJobs = jobsData.where((job) => job['payment_status']?.toString().toLowerCase() == paymentStatusToString(PaymentStatus.Paid).toLowerCase()).toList();
      _pendingPaymentJobs = jobsData.where((job) => job['payment_status']?.toString().toLowerCase() == paymentStatusToString(PaymentStatus.Pending).toLowerCase()).toList();
      _overduePaymentJobs = jobsData.where((job) => job['payment_status']?.toString().toLowerCase() == paymentStatusToString(PaymentStatus.Overdue).toLowerCase()).toList();

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

  Future<void> editJob(int jobId, CargoJob updatedJobData) async { 
    try {
      final currentJobSnapshot = await _supabase.from('cargo_jobs').select().eq('id', jobId).single();
      final currentJob = CargoJob.fromJson(currentJobSnapshot);
      final userId = _supabase.auth.currentUser?.id ?? 'system_edit';

      Map<String, dynamic> updatePayload = updatedJobData.toJson();

      // If delivery status is being set to Cancelled, also set payment status to Cancelled
      if (updatedJobData.deliveryStatus == deliveryStatusToString(DeliveryStatus.Cancelled)) {
        updatePayload['payment_status'] = paymentStatusToString(PaymentStatus.Cancelled);
      }
      
      await _supabase.from('cargo_jobs').update(updatePayload).eq('id', jobId);
      
      final fieldsToCompare = {
        'shipper_name': {'old': currentJob.shipperName, 'new': updatedJobData.shipperName},
        'payment_status': {'old': currentJob.paymentStatus, 'new': updatePayload['payment_status']}, 
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

  Future<void> updateJobDeliveryStatus(int jobId, String newDeliveryStatus) async { 
    try {
      final currentJobData = await _supabase.from('cargo_jobs').select('delivery_status, payment_status').eq('id', jobId).single();
      final oldDeliveryStatus = currentJobData['delivery_status'] as String? ?? deliveryStatusToString(DeliveryStatus.Scheduled); // Default if null
      final String currentPaymentStatus = currentJobData['payment_status'] as String? ?? paymentStatusToString(PaymentStatus.Pending);
      final userId = _supabase.auth.currentUser?.id ?? 'system_status_change';

      Map<String, dynamic> updatePayload = {'delivery_status': newDeliveryStatus};

      if (newDeliveryStatus == deliveryStatusToString(DeliveryStatus.Cancelled)) {
        if (currentPaymentStatus != paymentStatusToString(PaymentStatus.Cancelled)) {
          updatePayload['payment_status'] = paymentStatusToString(PaymentStatus.Cancelled);
        }
      }

      await _supabase.from('cargo_jobs').update(updatePayload).eq('id', jobId);
      
      if (oldDeliveryStatus != newDeliveryStatus) {
        await addJobHistoryRecord(jobId, 'delivery_status', oldDeliveryStatus, newDeliveryStatus, userId);
      }

      if (updatePayload.containsKey('payment_status') && currentPaymentStatus != updatePayload['payment_status']) {
         await addJobHistoryRecord(
            jobId,
            'payment_status',
            currentPaymentStatus, 
            updatePayload['payment_status'] as String,
            userId 
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

  Future<List<String>> fetchUniqueCustomerNames() async {
    try {
      final response = await _supabase.from('customer').select('clientName');

      // The response is directly a List<Map<String, dynamic>> if successful, or can throw PostgrestException
      // Supabase Dart client typically throws an error on failure, which is caught by the catch block.
      // If response is null (which shouldn't happen for .select() if no error is thrown),
      // or if it's not a list (also unlikely for .select()), we handle it.

      if (response is List) {
        final Set<String> uniqueNames = {};
        for (var item in response) {
          if (item is Map<String, dynamic> && item['clientName'] != null) {
            uniqueNames.add(item['clientName'] as String);
          }
        }
        return uniqueNames.toList();
      } else {
        // This case should ideally not be reached if Supabase client functions as expected (throws on error)
        print('Error fetching unique customer names: Unexpected response format.');
        return [];
      }
    } catch (e) {
      print('Error fetching unique customer names: $e');
      return [];
    }
  }
}
