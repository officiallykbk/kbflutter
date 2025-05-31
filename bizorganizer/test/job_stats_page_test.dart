import 'package:bizorganizer/providers/orders_providers.dart'; // Will import CargoJobProvider
import 'package:bizorganizer/stats.dart'; // Will import JobStatsPage
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bizorganizer/models/offline_change.dart';
import 'dart:io';

// Initialize Hive for testing
Future<void> initializeHiveForTesting() async {
  final directory = await Directory.systemTemp.createTemp();
  Hive.init(directory.path);
  Hive.registerAdapter(ChangeOperationAdapter());
  Hive.registerAdapter(OfflineChangeAdapter());
  final box = await Hive.openBox<OfflineChange>('offlineChangesBox');
  // Make the box listenable
  box.listenable();
}

// Clean up Hive after tests
Future<void> cleanupHive() async {
  await Hive.close();
}

// Define MockCargoJobProvider by extending Mock and implementing CargoJobProvider
class MockCargoJobProvider extends Mock implements CargoJobProvider {
  // Mock the getters that JobStatsPage uses
  // These will be overridden in tests with specific mock data
  @override
  List<Map<String, dynamic>> get jobs => []; // Renamed from trips

  @override
  List<Map<String, dynamic>> get completedJobs => []; // Renamed

  @override
  List<Map<String, dynamic>> get pendingJobs => []; // Renamed

  @override
  List<Map<String, dynamic>> get cancelledJobs => []; // Renamed

  @override
  List<Map<String, dynamic>> get delayedJobs => [];

  @override
  List<Map<String, dynamic>> get paidJobs => []; // Renamed

  @override
  List<Map<String, dynamic>> get pendingPayments =>
      []; // Kept similar name, refers to jobs

  @override
  List<Map<String, dynamic>> get overduePayments =>
      []; // Kept similar name, refers to jobs
}

void main() {
  setUpAll(() async {
    await initializeHiveForTesting();
  });

  tearDownAll(() async {
    await cleanupHive();
  });

  // Sample cargo job data for testing
  final sampleCargoJobs = [
    // Paid Jobs
    {
      'id': '1',
      'shipper_name': 'Shipper A',
      'agreed_price': 100.0,
      'payment_status': 'paid',
      'delivery_status': 'completed',
      'created_at': DateTime(2023, 1, 15).toIso8601String(),
      'dropoff_location': 'City X'
    },
    {
      'id': '2',
      'shipper_name': 'Shipper B',
      'agreed_price': 150.0,
      'payment_status': 'paid',
      'delivery_status': 'completed',
      'created_at': DateTime(2023, 1, 20).toIso8601String(),
      'dropoff_location': 'City Y'
    },
    // Pending Payment Jobs
    {
      'id': '3',
      'shipper_name': 'Shipper C',
      'agreed_price': 200.0,
      'payment_status': 'pending',
      'delivery_status': 'pending',
      'created_at': DateTime(2023, 2, 10).toIso8601String(),
      'dropoff_location': 'City Z'
    },
    {
      'id': '4',
      'shipper_name': 'Shipper D',
      'agreed_price': 250.0,
      'payment_status': 'pending',
      'delivery_status': 'completed',
      'created_at': DateTime(2023, 2, 15).toIso8601String(),
      'dropoff_location': 'City X'
    },
    // Overdue Payment Jobs
    {
      'id': '5',
      'shipper_name': 'Shipper E',
      'agreed_price': 300.0,
      'payment_status': 'overdue',
      'delivery_status': 'pending',
      'created_at': DateTime(2023, 3, 1).toIso8601String(),
      'dropoff_location': 'City Y'
    },
    // Another Paid Job for date filtering tests
    {
      'id': '6',
      'shipper_name': 'Shipper F',
      'agreed_price': 50.0,
      'payment_status': 'paid',
      'delivery_status': 'completed',
      'created_at': DateTime(2023, 3, 5).toIso8601String(),
      'dropoff_location': 'City Z'
    },
    // Another Pending Job for date filtering tests
    {
      'id': '7',
      'shipper_name': 'Shipper G',
      'agreed_price': 75.0,
      'payment_status': 'pending',
      'delivery_status': 'pending',
      'created_at': DateTime(2023, 3, 10).toIso8601String(),
      'dropoff_location': 'City X'
    },
  ];

  final paidJobsSample =
      sampleCargoJobs.where((j) => j['payment_status'] == 'paid').toList();
  final pendingJobsSample =
      sampleCargoJobs.where((j) => j['payment_status'] == 'pending').toList();
  final overdueJobsSample =
      sampleCargoJobs.where((j) => j['payment_status'] == 'overdue').toList();

  // Helper function to pump JobStatsPage with MockCargoJobProvider
  Future<void> pumpJobStatsPage(
      WidgetTester tester, MockCargoJobProvider mockProvider) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          // Use CargoJobProvider here
          ChangeNotifierProvider<CargoJobProvider>.value(value: mockProvider),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: JobStatsPage(), // Use JobStatsPage
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('JobStatsPage - Payment Filtering Logic Tests', () {
    // Updated group description
    late MockCargoJobProvider mockCargoJobProvider; // Updated type

    setUp(() {
      mockCargoJobProvider = MockCargoJobProvider(); // Updated type
      when(mockCargoJobProvider.jobs).thenReturn(sampleCargoJobs);
      when(mockCargoJobProvider.completedJobs).thenReturn(sampleCargoJobs
          .where((j) => j['delivery_status'] == 'completed')
          .toList());
      when(mockCargoJobProvider.pendingJobs).thenReturn(sampleCargoJobs
          .where((j) => j['delivery_status'] == 'pending')
          .toList());
      when(mockCargoJobProvider.cancelledJobs).thenReturn([]);
      when(mockCargoJobProvider.delayedJobs).thenReturn([]);
      when(mockCargoJobProvider.paidJobs).thenReturn(paidJobsSample);
      when(mockCargoJobProvider.pendingPayments).thenReturn(pendingJobsSample);
      when(mockCargoJobProvider.overduePayments).thenReturn(overdueJobsSample);
    });

    testWidgets('Filters for "Paid Only"', (WidgetTester tester) async {
      await pumpJobStatsPage(tester, mockCargoJobProvider); // Updated helper

      final paymentFilterDropdown =
          find.byType(DropdownButtonFormField<String>).at(1);
      expect(paymentFilterDropdown, findsOneWidget);

      await tester.tap(paymentFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paid Only').last);
      await tester.pumpAndSettle();

      // Total paid agreed_price: 100.0 + 150.0 + 50.0 = 300.0
      final totalRevenueText =
          find.textContaining(RegExp(r'Total Revenue.*\$300\.00'));
      expect(totalRevenueText, findsOneWidget,
          reason: 'Total Revenue should be \$300.00 for \'Paid Only\' jobs');
    });

    testWidgets('Filters for "Pending Only"', (WidgetTester tester) async {
      await pumpJobStatsPage(tester, mockCargoJobProvider); // Updated helper

      final paymentFilterDropdown =
          find.byType(DropdownButtonFormField<String>).at(1);
      await tester.tap(paymentFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pending Only').last);
      await tester.pumpAndSettle();

      // Total pending agreed_price: 200.0 + 250.0 + 75.0 = 525.0
      final totalRevenueText =
          find.textContaining(RegExp(r'Total Revenue.*\$525\.00'));
      expect(totalRevenueText, findsOneWidget,
          reason: 'Total Revenue should be \$525.00 for \'Pending Only\' jobs');
    });

    testWidgets('Filters for "Paid + Pending"', (WidgetTester tester) async {
      await pumpJobStatsPage(tester, mockCargoJobProvider); // Updated helper

      // Total "Paid + Pending" agreed_price: 300.0 (paid) + 525.0 (pending) = 825.0
      final totalRevenueText =
          find.textContaining(RegExp(r'Total Revenue.*\$825\.00'));
      expect(totalRevenueText, findsOneWidget,
          reason:
              'Total Revenue should be \$825.00 for \'Paid + Pending\' jobs (initial)');

      final paymentFilterDropdown =
          find.byType(DropdownButtonFormField<String>).at(1);
      await tester.tap(paymentFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paid Only').last);
      await tester.pumpAndSettle();

      await tester.tap(paymentFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paid + Pending').last);
      await tester.pumpAndSettle();

      expect(totalRevenueText, findsOneWidget,
          reason:
              'Total Revenue should be \$825.00 for \'Paid + Pending\' jobs (after re-selecting)');
    });
  });

  group('JobStatsPage - KPI Calculation Tests', () {
    // Updated group description
    late MockCargoJobProvider mockCargoJobProvider; // Updated type

    setUp(() {
      mockCargoJobProvider = MockCargoJobProvider(); // Updated type
      when(mockCargoJobProvider.jobs).thenReturn(sampleCargoJobs);
      when(mockCargoJobProvider.completedJobs).thenReturn(sampleCargoJobs
          .where((j) => j['delivery_status'] == 'completed')
          .toList());
      when(mockCargoJobProvider.pendingJobs).thenReturn(sampleCargoJobs
          .where((j) => j['delivery_status'] == 'pending')
          .toList());
      when(mockCargoJobProvider.cancelledJobs).thenReturn([]);
      when(mockCargoJobProvider.delayedJobs).thenReturn([]);
      when(mockCargoJobProvider.paidJobs).thenReturn(paidJobsSample);
      when(mockCargoJobProvider.pendingPayments).thenReturn(pendingJobsSample);
      when(mockCargoJobProvider.overduePayments).thenReturn(overdueJobsSample);
    });

    testWidgets(
        'Total Revenue KPI is correct with "Paid Only" and specific date range',
        (WidgetTester tester) async {
      await pumpJobStatsPage(tester, mockCargoJobProvider); // Updated helper

      final paymentFilterDropdown =
          find.byType(DropdownButtonFormField<String>).at(1);
      await tester.tap(paymentFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paid Only').last);
      await tester.pumpAndSettle();

      final dateFilterDropdown =
          find.byType(DropdownButtonFormField<String>).at(0);
      await tester.tap(dateFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 6 Months').last);
      await tester.pumpAndSettle();

      final totalRevenueText =
          find.textContaining(RegExp(r'Total Revenue.*\$300\.00'));
      expect(totalRevenueText, findsOneWidget,
          reason:
              'Total Revenue for \'Paid Only\' jobs in \'Last 6 Months\' should be \$300.00');
    });

    testWidgets(
        'Paid vs Pending Sub-KPI is correct when "Paid + Pending" is selected',
        (WidgetTester tester) async {
      await pumpJobStatsPage(tester, mockCargoJobProvider); // Updated helper

      final dateFilterDropdown =
          find.byType(DropdownButtonFormField<String>).at(0);
      await tester.tap(dateFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 6 Months').last);
      await tester.pumpAndSettle();

      final paidSubKpi = find.textContaining(RegExp(r'Paid:.*\$300\.00'));
      final pendingSubKpi = find.textContaining(RegExp(r'Pending:.*\$525\.00'));

      expect(paidSubKpi, findsOneWidget,
          reason:
              'Paid sub-KPI should be \$300.00 for \'Paid + Pending\' jobs in \'Last 6 Months\'');
      expect(pendingSubKpi, findsOneWidget,
          reason:
              'Pending sub-KPI should be \$525.00 for \'Paid + Pending\' jobs in \'Last 6 Months\'');
    });

    testWidgets('Average Revenue Per Job KPI is correct',
        (WidgetTester tester) async {
      // Updated test desc
      await pumpJobStatsPage(tester, mockCargoJobProvider); // Updated helper

      final dateFilterDropdown =
          find.byType(DropdownButtonFormField<String>).at(0);
      await tester.tap(dateFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 6 Months').last);
      await tester.pumpAndSettle();

      // Total agreed_price for "Paid + Pending" = $825
      // Total jobs for "Paid + Pending" = 6 jobs
      // Average = $825 / 6 = $137.50
      final avgRevenueText = find.textContaining(
          RegExp(r'Avg. Revenue/Job.*\$137\.50')); // Updated label
      expect(avgRevenueText, findsOneWidget,
          reason:
              'Average Revenue for \'Paid + Pending\' jobs in \'Last 6 Months\' should be \$137.50'); // Updated reason
    });

    testWidgets('Average Revenue Per Job handles division by zero gracefully',
        (WidgetTester tester) async {
      // Updated test desc
      when(mockCargoJobProvider.jobs).thenReturn([]); // Use new field name
      when(mockCargoJobProvider.paidJobs).thenReturn([]); // Use new field name
      when(mockCargoJobProvider.pendingPayments)
          .thenReturn([]); // Use new field name

      await pumpJobStatsPage(tester, mockCargoJobProvider); // Updated helper

      final paymentFilterDropdown =
          find.byType(DropdownButtonFormField<String>).at(1);
      await tester.tap(paymentFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paid Only').last);
      await tester.pumpAndSettle();

      final avgRevenueText = find.textContaining(
          RegExp(r'Avg. Revenue/Job.*\$0\.00')); // Updated label
      expect(avgRevenueText, findsOneWidget,
          reason:
              'Average Revenue should be \$0.00 when no jobs match filter'); // Updated reason
    });
  });
}
