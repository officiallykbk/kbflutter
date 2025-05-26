import 'package:bizorganizer/providers/orders_providers.dart'; // Will import CargoJobProvider
import 'package:bizorganizer/stats.dart'; // Will import JobStatsPage
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

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
  List<Map<String, dynamic>> get onHoldJobs => []; // Renamed

  @override
  List<Map<String, dynamic>> get paidJobs => []; // Renamed

  @override
  List<Map<String, dynamic>> get pendingPayments => []; // Kept similar name, refers to jobs
  
  @override
  List<Map<String, dynamic>> get overduePayments => []; // Kept similar name, refers to jobs
}

void main() {
  // Sample cargo job data for testing
  final sampleCargoJobs = [
    // Paid Jobs
    {'id': 1, 'shipper_name': 'Shipper A', 'agreed_price': 100.0, 'payment_status': 'paid', 'delivery_status': 'completed', 'created_at': DateTime(2023, 1, 15).toIso8601String(), 'dropoff_location': 'City X'},
    {'id': 2, 'shipper_name': 'Shipper B', 'agreed_price': 150.0, 'payment_status': 'paid', 'delivery_status': 'completed', 'created_at': DateTime(2023, 1, 20).toIso8601String(), 'dropoff_location': 'City Y'},
    // Pending Payment Jobs
    {'id': 3, 'shipper_name': 'Shipper C', 'agreed_price': 200.0, 'payment_status': 'pending', 'delivery_status': 'pending', 'created_at': DateTime(2023, 2, 10).toIso8601String(), 'dropoff_location': 'City Z'},
    {'id': 4, 'shipper_name': 'Shipper D', 'agreed_price': 250.0, 'payment_status': 'pending', 'delivery_status': 'completed', 'created_at': DateTime(2023, 2, 15).toIso8601String(), 'dropoff_location': 'City X'},
    // Overdue Payment Jobs
    {'id': 5, 'shipper_name': 'Shipper E', 'agreed_price': 300.0, 'payment_status': 'overdue', 'delivery_status': 'pending', 'created_at': DateTime(2023, 3, 1).toIso8601String(), 'dropoff_location': 'City Y'},
    // Another Paid Job for date filtering tests
    {'id': 6, 'shipper_name': 'Shipper F', 'agreed_price': 50.0, 'payment_status': 'paid', 'delivery_status': 'completed', 'created_at': DateTime(2023, 3, 5).toIso8601String(), 'dropoff_location': 'City Z'},
    // Another Pending Job for date filtering tests
    {'id': 7, 'shipper_name': 'Shipper G', 'agreed_price': 75.0, 'payment_status': 'pending', 'delivery_status': 'pending', 'created_at': DateTime(2023, 3, 10).toIso8601String(), 'dropoff_location': 'City X'},
  ];

  final paidJobsSample = sampleCargoJobs.where((j) => j['payment_status'] == 'paid').toList();
  final pendingJobsSample = sampleCargoJobs.where((j) => j['payment_status'] == 'pending').toList();
  final overdueJobsSample = sampleCargoJobs.where((j) => j['payment_status'] == 'overdue').toList();


  // Helper function to pump JobStatsPage with MockCargoJobProvider
  Future<void> pumpJobStatsPage(WidgetTester tester, MockCargoJobProvider mockProvider) async {
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

  group('JobStatsPage - Payment Filtering Logic Tests', () { // Updated group description
    late MockCargoJobProvider mockCargoJobProvider; // Updated type

    setUp(() {
      mockCargoJobProvider = MockCargoJobProvider(); // Updated type
      when(mockCargoJobProvider.jobs).thenReturn(sampleCargoJobs); 
      when(mockCargoJobProvider.completedJobs).thenReturn(sampleCargoJobs.where((j) => j['delivery_status'] == 'completed').toList());
      when(mockCargoJobProvider.pendingJobs).thenReturn(sampleCargoJobs.where((j) => j['delivery_status'] == 'pending').toList());
      when(mockCargoJobProvider.cancelledJobs).thenReturn(sampleCargoJobs.where((j) => j['delivery_status'] == 'cancelled').toList()); 
      when(mockCargoJobProvider.onHoldJobs).thenReturn(sampleCargoJobs.where((j) => j['delivery_status'] == 'onhold').toList()); 
      when(mockCargoJobProvider.paidJobs).thenReturn(paidJobsSample);
      when(mockCargoJobProvider.pendingPayments).thenReturn(pendingJobsSample);
      when(mockCargoJobProvider.overduePayments).thenReturn(overdueJobsSample);
    });

    testWidgets('Filters for "Paid Only"', (WidgetTester tester) async {
      await pumpJobStatsPage(tester, mockCargoJobProvider); // Updated helper

      final paymentFilterDropdown = find.byType(DropdownButtonFormField<String>).at(1); 
      expect(paymentFilterDropdown, findsOneWidget);
      
      await tester.tap(paymentFilterDropdown);
      await tester.pumpAndSettle(); 
      await tester.tap(find.text('Paid Only').last); 
      await tester.pumpAndSettle(); 

      // Total paid agreed_price: 100.0 + 150.0 + 50.0 = 300.0
      final totalRevenueText = find.textContaining(RegExp(r'Total Revenue.*\$300\.00')); 
      expect(totalRevenueText, findsOneWidget, reason: "Total Revenue should be $300.00 for 'Paid Only' jobs"); // Updated reason
    });

    testWidgets('Filters for "Pending Only"', (WidgetTester tester) async {
      await pumpJobStatsPage(tester, mockCargoJobProvider); // Updated helper
      
      final paymentFilterDropdown = find.byType(DropdownButtonFormField<String>).at(1);
      await tester.tap(paymentFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pending Only').last);
      await tester.pumpAndSettle();

      // Total pending agreed_price: 200.0 + 250.0 + 75.0 = 525.0
      final totalRevenueText = find.textContaining(RegExp(r'Total Revenue.*\$525\.00'));
      expect(totalRevenueText, findsOneWidget, reason: "Total Revenue should be $525.00 for 'Pending Only' jobs"); // Updated reason
    });

    testWidgets('Filters for "Paid + Pending"', (WidgetTester tester) async {
      await pumpJobStatsPage(tester, mockCargoJobProvider); // Updated helper

      // Total "Paid + Pending" agreed_price: 300.0 (paid) + 525.0 (pending) = 825.0
      final totalRevenueText = find.textContaining(RegExp(r'Total Revenue.*\$825\.00'));
      expect(totalRevenueText, findsOneWidget, reason: "Total Revenue should be $825.00 for 'Paid + Pending' jobs (initial)"); // Updated reason
      
      final paymentFilterDropdown = find.byType(DropdownButtonFormField<String>).at(1);
      await tester.tap(paymentFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paid Only').last);
      await tester.pumpAndSettle();

      await tester.tap(paymentFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paid + Pending').last);
      await tester.pumpAndSettle();
      
      expect(totalRevenueText, findsOneWidget, reason: "Total Revenue should be $825.00 for 'Paid + Pending' jobs (after re-selecting)"); // Updated reason
    });
  });

  group('JobStatsPage - KPI Calculation Tests', () { // Updated group description
    late MockCargoJobProvider mockCargoJobProvider; // Updated type

    setUp(() {
      mockCargoJobProvider = MockCargoJobProvider(); // Updated type
      when(mockCargoJobProvider.jobs).thenReturn(sampleCargoJobs);
      when(mockCargoJobProvider.completedJobs).thenReturn(sampleCargoJobs.where((j) => j['delivery_status'] == 'completed').toList());
      when(mockCargoJobProvider.pendingJobs).thenReturn(sampleCargoJobs.where((j) => j['delivery_status'] == 'pending').toList());
      when(mockCargoJobProvider.cancelledJobs).thenReturn([]); 
      when(mockCargoJobProvider.onHoldJobs).thenReturn([]); 
      when(mockCargoJobProvider.paidJobs).thenReturn(paidJobsSample);
      when(mockCargoJobProvider.pendingPayments).thenReturn(pendingJobsSample);
      when(mockCargoJobProvider.overduePayments).thenReturn(overdueJobsSample);
    });

    testWidgets('Total Revenue KPI is correct with "Paid Only" and specific date range', (WidgetTester tester) async {
      await pumpJobStatsPage(tester, mockCargoJobProvider); // Updated helper

      final paymentFilterDropdown = find.byType(DropdownButtonFormField<String>).at(1);
      await tester.tap(paymentFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paid Only').last);
      await tester.pumpAndSettle();

      final dateFilterDropdown = find.byType(DropdownButtonFormField<String>).at(0); 
      await tester.tap(dateFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 6 Months').last);
      await tester.pumpAndSettle();
      
      final totalRevenueText = find.textContaining(RegExp(r'Total Revenue.*\$300\.00'));
      expect(totalRevenueText, findsOneWidget, reason: "Total Revenue for 'Paid Only' jobs in 'Last 6 Months' should be $300.00"); // Updated reason
    });

    testWidgets('Paid vs Pending Sub-KPI is correct when "Paid + Pending" is selected', (WidgetTester tester) async {
      await pumpJobStatsPage(tester, mockCargoJobProvider); // Updated helper

      final dateFilterDropdown = find.byType(DropdownButtonFormField<String>).at(0);
      await tester.tap(dateFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 6 Months').last);
      await tester.pumpAndSettle();

      final paidSubKpi = find.textContaining(RegExp(r'Paid:.*\$300\.00'));
      final pendingSubKpi = find.textContaining(RegExp(r'Pending:.*\$525\.00'));

      expect(paidSubKpi, findsOneWidget, reason: "Paid sub-KPI should be $300.00 for 'Paid + Pending' jobs in 'Last 6 Months'"); // Updated reason
      expect(pendingSubKpi, findsOneWidget, reason: "Pending sub-KPI should be $525.00 for 'Paid + Pending' jobs in 'Last 6 Months'"); // Updated reason
    });

    testWidgets('Average Revenue Per Job KPI is correct', (WidgetTester tester) async { // Updated test desc
      await pumpJobStatsPage(tester, mockCargoJobProvider); // Updated helper
      
      final dateFilterDropdown = find.byType(DropdownButtonFormField<String>).at(0);
      await tester.tap(dateFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 6 Months').last);
      await tester.pumpAndSettle();

      // Total agreed_price for "Paid + Pending" = $825
      // Total jobs for "Paid + Pending" = 6 jobs
      // Average = $825 / 6 = $137.50
      final avgRevenueText = find.textContaining(RegExp(r'Avg. Revenue/Job.*\$137\.50')); // Updated label
      expect(avgRevenueText, findsOneWidget, reason: "Average Revenue for 'Paid + Pending' jobs in 'Last 6 Months' should be $137.50"); // Updated reason
    });

     testWidgets('Average Revenue Per Job handles division by zero gracefully', (WidgetTester tester) async { // Updated test desc
      when(mockCargoJobProvider.jobs).thenReturn([]); // Use new field name
      when(mockCargoJobProvider.paidJobs).thenReturn([]); // Use new field name
      when(mockCargoJobProvider.pendingPayments).thenReturn([]); // Use new field name
      
      await pumpJobStatsPage(tester, mockCargoJobProvider); // Updated helper

      final paymentFilterDropdown = find.byType(DropdownButtonFormField<String>).at(1);
      await tester.tap(paymentFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paid Only').last);
      await tester.pumpAndSettle();
      
      final avgRevenueText = find.textContaining(RegExp(r'Avg. Revenue/Job.*\$0\.00')); // Updated label
      expect(avgRevenueText, findsOneWidget, reason: "Average Revenue should be $0.00 when no jobs match filter"); // Updated reason
    });
  });

  group('JobStatsPage - Chart Data Generation Tests', () { // Updated group description
    late MockCargoJobProvider mockCargoJobProvider; // Updated type
    _JobStatsPageState? pageState;  // Updated type

    setUp(() {
      mockCargoJobProvider = MockCargoJobProvider(); // Updated type
      when(mockCargoJobProvider.jobs).thenReturn(sampleCargoJobs);
      when(mockCargoJobProvider.completedJobs).thenReturn(sampleCargoJobs.where((j) => j['delivery_status'] == 'completed').toList());
      when(mockCargoJobProvider.pendingJobs).thenReturn(sampleCargoJobs.where((j) => j['delivery_status'] == 'pending').toList());
      when(mockCargoJobProvider.cancelledJobs).thenReturn([]); 
      when(mockCargoJobProvider.onHoldJobs).thenReturn([]); 
      when(mockCargoJobProvider.paidJobs).thenReturn(paidJobsSample);
      when(mockCargoJobProvider.pendingPayments).thenReturn(pendingJobsSample);
      when(mockCargoJobProvider.overduePayments).thenReturn(overdueJobsSample);
    });

    Future<void> pumpAndGetState(WidgetTester tester, MockCargoJobProvider mockProvider) async { // Updated type
      GlobalKey<_JobStatsPageState> pageKey = GlobalKey(); // Updated type
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CargoJobProvider>.value(value: mockProvider), // Updated type
          ],
          child: MaterialApp(
            home: Scaffold(body: JobStatsPage(key: pageKey)), // Updated type
          ),
        ),
      );
      await tester.pumpAndSettle();
      pageState = pageKey.currentState;
      expect(pageState, isNotNull, reason: "Could not get state of JobStatsPage"); // Updated reason
    }
    
    testWidgets('Revenue by Delivery Status data is correct', (WidgetTester tester) async { // Updated test desc
      await pumpAndGetState(tester, mockCargoJobProvider);

      pageState!.setState(() {
        pageState!.selectedRange = 'Last 6 Months';
      });
      pageState!._processAndFilterData(); // Uses new field names internally
      await tester.pumpAndSettle();

      final List<ChartData> revenueByStatus = pageState!._getRevenueByDeliveryStatusData(); // Renamed method
      
      // Expected (Paid + Pending, Last 6 Months - includes all sampleCargoJobs):
      // delivery_status 'completed': $100 (paid) + $150 (paid) + $250 (pending) + $50 (paid) = $550
      // delivery_status 'pending': $200 (pending) + $300 (overdue_payment, delivery_status:pending) + $75 (pending) = $575
      
      expect(revenueByStatus.firstWhere((d) => d.x == 'COMPLETED').y, closeTo(550.0, 0.01));
      expect(revenueByStatus.firstWhere((d) => d.x == 'PENDING').y, closeTo(575.0, 0.01));
      // Ensure other statuses (CANCELLED, OVERDUE from onhold) are zero or not present based on sample data
      expect(revenueByStatus.where((d) => d.x == 'CANCELLED').every((d) => d.y == 0.0), isTrue);
      expect(revenueByStatus.where((d) => d.x == 'OVERDUE').every((d) => d.y == 0.0), isTrue); // as 'onhold' isn't in sample delivery_status
    });

    testWidgets('Revenue by Top 5 Dropoff Location data is correct', (WidgetTester tester) async { // Updated test desc
      await pumpAndGetState(tester, mockCargoJobProvider);
      pageState!.setState(() {
        pageState!.selectedRange = 'Last 6 Months';
      });
      pageState!._processAndFilterData(); // Uses new field names internally
      await tester.pumpAndSettle();

      final List<ChartData> top5Dest = pageState!._getRevenueByTop5DropoffLocationData(); // Renamed method

      // Expected (Paid + Pending, Last 6 Months, using agreed_price and dropoff_location):
      // City X: $100 + $250 + $75 = $425
      // City Y: $150 + $300 = $450
      // City Z: $200 + $50 = $250
      // Sorted: City Y ($450), City X ($425), City Z ($250)
      
      expect(top5Dest.length, 3); 
      expect(top5Dest[0].x, 'City Y'); expect(top5Dest[0].y, closeTo(450.0, 0.01));
      expect(top5Dest[1].x, 'City X'); expect(top5Dest[1].y, closeTo(425.0, 0.01));
      expect(top5Dest[2].x, 'City Z'); expect(top5Dest[2].y, closeTo(250.0, 0.01));
    });

    testWidgets('Job Status Distribution Pie Chart data is correct', (WidgetTester tester) async { // Updated test desc
      await pumpAndGetState(tester, mockCargoJobProvider);
      
      final List<StatusData> pieData = pageState!._getJobStatusDistributionData(); // Renamed method

      // Based on sampleCargoJobs and delivery_status:
      // Completed: 4 (id1, id2, id4, id6)
      // Pending: 3 (id3, id5, id7)
      // Cancelled: 0
      // OnHold (mapped to Overdue in chart): 0
      
      expect(pieData.firstWhere((d) => d.status == 'Completed').count, 4);
      expect(pieData.firstWhere((d) => d.status == 'Pending').count, 3);
      expect(pieData.firstWhere((d) => d.status == 'Cancelled').count, 0);
      expect(pieData.firstWhere((d) => d.status == 'Overdue').count, 0); 
    });
  });
}
