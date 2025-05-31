import 'dart:async'; // For Timer
import 'dart:convert'; // For JSON encoding/decoding
import 'package:shared_preferences/shared_preferences.dart'; // For local caching
import 'package:bizorganizer/models/cargo_job.dart';
import 'package:bizorganizer/models/job_history_entry.dart';
import 'package:bizorganizer/models/status_constants.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CargoJobProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _jobsCacheKey = 'cached_job_data';

  Timer? _reconnectionTimer;

  String? _image;
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _completedJobs = [];
  List<Map<String, dynamic>> _pendingJobs = [];
  List<Map<String, dynamic>> _cancelledJobs = [];
  List<Map<String, dynamic>> _delayedJobs = [];

  List<Map<String, dynamic>> _paidJobs = [];
  List<Map<String, dynamic>> _pendingPaymentJobs = [];
  List<Map<String, dynamic>> _overduePaymentJobs = [];

  // Flag to indicate if data is from cache
  bool _isDataFromCache = false;
  bool get isDataFromCache => _isDataFromCache;

  // Flag to indicate perceived network status
  bool _isNetworkOffline = false;
  bool get isNetworkOffline => _isNetworkOffline;

  String? get image => _image;
  List<Map<String, dynamic>> get jobs => _jobs;
  List<Map<String, dynamic>> get completedJobs => _completedJobs;
  List<Map<String, dynamic>> get pendingJobs => _pendingJobs;
  List<Map<String, dynamic>> get cancelledJobs => _cancelledJobs;
  List<Map<String, dynamic>> get delayedJobs => _delayedJobs;

  List<Map<String, dynamic>> get paidJobs => _paidJobs;
  List<Map<String, dynamic>> get pendingPayments => _pendingPaymentJobs;
  List<Map<String, dynamic>> get overduePayments => _overduePaymentJobs;

  void _processAndSetJobsData(List<Map<String, dynamic>> jobsData, {bool fromCache = false}) {
    _jobs = jobsData;
    _isDataFromCache = fromCache; // Set the flag

    // Filter based on Delivery Status using new enum values
    _completedJobs = jobsData
        .where((job) =>
            job['delivery_status']?.toString().toLowerCase() ==
            deliveryStatusToString(DeliveryStatus.Delivered).toLowerCase())
        .toList();
    _pendingJobs = jobsData.where((job) {
      final status = job['delivery_status']?.toString().toLowerCase();
      return status ==
          deliveryStatusToString(DeliveryStatus.Scheduled).toLowerCase();
    }).toList();
    _cancelledJobs = jobsData
        .where((job) =>
            job['delivery_status']?.toString().toLowerCase() ==
            deliveryStatusToString(DeliveryStatus.Cancelled).toLowerCase())
        .toList();
    _delayedJobs = jobsData
        .where((job) =>
            job['delivery_status']?.toString().toLowerCase() ==
            deliveryStatusToString(DeliveryStatus.Delayed).toLowerCase())
        .toList();

    // Payment Status
    _paidJobs = jobsData
        .where((job) =>
            job['payment_status']?.toString().toLowerCase() ==
            paymentStatusToString(PaymentStatus.Paid).toLowerCase())
        .toList();
    _pendingPaymentJobs = jobsData
        .where((job) =>
            job['payment_status']?.toString().toLowerCase() ==
            paymentStatusToString(PaymentStatus.Pending).toLowerCase())
        .toList();

    notifyListeners();
  }

  Future<void> _saveJobsToCache(List<Map<String, dynamic>> jobsData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(jobsData);
      await prefs.setString(_jobsCacheKey, jsonString);
      print('Job data saved to cache.');
    } catch (e) {
      print('Error saving jobs to cache: $e');
    }
  }

  Future<bool> loadJobsFromCache() async {
    print('Attempting to load jobs from cache...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_jobsCacheKey);
      if (jsonString != null) {
        final List<dynamic> decodedJson = jsonDecode(jsonString) as List<dynamic>;
        final List<Map<String, dynamic>> jobsData = decodedJson.cast<Map<String, dynamic>>();
        _processAndSetJobsData(jobsData, fromCache: true);
        print('Job data loaded from cache.');
        return true;
      } else {
        print('No job data found in cache.');
        _isDataFromCache = true; // No data, but we tried cache
        _processAndSetJobsData([], fromCache: true); // Ensure lists are empty and UI updates
        return false;
      }
    } catch (e) {
      print('Error loading jobs from cache: $e');
      _isDataFromCache = true; // Error, but we tried cache
      _processAndSetJobsData([], fromCache: true); // Ensure lists are empty and UI updates
      return false;
    }
  }

  Future<void> fetchJobsData() async {
    try {
      print('Fetching jobs data from Supabase...');
      final response = await _supabase
          .from('cargo_jobs')
          .select()
          .order('created_at', ascending: false);

      // If fetch is successful, network is considered online.
      _isNetworkOffline = false;
      _cancelReconnectionTimer(); // Stop timer if we successfully connected
      // Note: _isDataFromCache will be set to false by _processAndSetJobsData

      List<Map<String, dynamic>> jobsData =
          (response as List).cast<Map<String, dynamic>>();

      _processAndSetJobsData(jobsData, fromCache: false);
      await _saveJobsToCache(jobsData);

    } catch (e) {
      print('Error fetching jobs data from Supabase: $e');
      if (!_isNetworkOffline) { // Only set to true and notify if it wasn't already offline
        _isNetworkOffline = true;
        // Consider if an immediate notifyListeners() is needed here for _isNetworkOffline
        // before cache operations, if UI must react instantly to network loss
        // For now, _processAndSetJobsData called by loadJobsFromCache will notify.
      }
      _startReconnectionTimer(); // Start timer when fetch fails

      print('Attempting to load from cache as fallback...');
      bool loadedFromCache = await loadJobsFromCache();

      if (loadedFromCache) {
        print('Successfully loaded data from cache while network is offline.');
      } else {
        print('Failed to load data from cache while network is offline.');
      }
    }
  }

  void _startReconnectionTimer() {
    _reconnectionTimer?.cancel(); // Cancel any existing timer
    _reconnectionTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!_isNetworkOffline) { // Should not happen if timer is only started when offline
        timer.cancel();
        return;
      }
      print('Timer: Attempting to reconnect and fetch jobs...');
      await fetchJobsData();
      // If fetchJobsData is successful, it will set _isNetworkOffline to false
      // and call _cancelReconnectionTimer itself.
    });
    print('Reconnection timer started.');
  }

  void _cancelReconnectionTimer() {
    if (_reconnectionTimer != null && _reconnectionTimer!.isActive) {
      _reconnectionTimer!.cancel();
      _reconnectionTimer = null;
      print('Reconnection timer cancelled.');
    }
  }

  @override
  void dispose() {
    _cancelReconnectionTimer();
    super.dispose();
  }

  Future<void> addJob(CargoJob job) async {
    final jobData = job.toJson();
    print('Attempting to add job. Payload: $jobData'); // Detailed logging before insert

    try {
      final response = await _supabase.from('cargo_jobs').insert(jobData).select(); // Added .select() to get response

      // Supabase insert used to return an error within the response body with older versions or certain settings.
      // With `postgrest_flutter: ^1.0.0` and later, it typically throws a PostgrestException on failure.
      // However, checking for data in the response from .select() is a good practice if insert itself doesn't error out.
      print('Supabase insert response: $response');

      // If using .select() and no error was thrown, but response is empty or indicates an issue (less common for insert)
      if (response == null || (response is List && response.isEmpty)) {
          print('Error adding job: Supabase returned no data or empty list, indicating potential issue.');
          // Consider throwing an exception here to be caught by the UI layer
          throw Exception('Failed to add job: Supabase returned no data. Check RLS or constraints.');
      }

      await fetchJobsData(); // Refresh local cache
      print('Job added successfully and data refreshed.');
    } on PostgrestException catch (e) { // Catch specific Supabase exception
      print('Error adding job to Supabase: ${e.message}');
      print('Details: code=${e.code}, details=${e.details}, hint=${e.hint}');
      // Re-throw the exception or a custom one to notify the UI
      throw Exception('Failed to add job to Supabase: ${e.message}');
    } catch (e) { // Catch any other general errors
      print('An unexpected error occurred while adding job: $e');
      // Re-throw the exception or a custom one to notify the UI
      throw Exception('An unexpected error occurred: $e');
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

  //     // If delivery status is being set to Cancelled, also set payment status to Cancelled
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
  //         'new': updatePayload['payment_status']
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
