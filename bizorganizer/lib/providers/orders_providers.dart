import 'dart:async'; // For Timer
// import 'dart:convert'; // For JSON encoding/decoding - No longer needed for Hive with TypeAdapter
// import 'package:shared_preferences/shared_preferences.dart'; // No longer needed
import 'package:hive/hive.dart'; // Import Hive
import 'package:bizorganizer/models/cargo_job.dart';
import 'package:bizorganizer/models/job_history_entry.dart';
import 'package:bizorganizer/models/status_constants.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Import connectivity_plus
import 'package:uuid/uuid.dart'; // Import Uuid package
import 'dart:convert'; // For jsonEncode/Decode
import 'package:bizorganizer/models/offline_change.dart'; // Import OfflineChange model

class CargoJobProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Connectivity _connectivity = Connectivity(); // Add Connectivity instance
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription; // Add StreamSubscription
  static const String _jobsCacheKey = 'cargoJobsBox'; // New Hive box name
  static const String _offlineChangesBoxName = 'offlineChangesBox'; // Offline changes box
  final Uuid _uuid = Uuid(); // Uuid instance

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

  // Flag to indicate if sync process is running
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  // Flag for loading state of jobs
  bool _isLoadingJobs = false;
  bool get isLoadingJobs => _isLoadingJobs;

  // Error message for fetching jobs
  String? _fetchError;
  String? get fetchError => _fetchError;

  // Constructor
  CargoJobProvider() {
    _initializeConnectivityStatus();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> result) {
      _updateConnectionStatus(result);
    });
  }

  String? get image => _image;
  List<Map<String, dynamic>> get jobs => _jobs;
  List<Map<String, dynamic>> get completedJobs => _completedJobs;
  List<Map<String, dynamic>> get pendingJobs => _pendingJobs;
  List<Map<String, dynamic>> get cancelledJobs => _cancelledJobs;
  List<Map<String, dynamic>> get delayedJobs => _delayedJobs;

  List<Map<String, dynamic>> get paidJobs => _paidJobs;
  List<Map<String, dynamic>> get pendingPayments => _pendingPaymentJobs;
  List<Map<String, dynamic>> get overduePayments => _overduePaymentJobs;

  void _processAndSetJobsData(List<Map<String, dynamic>> jobsData,
      {bool fromCache = false}) {
    print('_processAndSetJobsData: Received ${jobsData.length} jobs. From cache: $fromCache. Notifying listeners.');
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
      final box = Hive.box<CargoJob>(_jobsCacheKey);
      final List<CargoJob> cargoJobsList = jobsData.map((json) => CargoJob.fromJson(json)).toList();
      await box.clear(); // Clear old data
      await box.addAll(cargoJobsList); // Add new data
      print('Job data saved to Hive cache.');
    } catch (e) {
      print('Error saving jobs to Hive cache: $e');
    }
  }

  Future<bool> loadJobsFromCache() async {
    print('Attempting to load jobs from Hive cache...');
    try {
      final box = Hive.box<CargoJob>(_jobsCacheKey);
      if (box.isNotEmpty) {
        final List<CargoJob> cargoJobsList = box.values.toList();
        // Convert List<CargoJob> to List<Map<String, dynamic>> for _processAndSetJobsData
        final List<Map<String, dynamic>> jobsData = cargoJobsList.map((job) => job.toJson()).toList();
        _processAndSetJobsData(jobsData, fromCache: true);
        print('Job data loaded from Hive cache.');
        return true;
      } else {
        print('No job data found in Hive cache.');
        _isDataFromCache = true; // No data, but we tried cache
        _processAndSetJobsData([], fromCache: true); // Ensure lists are empty and UI updates
        return false;
      }
    } catch (e) {
      print('Error loading jobs from Hive cache: $e');
      _isDataFromCache = true; // Error, but we tried cache
      _processAndSetJobsData([], fromCache: true); // Ensure lists are empty and UI updates
      return false;
    }
  }

  Future<void> _initializeConnectivityStatus() async {
    final List<ConnectivityResult> initialResult = await _connectivity.checkConnectivity();
    _updateConnectionStatus(initialResult);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) async { // Made async
    final bool wasOffline = _isNetworkOffline;
    if (result.contains(ConnectivityResult.none)) {
      if (!_isNetworkOffline) { // Only update and print if status actually changed
        _isNetworkOffline = true;
        print('Connectivity: Offline');
        if (_reconnectionTimer == null || !_reconnectionTimer!.isActive) {
           _startReconnectionTimer();
        }
        notifyListeners(); // Notify listeners about going offline
      }
    } else {
      if (_isNetworkOffline || wasOffline) { // If status changed or was previously offline and is now confirmed online
        _isNetworkOffline = false;
        print('Connectivity: Online');
        _cancelReconnectionTimer();
        notifyListeners(); // Notify listeners about going online

        print('Connectivity: Was offline or unsure, now confirmed online. Processing offline changes...');
        await _processOfflineChanges(); // Process queue
        // fetchJobsData will be called by _processOfflineChanges or if the queue was empty.
        // If queue processing itself calls fetchJobsData, this explicit call might be redundant
        // but ensures data is fetched if queue was empty.
        if (Hive.box<OfflineChange>(_offlineChangesBoxName).isEmpty) { // Only fetch if queue was empty, otherwise _processOfflineChanges handles it
            print('Connectivity: Offline queue is empty. Fetching data directly.');
            await fetchJobsData();
        }
      }
    }
  }

  Future<void> _processOfflineChanges() async {
    if (_isSyncing) return; // Prevent concurrent syncs

    _isSyncing = true;
    print('CargoJobProvider: Setting _isSyncing = true. Notifying listeners.');
    notifyListeners();
    // print('Starting offline changes sync...'); // Redundant with the one above

    final box = Hive.box<OfflineChange>(_offlineChangesBoxName);
    try {
      if (box.isEmpty) {
        print('Offline changes queue is empty.');
        // No changes to process, but we might still want to refresh data if we just came online.
        // This will be handled by the caller in _updateConnectionStatus or a periodic check.
        return;
      }

      final changes = List<OfflineChange>.from(box.values);
    changes.sort((a, b) => a.timestamp.compareTo(b.timestamp)); // Process in order

    print('Processing ${changes.length} offline changes...');

    for (final change in changes) {
      print('Processing change: ${change.id}, Operation: ${change.operation}, JobID: ${change.jobId}');
      bool success = false;
      try {
        switch (change.operation) {
          case ChangeOperation.create:
            if (change.jobData == null) {
              print('Error: Create operation for change ${change.id} has no jobData.');
              continue; // Skip this change
            }
            final Map<String, dynamic> jobMap = jsonDecode(change.jobData!);
            // Remove client-generated ID if it exists, Supabase will assign one
            jobMap.remove('id');
            final jobToCreate = CargoJob.fromJson(jobMap);

            // Using the online part of addJob's logic directly
            final createData = jobToCreate.toJson();
            // Remove id from createData as Supabase assigns it
            createData.remove('id');
            print('Attempting to create job (sync): ${jobToCreate.shipperName}');
            final response = await _supabase.from('cargo_jobs').insert(createData).select();
             if (response == null || (response is List && response.isEmpty)) {
                print('Error creating job (sync) ${jobToCreate.shipperName}: Supabase returned no data.');
                // Keep in queue by not setting success = true
             } else {
                print('Successfully created job (sync): ${jobToCreate.shipperName}');
                success = true;
             }
            break;
          case ChangeOperation.update:
            if (change.jobId == null || change.jobData == null) {
               print('Error: Update operation for change ${change.id} is missing jobId or jobData.');
               continue;
            }
            final Map<String, dynamic> updateData = jsonDecode(change.jobData!);
            // Ensure 'id' is not in the payload for an update, or handle as per Supabase requirements
            updateData.remove('id');
            // Use a generic update, assuming jobData contains all necessary fields for update
            // This might need to be more specific if only partial updates are desired or if specific
            // update methods (like updateJobDeliveryStatus) have extra logic (e.g., history).
            // For simplicity, a direct update:
            print('Attempting to update job (sync): ${change.jobId}');
            await _supabase.from('cargo_jobs').update(updateData).eq('id', change.jobId!);
            // Assume success for now, or add select() and check response
            success = true;
            print('Successfully updated job (sync): ${change.jobId}');
            break;
          case ChangeOperation.delete:
            if (change.jobId == null) {
              print('Error: Delete operation for change ${change.id} is missing jobId.');
              continue;
            }
            print('Attempting to delete job (sync): ${change.jobId}');
            await _supabase.from('cargo_jobs').delete().eq('id', change.jobId!);
            // Assume success for now
            success = true;
            print('Successfully deleted job (sync): ${change.jobId}');
            break;
        }

        if (success) {
          print('Change ${change.id} processed successfully. Removing from queue.');
          await box.delete(change.id);
        }
      } catch (e) {
        print('Error processing change ${change.id} (Operation: ${change.operation}): $e. Leaving in queue.');
        // Optionally, implement retry limits or specific error handling here
      }
    }

    print('Finished processing offline changes.');
    // Always refresh data from server after processing queue to ensure consistency
    await fetchJobsData();
    } finally {
      _isSyncing = false;
      print('CargoJobProvider: Setting _isSyncing = false in finally. Notifying listeners.');
      notifyListeners();
      // print('Offline changes sync finished.'); // Redundant
    }
  }

  Future<void> fetchJobsData() async {
    print('CargoJobProvider: Setting _isLoadingJobs = true. Current error: $_fetchError. Notifying listeners.');
    _isLoadingJobs = true;
    _fetchError = null; // Clear previous error
    notifyListeners();

    try {
      // If connectivity_plus says we are offline, try loading from cache first.
      if (_isNetworkOffline) {
        print('fetchJobsData: Network is reported offline by connectivity_plus. Attempting cache load.');
        bool loadedFromCache = await loadJobsFromCache();
        if (loadedFromCache) {
          print('fetchJobsData: Successfully loaded data from cache while offline.');
          _fetchError = null; // Loaded from cache, so no "fetch" error per se for this attempt.
        } else {
          print('fetchJobsData: Failed to load data from cache while offline.');
          _fetchError = 'Network offline and no cached data available.';
          _isDataFromCache = true; // Indicate that we attempted cache but it was empty or failed
          _processAndSetJobsData([], fromCache: true); // Ensure lists are empty
        }
        return;
      }

      print('Fetching jobs data from Supabase...');
      final response = await _supabase
          .from('cargo_jobs')
          .select()
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> jobsData = (response as List).cast<Map<String, dynamic>>();
      print('fetchJobsData: About to call _processAndSetJobsData with ${jobsData.length} jobs. From cache: false');
      _processAndSetJobsData(jobsData, fromCache: false);
      await _saveJobsToCache(jobsData);
      _fetchError = null; // Clear any previous error on successful fetch
      // _cancelReconnectionTimer(); // Consider if this is needed here or if connectivity handling is enough
    } catch (e) {
      print('Error fetching jobs data from Supabase: $e');
      _fetchError = 'Failed to fetch jobs: $e';
      _startReconnectionTimer(); // Keep retrying Supabase if it fails.

      print('Attempting to load from cache as fallback due to Supabase error...');
      bool loadedFromCache = await loadJobsFromCache();
      if (loadedFromCache) {
        print('Successfully loaded data from cache after Supabase error.');
        // _fetchError remains from the Supabase error, but data is available from cache.
      } else {
        print('Failed to load data from cache after Supabase error.');
        // _fetchError is already set from Supabase error.
      }
    } finally {
      print('CargoJobProvider: Setting _isLoadingJobs = false in finally. Current error: $_fetchError. Notifying listeners.');
      _isLoadingJobs = false;
      notifyListeners();
    }
  }

  void _startReconnectionTimer() {
    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      // This timer now primarily retries fetching data if Supabase was unreachable,
      // or if connectivity was lost and then regained (handled by _updateConnectionStatus calling fetchJobsData).
      // If _isNetworkOffline is true, fetchJobsData will rely on cache.
      // If _isNetworkOffline is false, it will attempt Supabase.
      print('Timer: Attempting to fetch jobs...');
      await fetchJobsData();
    });
    print('Reconnection/Retry timer started.');
  }

  void _cancelReconnectionTimer() {
    if (_reconnectionTimer != null && _reconnectionTimer!.isActive) {
      _reconnectionTimer!.cancel();
      _reconnectionTimer = null;
      print('Reconnection/Retry timer cancelled.');
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel(); // Cancel connectivity subscription
    _cancelReconnectionTimer();
    super.dispose();
  }

  Future<void> _addChangeToQueue(ChangeOperation operation, {String? jobId, CargoJob? job}) async {
    final String changeId = _uuid.v4(); // Generate ID for the change itself
    Map<String, dynamic>? jobDataMap = job?.toJson();

    // For create operations, if the job has a client-generated ID, store it with the change.
    // This client-generated ID will be part of jobDataMap.
    // It will be stripped before sending to Supabase during _processOfflineChanges.
    // The main _jobs list will be reconciled by fetchJobsData after queue processing.

    final change = OfflineChange(
      id: changeId,
      operation: operation,
      jobId: jobId ?? job?.id, // For update/delete, this is the permanent ID. For create, it might be client-generated.
      jobData: jobDataMap != null ? jsonEncode(jobDataMap) : null,
      timestamp: DateTime.now(),
    );
    final box = Hive.box<OfflineChange>(_offlineChangesBoxName);
    await box.put(change.id, change); // Use the change's own ID as the key
    print('Added change to queue: ${change.id} - Op: ${change.operation}, JobID: ${change.jobId}');
  }

  Future<void> addJob(CargoJob job) async {
    if (_isNetworkOffline) {
      // print('Network offline. Queueing job creation: ${job.shipperName}'); // Kept original, more specific one to be added
      // Use a temporary ID for optimistic update if your CargoJob model needs an ID.
      // Or ensure your UI can handle jobs that might not have a final ID yet.
      // If job.id is null, assign a temporary client-side UUID for optimistic UI updates.
      // This temporary ID will be included in the jobData of the OfflineChange.
      final String tempJobIdForOptimisticCreate = job.id ?? _uuid.v4();
      final jobForOptimisticAdd = (job.id == null)
        ? CargoJob(
            id: tempJobIdForOptimisticCreate, // Use temp ID
            shipperName: job.shipperName,
            paymentStatus: job.paymentStatus,
              deliveryStatus: job.deliveryStatus,
              pickupLocation: job.pickupLocation,
              dropoffLocation: job.dropoffLocation,
              pickupDate: job.pickupDate,
              estimatedDeliveryDate: job.estimatedDeliveryDate,
              actualDeliveryDate: job.actualDeliveryDate,
              agreedPrice: job.agreedPrice,
              notes: job.notes,
            createdBy: job.createdBy,
            receiptUrl: job.receiptUrl,
            createdAt: job.createdAt ?? DateTime.now(),
            updatedAt: DateTime.now(),
          )
        : job;


      // The job object passed to _addChangeToQueue will contain the tempJobIdForOptimisticCreate if job.id was null.
      await _addChangeToQueue(ChangeOperation.create, job: jobForOptimisticAdd);
      print('CargoJobProvider: addJob (Offline). About to call _processAndSetJobsData for optimistic update. New temp job ID: ${jobForOptimisticAdd.id}');

      // Optimistic Update using jobForOptimisticAdd (which has the temp ID if original was null)
      _jobs.insert(0, jobForOptimisticAdd.toJson());
      _processAndSetJobsData(List<Map<String, dynamic>>.from(_jobs)); // This calls notifyListeners
      await _saveJobsToCache(_jobs);
      // notifyListeners(); // Redundant: _processAndSetJobsData already called it
      return;
    }

    // Online: Proceed with Supabase call
    final jobData = job.toJson();
    print('Attempting to add job (online). Payload: $jobData');
    try {
      final response = await _supabase.from('cargo_jobs').insert(jobData).select();
      if (response == null || (response is List && response.isEmpty)) {
        throw Exception('Failed to add job: Supabase returned no data. Check RLS or constraints.');
      }
      print('CargoJobProvider: addJob (Online) successful. About to call fetchJobsData. Current _jobs count: ${_jobs.length}');
      await fetchJobsData(); // Refresh local cache from Supabase
      // print('Job added successfully online and data refreshed.'); // fetchJobsData will print its own status
    } on PostgrestException catch (e) {
      print('Error adding job to Supabase: ${e.message}');
      throw Exception('Failed to add job to Supabase: ${e.message}');
    } catch (e) {
      print('An unexpected error occurred while adding job: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<void> removeJob(String jobId) async {
    if (_isNetworkOffline) {
      // print('Network offline. Queueing job deletion: $jobId'); // Kept original
      await _addChangeToQueue(ChangeOperation.delete, jobId: jobId);
      print('CargoJobProvider: removeJob (Offline). About to call _processAndSetJobsData for optimistic update. Job ID to remove: $jobId');

      // Optimistic Update
      _jobs.removeWhere((j) => j['id'] == jobId);
      _processAndSetJobsData(List<Map<String, dynamic>>.from(_jobs)); // This calls notifyListeners
      await _saveJobsToCache(_jobs);
      // notifyListeners(); // Redundant
      return;
    }

    // Online: Proceed with Supabase call
    try {
      await _supabase.from('cargo_jobs').delete().eq('id', jobId);
      print('CargoJobProvider: removeJob (Online) successful. About to call fetchJobsData. Current _jobs count: ${_jobs.length}');
      await fetchJobsData(); // Refresh
      // print('Job removed successfully online');
    } catch (e) {
      print('Error removing job online: $e');
      throw Exception('Error removing job online: $e');
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

  Future<void> updateJobDeliveryStatus(String jobId, String newDeliveryStatus) async {
    if (_isNetworkOffline) {
      print('Network offline. Queueing delivery status update for job $jobId to $newDeliveryStatus');
      final jobIndex = _jobs.indexWhere((j) => j['id'] == jobId);
      if (jobIndex == -1) {
        print('Job not found locally for offline update: $jobId');
        return;
      }
      CargoJob jobToUpdate = CargoJob.fromJson(_jobs[jobIndex]);
      // Create a new CargoJob instance for the update queue
      CargoJob updatedJobForQueue = CargoJob(
        id: jobToUpdate.id,
        shipperName: jobToUpdate.shipperName,
        paymentStatus: (newDeliveryStatus == deliveryStatusToString(DeliveryStatus.Cancelled) && jobToUpdate.paymentStatus != paymentStatusToString(PaymentStatus.Refunded))
            ? paymentStatusToString(PaymentStatus.Refunded)
            : jobToUpdate.paymentStatus, // Potentially update payment status if delivery is cancelled
        deliveryStatus: newDeliveryStatus, // Apply the new delivery status
        pickupLocation: jobToUpdate.pickupLocation,
        dropoffLocation: jobToUpdate.dropoffLocation,
        pickupDate: jobToUpdate.pickupDate,
        estimatedDeliveryDate: jobToUpdate.estimatedDeliveryDate,
        actualDeliveryDate: jobToUpdate.actualDeliveryDate, // This might also need updating if newDeliveryStatus is 'Delivered'
        agreedPrice: jobToUpdate.agreedPrice,
        notes: jobToUpdate.notes,
        createdBy: jobToUpdate.createdBy,
        receiptUrl: jobToUpdate.receiptUrl,
        createdAt: jobToUpdate.createdAt,
        updatedAt: DateTime.now(), // Update timestamp
      );

      await _addChangeToQueue(ChangeOperation.update, jobId: jobId, job: updatedJobForQueue);

      // Optimistic Update
      _jobs[jobIndex] = updatedJobForQueue.toJson();
      _processAndSetJobsData(List<Map<String, dynamic>>.from(_jobs));
      await _saveJobsToCache(_jobs);
      notifyListeners();
      return;
    }

    // Online: Proceed with Supabase call
    try {
      final currentJobData = await _supabase.from('cargo_jobs').select('delivery_status, payment_status').eq('id', jobId).single();
      final oldDeliveryStatus = currentJobData['delivery_status'] as String? ?? deliveryStatusToString(DeliveryStatus.Scheduled);
      final String currentPaymentStatus = currentJobData['payment_status'] as String? ?? paymentStatusToString(PaymentStatus.Pending);
      final userId = _supabase.auth.currentUser?.id ?? 'system_status_change';
      Map<String, dynamic> updatePayload = {'delivery_status': newDeliveryStatus};

      if (newDeliveryStatus == deliveryStatusToString(DeliveryStatus.Cancelled)) {
        if (currentPaymentStatus != paymentStatusToString(PaymentStatus.Refunded)) {
          updatePayload['payment_status'] = paymentStatusToString(PaymentStatus.Refunded);
        }
      }
      // Potentially handle actualDeliveryDate if newDeliveryStatus is 'Delivered'
      // if (newDeliveryStatus == deliveryStatusToString(DeliveryStatus.Delivered) && updatedJobForQueue.actualDeliveryDate == null) {
      //   updatePayload['actual_delivery_date'] = DateTime.now().toIso8601String();
      // }


      await _supabase.from('cargo_jobs').update(updatePayload).eq('id', jobId);
      if (oldDeliveryStatus != newDeliveryStatus) {
        await addJobHistoryRecord(jobId, 'delivery_status', oldDeliveryStatus, newDeliveryStatus, userId);
      }
      if (updatePayload.containsKey('payment_status') && currentPaymentStatus != updatePayload['payment_status']) {
        await addJobHistoryRecord(jobId, 'payment_status', currentPaymentStatus, updatePayload['payment_status'] as String, userId);
      }
      await fetchJobsData();
      print('Job delivery status updated successfully online for job $jobId');
    } catch (e) {
      print('Error changing job delivery_status online: $e');
      throw Exception('Error changing job delivery_status online: $e');
    }
  }

  Future<void> updateJobPaymentStatus(String jobId, String newStatus) async {
    if (_isNetworkOffline) {
      print('Network offline. Queueing payment status update for job $jobId to $newStatus');
      final jobIndex = _jobs.indexWhere((j) => j['id'] == jobId);
      if (jobIndex == -1) {
        print('Job not found locally for offline update: $jobId');
        return;
      }
      CargoJob jobToUpdate = CargoJob.fromJson(_jobs[jobIndex]);
      CargoJob updatedJobForQueue = CargoJob( // Create a new instance for the queue
        id: jobToUpdate.id,
        shipperName: jobToUpdate.shipperName,
        paymentStatus: newStatus, // Apply the new payment status
        deliveryStatus: jobToUpdate.deliveryStatus,
        pickupLocation: jobToUpdate.pickupLocation,
        dropoffLocation: jobToUpdate.dropoffLocation,
        pickupDate: jobToUpdate.pickupDate,
        estimatedDeliveryDate: jobToUpdate.estimatedDeliveryDate,
        actualDeliveryDate: jobToUpdate.actualDeliveryDate,
        agreedPrice: jobToUpdate.agreedPrice,
        notes: jobToUpdate.notes,
        createdBy: jobToUpdate.createdBy,
        receiptUrl: jobToUpdate.receiptUrl,
        createdAt: jobToUpdate.createdAt,
        updatedAt: DateTime.now(), // Update timestamp
      );
      await _addChangeToQueue(ChangeOperation.update, jobId: jobId, job: updatedJobForQueue);

      // Optimistic Update
      _jobs[jobIndex] = updatedJobForQueue.toJson();
      _processAndSetJobsData(List<Map<String, dynamic>>.from(_jobs));
      await _saveJobsToCache(_jobs);
      notifyListeners();
      return;
    }

    // Online: Proceed with Supabase call
    try {
      final currentJobData = await _supabase.from('cargo_jobs').select().eq('id', jobId).single();
      final oldStatus = currentJobData['payment_status'] as String;
      final userId = _supabase.auth.currentUser?.id ?? 'system_status_change';
      await _supabase.from('cargo_jobs').update({'payment_status': newStatus}).eq('id', jobId);
      if (oldStatus != newStatus) {
        await addJobHistoryRecord(jobId, 'payment_status', oldStatus, newStatus, userId);
      }
      await fetchJobsData();
      print('Job payment status updated successfully online for job $jobId');
    } catch (e) {
      print('Error changing job payment_status online: $e');
      throw Exception('Error changing job payment_status online: $e');
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
