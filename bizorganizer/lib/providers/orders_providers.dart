import 'package:bizorganizer/models/cargo_job.dart';
import 'package:bizorganizer/models/job_history_entry.dart';
import 'package:bizorganizer/models/status_constants.dart';
import 'package:bizorganizer/providers/loading_provider.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Added connectivity_plus
import 'package:bizorganizer/services/database_helper.dart'; // Added DatabaseHelper

class CargoJobProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final LoadingProvider _loadingProvider;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance; // Initialize DatabaseHelper

  CargoJobProvider(this._loadingProvider);

  String? _image;
  bool isDataFromCache = false; // Added isDataFromCache field
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _completedJobs = []; // Will filter for Delivered
  List<Map<String, dynamic>> _pendingJobs =
      []; // Will include Scheduled, InProgress
  List<Map<String, dynamic>> _cancelledJobs = [];
  List<Map<String, dynamic>> _delayedJobs =
      []; // For jobs explicitly marked as Delayed or calculated as such

  List<Map<String, dynamic>> _paidJobs = [];
  List<Map<String, dynamic>> _pendingPaymentJobs = [];
  List<Map<String, dynamic>> _overduePaymentJobs = []; // For payment status

  String? get image => _image;
  List<Map<String, dynamic>> get jobs => _jobs;
  List<Map<String, dynamic>> get completedJobs =>
      _completedJobs; // Getter for Delivered jobs
  List<Map<String, dynamic>> get pendingJobs => _pendingJobs;
  List<Map<String, dynamic>> get cancelledJobs => _cancelledJobs;
  List<Map<String, dynamic>> get delayedJobs =>
      _delayedJobs; // Getter for Delayed jobs

  List<Map<String, dynamic>> get paidJobs => _paidJobs;
  List<Map<String, dynamic>> get pendingPayments => _pendingPaymentJobs;
  List<Map<String, dynamic>> get overduePayments => _overduePaymentJobs;

  Future<void> fetchJobsData() async {
    _loadingProvider.setLoading(true);
    final connectivity = Connectivity();
    try {
      final connectivityResult = await connectivity.checkConnectivity();
      List<Map<String, dynamic>> jobsDataToProcess = [];

      if (connectivityResult != ConnectivityResult.none) {
        // Online: Fetch from Supabase and cache
        print('Fetching jobs from Supabase (Online)');
        final response = await _supabase
            .from('cargo_jobs')
            .select()
            .order('created_at', ascending: false);

        // Supabase response is List<dynamic>, needs casting.
        // Each item in the list is already a Map<String, dynamic>.
        final rawJobsData = List<Map<String, dynamic>>.from(response as List);
        
        // Convert to List<CargoJob> for saving
        List<CargoJob> cargoJobs = rawJobsData.map((jobMap) => CargoJob.fromJson(jobMap)).toList();
        await _dbHelper.batchInsertJobs(cargoJobs);
        print('Jobs cached to local DB');
        
        jobsDataToProcess = rawJobsData; // Use raw data from Supabase for current session
        isDataFromCache = false; // Set for online case

      } else {
        // Offline: Load from local DB
        print('Fetching jobs from local DB (Offline)');
        List<CargoJob> cachedCargoJobs = await _dbHelper.getAllJobs();
        isDataFromCache = true; // Set for offline case
        // Convert List<CargoJob> to List<Map<String, dynamic>> for existing logic
        // Ensure CargoJob.toJson() returns keys compatible with filtering logic (snake_case)
        jobsDataToProcess = cachedCargoJobs.map((cargoJob) {
          // Manually construct map to ensure all necessary fields for UI/filtering are present
          // and keys are snake_case as expected by filtering logic.
          return {
            'id': cargoJob.id,
            'shipper_name': cargoJob.shipperName,
            'payment_status': cargoJob.paymentStatus,
            'delivery_status': cargoJob.deliveryStatus,
            'pickup_location': cargoJob.pickupLocation,
            'dropoff_location': cargoJob.dropoffLocation,
            'pickup_date': cargoJob.pickupDate?.toIso8601String(),
            'estimated_delivery_date': cargoJob.estimatedDeliveryDate?.toIso8601String(),
            'actual_delivery_date': cargoJob.actualDeliveryDate?.toIso8601String(),
            'agreed_price': cargoJob.agreedPrice,
            'notes': cargoJob.notes,
            'created_by': cargoJob.createdBy,
            'receipt_url': cargoJob.receiptUrl,
            'created_at': cargoJob.createdAt?.toIso8601String(),
            'updated_at': cargoJob.updatedAt?.toIso8601String(),
          };
        }).toList();
        print('Loaded ${cachedCargoJobs.length} jobs from local DB');
      }

      _jobs = jobsDataToProcess;

      // Filter based on Delivery Status
      _completedJobs = _jobs.where((job) => job['delivery_status']?.toString().toLowerCase() == deliveryStatusToString(DeliveryStatus.Delivered).toLowerCase()).toList();
      _pendingJobs = _jobs.where((job) => job['delivery_status']?.toString().toLowerCase() == deliveryStatusToString(DeliveryStatus.Scheduled).toLowerCase()).toList();
      _cancelledJobs = _jobs.where((job) => job['delivery_status']?.toString().toLowerCase() == deliveryStatusToString(DeliveryStatus.Cancelled).toLowerCase()).toList();
      _delayedJobs = _jobs.where((job) => job['delivery_status']?.toString().toLowerCase() == deliveryStatusToString(DeliveryStatus.Delayed).toLowerCase()).toList();

      // Filter based on Payment Status
      _paidJobs = _jobs.where((job) => job['payment_status']?.toString().toLowerCase() == paymentStatusToString(PaymentStatus.Paid).toLowerCase()).toList();
      _pendingPaymentJobs = _jobs.where((job) => job['payment_status']?.toString().toLowerCase() == paymentStatusToString(PaymentStatus.Pending).toLowerCase()).toList();
      
      notifyListeners();

    } catch (e) {
      print('Error in fetchJobsData: $e');
      // Consider how to inform UI about error, e.g., setting an error state.
      // If offline and DB is empty, _jobs will be empty, UI should handle this.
    } finally {
      _loadingProvider.setLoading(false);
    }
  }

  Future<void> addJob(CargoJob job) async {
    try {
      await _supabase.from('cargo_jobs').insert(job.toJson());
      await fetchJobsData();
    } catch (e) {
      print('Error adding job: $e');
    }
  }

  Future<void> removeJob(String jobId) async {
    try {
      await _supabase.from('cargo_jobs').delete().eq('id', jobId);
      await fetchJobsData();
      print('Job removed successfully');
    } catch (e) {
      print('Error removing job: $e');
    }
  }

  // Future<void> editJob(String jobId, CargoJob updatedJobData) async {
  //   try {
  //     final currentJobSnapshot =
  //         await _supabase.from('cargo_jobs').select().eq('id', jobId).single();
  //     final currentJob = CargoJob.fromJson(currentJobSnapshot);
  //     final userId = _supabase.auth.currentUser?.id ?? 'system_edit';

  //     Map<String, dynamic> updatePayload = updatedJobData.toJson();

  //     // If delivery status is being set to Cancelled, also set payment status to Refunded
  //     if (updatedJobData.deliveryStatus ==
  //         deliveryStatusToString(DeliveryStatus.Cancelled)) {
  //       updatePayload['payment_status'] =
  //           paymentStatusToString(PaymentStatus.Refunded);
  //     }

  //     await _supabase.from('cargo_jobs').update(updatePayload).eq('id', jobId);

  //     final fieldsToCompare = {
  //       'shipper_name': {
  //         'old': currentJob.shipperName,
  //         'new': updatedJobData.shipperName
  //       },
  //       'payment_status': {
  //         'old': currentJob.paymentStatus,
  //         'new': updatePayload['payment_status'] // Use the value from updatePayload
  //       },
  //       'delivery_status': {
  //         'old': currentJob.deliveryStatus,
  //         'new': updatedJobData.deliveryStatus
  //       },
  //       'pickup_location': {
  //         'old': currentJob.pickupLocation,
  //         'new': updatedJobData.pickupLocation
  //       },
  //       'dropoff_location': {
  //         'old': currentJob.dropoffLocation,
  //         'new': updatedJobData.dropoffLocation
  //       },
  //       'pickup_date': {
  //         'old': currentJob.pickupDate?.toIso8601String(),
  //         'new': updatedJobData.pickupDate?.toIso8601String()
  //       },
  //       'estimated_delivery_date': {
  //         'old': currentJob.estimatedDeliveryDate?.toIso8601String(),
  //         'new': updatedJobData.estimatedDeliveryDate?.toIso8601String()
  //       },
  //       'actual_delivery_date': {
  //         'old': currentJob.actualDeliveryDate?.toIso8601String(),
  //         'new': updatedJobData.actualDeliveryDate?.toIso8601String()
  //       },
  //       'agreed_price': {
  //         'old': currentJob.agreedPrice?.toString(),
  //         'new': updatedJobData.agreedPrice?.toString()
  //       },
  //       'notes': {'old': currentJob.notes, 'new': updatedJobData.notes},
  //       'receipt_url': {
  //         'old': currentJob.receiptUrl,
  //         'new': updatedJobData.receiptUrl
  //       },
  //     };

  //     for (var field in fieldsToCompare.entries) {
  //       String oldValue = field.value['old'] ?? '';
  //       String newValue = field.value['new'] ?? '';
  //       if (oldValue != newValue) {
  //         await addJobHistoryRecord(
  //             jobId, field.key, oldValue, newValue, userId);
  //       }
  //     }

  //     await fetchJobsData();
  //     print('Job updated successfully');
  //   } catch (e) {
  //     print('Error updating job: $e');
  //   }
  // }

  Future<void> updateJobDeliveryStatus(
      String jobId, String newDeliveryStatus) async {
    try {
      final currentJobData = await _supabase
          .from('cargo_jobs')
          .select('delivery_status, payment_status')
          .eq('id', jobId)
          .single();
      final oldDeliveryStatus = currentJobData['delivery_status'] as String? ??
          deliveryStatusToString(DeliveryStatus.Scheduled); // Default if null
      final String currentPaymentStatus =
          currentJobData['payment_status'] as String? ??
              paymentStatusToString(PaymentStatus.Pending);
      final userId = _supabase.auth.currentUser?.id ?? 'system_status_change';

      Map<String, dynamic> updatePayload = {
        'delivery_status': newDeliveryStatus
      };

      if (newDeliveryStatus ==
          deliveryStatusToString(DeliveryStatus.Cancelled)) {
        if (currentPaymentStatus !=
            paymentStatusToString(PaymentStatus.Refunded)) {
          updatePayload['payment_status'] =
              paymentStatusToString(PaymentStatus.Refunded);
        }
      }

      await _supabase.from('cargo_jobs').update(updatePayload).eq('id', jobId);

      if (oldDeliveryStatus != newDeliveryStatus) {
        await addJobHistoryRecord(jobId, 'delivery_status', oldDeliveryStatus,
            newDeliveryStatus, userId);
      }

      if (updatePayload.containsKey('payment_status') &&
          currentPaymentStatus != updatePayload['payment_status']) {
        await addJobHistoryRecord(jobId, 'payment_status', currentPaymentStatus,
            updatePayload['payment_status'] as String, userId);
      }

      await fetchJobsData();
      print('Job delivery status updated successfully for job $jobId');
    } catch (e) {
      print('Error changing job delivery_status: $e');
    }
  }

  Future<void> updateJobPaymentStatus(String jobId, String newStatus) async {
    try {
      final currentJobData =
          await _supabase.from('cargo_jobs').select().eq('id', jobId).single();
      final oldStatus = currentJobData['payment_status'] as String;
      final userId = _supabase.auth.currentUser?.id ?? 'system_status_change';

      await _supabase
          .from('cargo_jobs')
          .update({'payment_status': newStatus}).eq('id', jobId);

      if (oldStatus != newStatus) {
        await addJobHistoryRecord(
            jobId, 'payment_status', oldStatus, newStatus, userId);
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

  Future<List<JobHistoryEntry>> fetchJobHistory(String jobId) async {
    try {
      final response = await _supabase
          .from('job_history')
          .select()
          .eq('job_id', jobId)
          .order('changed_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => JobHistoryEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching job history for job $jobId: $e');
      return [];
    }
  }

  Future<void> addJobHistoryRecord(String jobId, String fieldChanged,
      String oldValue, String newValue, String changedBy) async {
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
      print(
          'Job history entry added successfully for job $jobId: $fieldChanged from "$oldValue" to "$newValue" by $changedBy');
    } catch (e) {
      print('Error adding job history entry for job $jobId: $e');
    }
  }

  Future<List<String>> fetchUniqueCustomerNames() async {
    try {
      final response =
          await _supabase.from('cargo_jobs').select('shipper_name');

      // The response is directly a List<Map<String, dynamic>> if successful, or can throw PostgrestException
      // Supabase Dart client typically throws an error on failure, which is caught by the catch block.
      // If response is null (which shouldn't happen for .select() if no error is thrown),
      // or if it's not a list (also unlikely for .select()), we handle it.

      if (response is List) {
        final Set<String> uniqueNames = {};
        for (var item in response) {
          if (item is Map<String, dynamic> && item['shipper_name'] != null) {
            uniqueNames.add(item['shipper_name'] as String);
          }
        }
        return uniqueNames.toList();
      } else {
        // This case should ideally not be reached if Supabase client functions as expected (throws on error)
        print(
            'Error fetching unique customer names: Unexpected response format.');
        return [];
      }
    } catch (e) {
      print('Error fetching unique customer names: $e');
      return [];
    }
  }
}
