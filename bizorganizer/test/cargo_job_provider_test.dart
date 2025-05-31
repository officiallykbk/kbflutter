import 'dart:async';
import 'dart:convert';

import 'package:bizorganizer/models/cargo_job.dart';
import 'package:bizorganizer/models/offline_change.dart';
import 'package:bizorganizer/providers/orders_providers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// Import generated mocks
import 'cargo_job_provider_test.mocks.dart';

// Annotations for mock generation
@GenerateMocks([
  SupabaseClient,
  GoTrueClient,
  SupabaseQueryBuilder,
  PostgrestFilterBuilder, // Added for .eq() and other filtering
  PostgrestTransformBuilder, // Added for .order()
  RealtimeChannel,      // For .channel()
  Box,
  Connectivity,
], customMocks: [
  // If PostgrestResponse is not a class but a typedef or needs specific mocking:
  // MockSpec<PostgrestResponse>(as: #MockPostgrestResponseAliased),
  // For now, assuming PostgrestResponse can be mocked directly or is not directly used in a way that needs explicit mocking here.
  // Often, the data itself or an error is what's checked from the response.
])
void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuthClient;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder<dynamic> mockFilterBuilder; // Typed for clarity
  late MockPostgrestTransformBuilder<dynamic> mockTransformBuilder; // Typed for clarity
  // late MockPostgrestResponse mockPostgrestResponse; // Declared but might not be directly used if testing data/errors

  late MockBox<CargoJob> mockCargoJobBox;
  late MockBox<OfflineChange> mockOfflineChangeBox;
  late MockConnectivity mockConnectivity;

  late CargoJobProvider cargoJobProvider;

  final sampleJobMap = {
    'id': 'server-id-1',
    'shipper_name': 'Test Shipper',
    'delivery_status': 'Scheduled',
    'payment_status': 'Pending',
    'pickup_location': 'A',
    'dropoff_location': 'B',
    'agreed_price': 100.0,
    'created_by': 'user-id-123',
    'created_at': DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
    // Add other fields as necessary to match CargoJob.fromJson
  };
  final sampleCargoJob = CargoJob.fromJson(sampleJobMap);

  final sampleOfflineChangeCreate = OfflineChange(
    id: Uuid().v4(), // Generate unique ID for the change
    operation: ChangeOperation.create,
    jobData: jsonEncode(sampleCargoJob.toJson()),
    timestamp: DateTime.now(),
    jobId: sampleCargoJob.id, // This might be a client-generated ID for optimistic updates
  );

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockAuthClient = MockGoTrueClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterBuilder = MockPostgrestFilterBuilder<dynamic>();
    mockTransformBuilder = MockPostgrestTransformBuilder<dynamic>();
    // mockPostgrestResponse = MockPostgrestResponse();

    mockCargoJobBox = MockBox<CargoJob>();
    mockOfflineChangeBox = MockBox<OfflineChange>();
    mockConnectivity = MockConnectivity();

    // Default Supabase client behavior
    when(mockSupabaseClient.from(any)).thenReturn(mockQueryBuilder);
    when(mockSupabaseClient.auth).thenReturn(mockAuthClient); // Mock auth client
    when(mockAuthClient.currentUser).thenReturn(User(id: 'user-id-123', appMetadata: {}, userMetadata: {}, aud: 'aud', createdAt: DateTime.now().toIso8601String()));


    // Setup for query builder chain
    // SELECT operations
    when(mockQueryBuilder.select(any)).thenReturn(mockFilterBuilder); // .select() typically returns a PostgrestFilterBuilder
    when(mockFilterBuilder.eq(any, any)).thenReturn(mockFilterBuilder); // .eq() also returns PostgrestFilterBuilder
    when(mockFilterBuilder.order(any, ascending: anyNamed('ascending'))).thenReturn(mockTransformBuilder); // .order() returns PostgrestTransformBuilder
    when(mockTransformBuilder.order(any, ascending: anyNamed('ascending'))).thenReturn(mockTransformBuilder); // Allow chaining .order
    when(mockTransformBuilder.eq(any,any)).thenReturn(mockFilterBuilder); // Allow .eq after .order


    // INSERT operations
    when(mockQueryBuilder.insert(any, valueOptions: anyNamed('valueOptions'))).thenAnswer((_) async => [sampleJobMap]); // Simulate returning data directly

    // UPDATE operations
    when(mockQueryBuilder.update(any, valueOptions: anyNamed('valueOptions'))).thenReturn(mockQueryBuilder); // Returns QueryBuilder
    // .eq() after update is already mocked via mockQueryBuilder.eq -> mockFilterBuilder
    // For the actual execution of update:
    when(mockFilterBuilder.update(any)).thenAnswer((_) async => [sampleJobMap]); // Simulate update returning updated data

    // DELETE operations
    when(mockQueryBuilder.delete(valueOptions: anyNamed('valueOptions'))).thenReturn(mockQueryBuilder); // Returns QueryBuilder
    // .eq() after delete is already mocked
    // For the actual execution of delete:
    when(mockFilterBuilder.delete()).thenAnswer((_) async => [sampleJobMap]); // Simulate delete returning deleted data


    // Default responses for Hive boxes
    when(mockCargoJobBox.values).thenReturn([]);
    when(mockCargoJobBox.isEmpty).thenReturn(true);
    when(mockCargoJobBox.put(any, any)).thenAnswer((_) async => Future.value());
    when(mockCargoJobBox.addAll(any)).thenAnswer((_) async => Future.value([1])); // Simulate adding one item
    when(mockCargoJobBox.clear()).thenAnswer((_) async => Future.value(0));
    when(mockCargoJobBox.delete(any)).thenAnswer((_) async => Future.value());


    when(mockOfflineChangeBox.values).thenReturn([]);
    when(mockOfflineChangeBox.isEmpty).thenReturn(true);
    when(mockOfflineChangeBox.put(any, any)).thenAnswer((_) async => Future.value());
    when(mockOfflineChangeBox.delete(any)).thenAnswer((_) async => Future.value());

    // It's important that Hive.isBoxOpen returns true for the boxes used in provider
    // This part is tricky due to static calls. Ideal solution is DI for boxes.
    // For now, tests will assume boxes are open and can be interacted with.

    // Initialize CargoJobProvider - THIS IS THE CRITICAL PART FOR ADAPTATION
    // The user MUST adapt this to how they can inject mocks into CargoJobProvider
    // For example, if CargoJobProvider is refactored:
    // cargoJobProvider = CargoJobProvider(
    //   supabaseClient: mockSupabaseClient,
    //   connectivity: mockConnectivity,
    //   cargoJobBox: mockCargoJobBox,
    //   offlineChangeBox: mockOfflineChangeBox,
    // );
    // If not refactored, this test setup will have limitations.
    // We proceed assuming some form of injection or test-specific setup is done by the user.

    // For the sake of generating runnable test code, we'll call a testability method.
    // This is a placeholder for actual dependency injection.
    cargoJobProvider = CargoJobProvider();
    cargoJobProvider.testability_injectMocks(
      supabaseClient: mockSupabaseClient,
      connectivity: mockConnectivity,
      jobBox: mockCargoJobBox,
      changeBox: mockOfflineChangeBox
    );

    // Default connectivity
    when(mockConnectivity.checkConnectivity()).thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(mockConnectivity.onConnectivityChanged).thenAnswer((_) => Stream.value([ConnectivityResult.wifi]));
    // Initialize connectivity within the provider after mocks are injected.
    // This simulates the constructor's async work.
    // await cargoJobProvider.testability_initializeConnectivity(); // Call the actual init
  });

  tearDown(() {
    cargoJobProvider.dispose();
    // Hive.close(); // Be careful if Hive is used elsewhere or not properly isolated.
  });

  group('Connectivity Handling', () {
    test('Initializes with current connectivity status (online)', () async {
      await cargoJobProvider.testability_triggerConnectivityCheck(); // Simulate initial check
      expect(cargoJobProvider.isNetworkOffline, isFalse);
    });

    test('Initializes with current connectivity status (offline)', () async {
      when(mockConnectivity.checkConnectivity()).thenAnswer((_) async => [ConnectivityResult.none]);
      // Re-create provider or re-initialize connectivity part for this specific test condition
       cargoJobProvider = CargoJobProvider();
       cargoJobProvider.testability_injectMocks(
        supabaseClient: mockSupabaseClient,
        connectivity: mockConnectivity,
        jobBox: mockCargoJobBox,
        changeBox: mockOfflineChangeBox
      );
      await cargoJobProvider.testability_triggerConnectivityCheck();
      expect(cargoJobProvider.isNetworkOffline, isTrue);
    });

    test('Updates network status on connectivity change stream', () async {
      final connectivityStreamController = StreamController<List<ConnectivityResult>>();
      when(mockConnectivity.onConnectivityChanged).thenAnswer((_) => connectivityStreamController.stream);

      // Re-initialize to use the new stream controller
      cargoJobProvider = CargoJobProvider();
      cargoJobProvider.testability_injectMocks(
        supabaseClient: mockSupabaseClient,
        connectivity: mockConnectivity,
        jobBox: mockCargoJobBox,
        changeBox: mockOfflineChangeBox
      );
      await cargoJobProvider.testability_triggerConnectivityCheck(); // Initial check

      connectivityStreamController.add([ConnectivityResult.none]);
      await Future.delayed(Duration.zero); // Allow stream to propagate
      expect(cargoJobProvider.isNetworkOffline, isTrue, reason: "Should be offline after ConnectivityResult.none");

      connectivityStreamController.add([ConnectivityResult.ethernet]);
      await Future.delayed(Duration.zero);
      expect(cargoJobProvider.isNetworkOffline, isFalse, reason: "Should be online after ConnectivityResult.ethernet");

      await connectivityStreamController.close();
    });

    test('Calls _processOfflineChanges and fetchJobsData when coming online from offline', () async {
      // 1. Start offline
      when(mockConnectivity.checkConnectivity()).thenAnswer((_) async => [ConnectivityResult.none]);
      final streamController = StreamController<List<ConnectivityResult>>();
      when(mockConnectivity.onConnectivityChanged).thenAnswer((_) => streamController.stream);

      cargoJobProvider = CargoJobProvider();
      cargoJobProvider.testability_injectMocks(
          supabaseClient: mockSupabaseClient,
          connectivity: mockConnectivity,
          jobBox: mockCargoJobBox,
          changeBox: mockOfflineChangeBox);
      await cargoJobProvider.testability_triggerConnectivityCheck(); // Initial check, sets to offline

      expect(cargoJobProvider.isNetworkOffline, isTrue);

      // 2. Have an item in the change queue
      when(mockOfflineChangeBox.values).thenReturn([sampleOfflineChangeCreate]);
      when(mockOfflineChangeBox.isEmpty).thenReturn(false);

      // 3. Mock Supabase for create operation during sync
      //    Note: insert is mocked to return [sampleJobMap] in setUp
      //    Mock select for the fetch after sync
      when(mockSupabaseClient.from('cargo_jobs').select(any).order(any, ascending: anyNamed('ascending')))
          .thenAnswer((_) async => [sampleJobMap]);


      // 4. Action: Transition to online
      streamController.add([ConnectivityResult.wifi]);
      await Future.delayed(Duration.zero); // Allow stream and async operations to complete

      // 5. Assertions
      expect(cargoJobProvider.isNetworkOffline, isFalse);
      // Verify that Supabase insert was called for the queued item
      verify(mockSupabaseClient.from('cargo_jobs').insert(any, valueOptions: anyNamed('valueOptions'))).called(1);
      // Verify the change was deleted
      verify(mockOfflineChangeBox.delete(sampleOfflineChangeCreate.id)).called(1);
      // Verify fetchJobsData was called (implicitly, by checking the select call)
      verify(mockSupabaseClient.from('cargo_jobs').select(any).order(any, ascending: anyNamed('ascending'))).called(1);

      await streamController.close();
    });
  });

  group('Offline Change Queueing', () {
    setUp(() async { // Make setUp async if needed for re-initialization
      when(mockConnectivity.checkConnectivity()).thenAnswer((_) async => [ConnectivityResult.none]);
      when(mockConnectivity.onConnectivityChanged).thenAnswer((_) => Stream.value([ConnectivityResult.none]));

      cargoJobProvider = CargoJobProvider();
      cargoJobProvider.testability_injectMocks(
          supabaseClient: mockSupabaseClient,
          connectivity: mockConnectivity,
          jobBox: mockCargoJobBox,
          changeBox: mockOfflineChangeBox);
      await cargoJobProvider.testability_triggerConnectivityCheck(); // Ensure provider is in offline state
    });

    test('addJob queues change and updates cache optimistically when offline', () async {
      await cargoJobProvider.addJob(sampleCargoJob);

      verify(mockOfflineChangeBox.put(any, any)).called(1);
      verify(mockCargoJobBox.clear()).called(1); // From _saveJobsToCache
      verify(mockCargoJobBox.addAll(any)).called(1); // From _saveJobsToCache
      expect(cargoJobProvider.jobs.first['shipper_name'], sampleCargoJob.shipperName);
      expect(cargoJobProvider.jobs.first['id'], isNotNull); // Should have a client-generated ID
    });

    test('removeJob queues change and updates cache optimistically when offline', () async {
      // Setup: Provider has one job
      cargoJobProvider.testability_setJobsForTest([sampleCargoJob]); // Uses internal _jobs

      await cargoJobProvider.removeJob(sampleCargoJob.id!);

      verify(mockOfflineChangeBox.put(any, any)).called(1);
      verify(mockCargoJobBox.clear()).called(1);
      verify(mockCargoJobBox.addAll(argThat(isEmpty))).called(1); // Cache is now empty
      expect(cargoJobProvider.jobs, isEmpty);
    });

    test('updateJobDeliveryStatus queues change and updates cache optimistically when offline', () async {
      cargoJobProvider.testability_setJobsForTest([sampleCargoJob]);
      const newStatus = "Delivered";

      await cargoJobProvider.updateJobDeliveryStatus(sampleCargoJob.id!, newStatus);

      verify(mockOfflineChangeBox.put(any, any)).called(1);
      verify(mockCargoJobBox.clear()).called(1);
      verify(mockCargoJobBox.addAll(any)).called(1);
      expect(cargoJobProvider.jobs.first['delivery_status'], newStatus);
    });
  });

  group('_processOfflineChanges Synchronization', () {
    setUp(() async {
      // Assume online for these tests, or that connectivity check passes
      when(mockConnectivity.checkConnectivity()).thenAnswer((_) async => [ConnectivityResult.wifi]);
      cargoJobProvider = CargoJobProvider();
       cargoJobProvider.testability_injectMocks(
          supabaseClient: mockSupabaseClient,
          connectivity: mockConnectivity,
          jobBox: mockCargoJobBox,
          changeBox: mockOfflineChangeBox);
      await cargoJobProvider.testability_triggerConnectivityCheck();
    });

    test('Processes CREATE change: calls Supabase, removes from queue, fetches data', () async {
      when(mockOfflineChangeBox.values).thenReturn([sampleOfflineChangeCreate]);
      when(mockOfflineChangeBox.isEmpty).thenReturn(false);

      // Supabase insert is mocked in main setUp to return [sampleJobMap]
      // Supabase select for fetchJobsData:
      when(mockSupabaseClient.from('cargo_jobs').select(any).order(any, ascending: anyNamed('ascending')))
          .thenAnswer((_) async => [sampleJobMap]);

      await cargoJobProvider.testability_processOfflineChanges();

      verify(mockSupabaseClient.from('cargo_jobs').insert(any, valueOptions: anyNamed('valueOptions'))).called(1);
      verify(mockOfflineChangeBox.delete(sampleOfflineChangeCreate.id)).called(1);
      verify(mockSupabaseClient.from('cargo_jobs').select(any).order(any, ascending: anyNamed('ascending'))).called(1);
      expect(cargoJobProvider.isSyncing, isFalse); // Check isSyncing flag
    });

    test('Processes UPDATE change correctly', () async {
        final updatedJobData = Map<String, dynamic>.from(sampleCargoJob.toJson());
        updatedJobData['delivery_status'] = "Delivered";
        final updateChange = OfflineChange(
            id: Uuid().v4(),
            operation: ChangeOperation.update,
            jobId: sampleCargoJob.id!,
            jobData: jsonEncode(updatedJobData),
            timestamp: DateTime.now()
        );
        when(mockOfflineChangeBox.values).thenReturn([updateChange]);
        when(mockOfflineChangeBox.isEmpty).thenReturn(false);

        // Mock Supabase update
        // The .eq() is part of the chain from .update() or .delete()
        when(mockSupabaseClient.from('cargo_jobs').update(any)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq(any, any)).thenAnswer((_) async => [updatedJobData]); // Simulate update returning data


        // Mock select for fetchJobsData:
        when(mockSupabaseClient.from('cargo_jobs').select(any).order(any, ascending: anyNamed('ascending')))
            .thenAnswer((_) async => [updatedJobData]);


        await cargoJobProvider.testability_processOfflineChanges();

        verify(mockSupabaseClient.from('cargo_jobs').update(argThat(containsPair('delivery_status', 'Delivered')))).called(1);
        verify(mockOfflineChangeBox.delete(updateChange.id)).called(1);
        verify(mockSupabaseClient.from('cargo_jobs').select(any).order(any, ascending: anyNamed('ascending'))).called(1);
    });

    test('Processes DELETE change correctly', () async {
        final deleteChange = OfflineChange(
            id: Uuid().v4(),
            operation: ChangeOperation.delete,
            jobId: sampleCargoJob.id!,
            timestamp: DateTime.now()
        );
        when(mockOfflineChangeBox.values).thenReturn([deleteChange]);
        when(mockOfflineChangeBox.isEmpty).thenReturn(false);

        // Mock Supabase delete
        when(mockSupabaseClient.from('cargo_jobs').delete()).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq(any, any)).thenAnswer((_) async => [sampleJobMap]); // Simulate delete returning data

        // Mock select for fetchJobsData (empty list after delete)
        when(mockSupabaseClient.from('cargo_jobs').select(any).order(any, ascending: anyNamed('ascending')))
            .thenAnswer((_) async => []);

        await cargoJobProvider.testability_processOfflineChanges();

        verify(mockSupabaseClient.from('cargo_jobs').delete().eq('id', sampleCargoJob.id!)).called(1);
        verify(mockOfflineChangeBox.delete(deleteChange.id)).called(1);
        verify(mockSupabaseClient.from('cargo_jobs').select(any).order(any, ascending: anyNamed('ascending'))).called(1);
        expect(cargoJobProvider.jobs, isEmpty);
    });

    test('Handles Supabase error during change processing, keeps change in queue', () async {
        when(mockOfflineChangeBox.values).thenReturn([sampleOfflineChangeCreate]);
        when(mockOfflineChangeBox.isEmpty).thenReturn(false);

        // Simulate Supabase insert error
        when(mockSupabaseClient.from('cargo_jobs').insert(any, valueOptions: anyNamed('valueOptions')))
            .thenThrow(PostgrestException(message: 'Simulated insert error'));

        // Mock select for fetchJobsData (still called in finally)
        when(mockSupabaseClient.from('cargo_jobs').select(any).order(any, ascending: anyNamed('ascending')))
            .thenAnswer((_) async => []);


        await cargoJobProvider.testability_processOfflineChanges();

        verify(mockSupabaseClient.from('cargo_jobs').insert(any, valueOptions: anyNamed('valueOptions'))).called(1);
        verifyNever(mockOfflineChangeBox.delete(sampleOfflineChangeCreate.id)); // Not deleted
        verify(mockSupabaseClient.from('cargo_jobs').select(any).order(any, ascending: anyNamed('ascending'))).called(1); // fetchJobsData still called
    });
  });
}

// Testability extension for CargoJobProvider
// User must adapt CargoJobProvider to allow injection of these mocks,
// possibly via constructor or a more sophisticated DI approach.
extension TestableCargoJobProvider on CargoJobProvider {
  void testability_injectMocks({
    required SupabaseClient supabaseClient,
    required Connectivity connectivity,
    required Box<CargoJob> jobBox,
    required Box<OfflineChange> changeBox,
  }) {
    // This is a conceptual method. It assumes that CargoJobProvider's internal
    // dependencies (like _supabase, _connectivity, and direct Hive.box calls)
    // can be replaced for testing.
    // One way: have private nullable fields for these, and if null, use actual instance.
    // For tests, set these fields.
    // e.g., this.supabaseClientForTest = supabaseClient;
    // And in provider methods: final client = supabaseClientForTest ?? Supabase.instance.client;

    // This requires modification of CargoJobProvider itself.
    // For now, this extension serves as a placeholder for that injection.
    // The actual tests above might fail without such modifications to CargoJobProvider.
    print("Warning: Mock injection is conceptual. CargoJobProvider needs to be adapted for proper DI.");
  }

  Future<void> testability_triggerConnectivityCheck() {
    // This would typically call the provider's internal method that's called by constructor or initState
    // to check initial connectivity.
    return _initializeConnectivityStatus();
  }

  void testability_setJobsForTest(List<CargoJob> newJobs) {
    // Helper to directly set the internal _jobs list for certain test scenarios.
    // This bypasses fetching or loading from cache.
    _jobs = newJobs.map((j) => j.toJson()).toList();
    _processAndSetJobsData(_jobs); // Ensure filtered lists are also updated
  }

  Future<void> testability_processOfflineChanges() {
    return _processOfflineChanges();
  }
}

// Note: The PostgrestFilterBuilder and PostgrestTransformBuilder mocks might need
// to return themselves for chained calls if the actual Supabase client does that,
// e.g., when(mockFilterBuilder.lt(any, any)).thenReturn(mockFilterBuilder);
// The current setup tries to mock the final execution method (e.g. .thenAnswer for insert/delete/update)
// or assumes the chain ends in a method that returns the data directly (like older Supabase versions).
// The user needs to adjust based on their exact Supabase call patterns.
// For .select().order().eq() chains, the final method that returns data (e.g. if it's `await eq(...)`)
// should be mocked on the builder that provides it.
// e.g. when(mockFilterBuilder.eq(any,any)).thenAnswer((_) async => [sampleJobMap]);
// The example above has been updated to reflect some of this chaining.
// The key is that the method that actually executes the query and returns a Future<Data> or Future<Response>
// needs to be the one mocked with .thenAnswer((_) async => ...).
