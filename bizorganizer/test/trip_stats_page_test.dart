import 'package:bizorganizer/providers/orders_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

// Define MockTripsProvider by extending Mock and implementing TripsProvider
class MockTripsProvider extends Mock implements TripsProvider {
  // If TripsProvider has methods that return Futures or Streams,
  // you might need to provide default implementations here or when setting up mocks.

  // Example: If TripsProvider has a method like `fetchTripsData()`,
  // you might need:
  // @override
  // Future<void> fetchTripsData() async {
  //   // Mock implementation or just return a completed future
  //   return Future.value();
  // }

  // Mock the getters that TripStatsPage uses
  // These will be overridden in tests with specific mock data
  @override
  List<Map<String, dynamic>> get trips => [];

  @override
  List<Map<String, dynamic>> get completedTrips => [];

  @override
  List<Map<String, dynamic>> get pendingTrips => [];

  @override
  List<Map<String, dynamic>> get cancelledTrips => [];
  
  @override
  List<Map<String, dynamic>> get onHoldTrips => [];

  @override
  List<Map<String, dynamic>> get paidTrips => [];

  @override
  List<Map<String, dynamic>> get pendingPayments => [];
  
  @override
  List<Map<String, dynamic>> get overduePayments => [];


}

void main() {
  // Sample trip data for testing
  final sampleTrips = [
    // Paid Trips
    {'id': '1', 'clientName': 'Client A', 'amount': 100.0, 'paymentStatus': 'paid', 'orderStatus': 'completed', 'created_at': DateTime(2023, 1, 15).toIso8601String(), 'destination': 'City X'},
    {'id': '2', 'clientName': 'Client B', 'amount': 150.0, 'paymentStatus': 'paid', 'orderStatus': 'completed', 'created_at': DateTime(2023, 1, 20).toIso8601String(), 'destination': 'City Y'},
    // Pending Payment Trips
    {'id': '3', 'clientName': 'Client C', 'amount': 200.0, 'paymentStatus': 'pending', 'orderStatus': 'pending', 'created_at': DateTime(2023, 2, 10).toIso8601String(), 'destination': 'City Z'},
    {'id': '4', 'clientName': 'Client D', 'amount': 250.0, 'paymentStatus': 'pending', 'orderStatus': 'completed', 'created_at': DateTime(2023, 2, 15).toIso8601String(), 'destination': 'City X'},
    // Overdue Trips (assuming 'overdue' is a valid paymentStatus from data source)
    {'id': '5', 'clientName': 'Client E', 'amount': 300.0, 'paymentStatus': 'overdue', 'orderStatus': 'pending', 'created_at': DateTime(2023, 3, 1).toIso8601String(), 'destination': 'City Y'},
    // Another Paid Trip for date filtering tests
    {'id': '6', 'clientName': 'Client F', 'amount': 50.0, 'paymentStatus': 'paid', 'orderStatus': 'completed', 'created_at': DateTime(2023, 3, 5).toIso8601String(), 'destination': 'City Z'},
    // Another Pending Trip for date filtering tests
    {'id': '7', 'clientName': 'Client G', 'amount': 75.0, 'paymentStatus': 'pending', 'orderStatus': 'pending', 'created_at': DateTime(2023, 3, 10).toIso8601String(), 'destination': 'City X'},
  ];

  final paidTripsSample = sampleTrips.where((t) => t['paymentStatus'] == 'paid').toList();
  final pendingTripsSample = sampleTrips.where((t) => t['paymentStatus'] == 'pending').toList();
  final overdueTripsSample = sampleTrips.where((t) => t['paymentStatus'] == 'overdue').toList();


  // Helper function to pump TripStatsPage with MockTripsProvider
  Future<void> pumpTripStatsPage(WidgetTester tester, MockTripsProvider mockProvider) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TripsProvider>.value(value: mockProvider),
        ],
        child: MaterialApp(
          home: Scaffold( // TripStatsPage is typically a full page, so Scaffold is appropriate
            body: TripStatsPage(),
          ),
        ),
      ),
    );
    // Wait for any initial frame rendering or async operations like _processAndFilterData
    await tester.pumpAndSettle();
  }

  group('TripStatsPage - Payment Filtering Logic Tests', () {
    late MockTripsProvider mockTripsProvider;

    setUp(() {
      mockTripsProvider = MockTripsProvider();
      // Provide default values for all categories the page might try to access, even if empty.
      when(mockTripsProvider.trips).thenReturn(sampleTrips); // Main list used by _getRawTripsBasedOnPaymentFilter
      when(mockTripsProvider.completedTrips).thenReturn(sampleTrips.where((t) => t['orderStatus'] == 'completed').toList());
      when(mockTripsProvider.pendingTrips).thenReturn(sampleTrips.where((t) => t['orderStatus'] == 'pending').toList());
      when(mockTripsProvider.cancelledTrips).thenReturn(sampleTrips.where((t) => t['orderStatus'] == 'cancelled').toList()); // Assuming 'cancelled' is a status
      when(mockTripsProvider.onHoldTrips).thenReturn(sampleTrips.where((t) => t['orderStatus'] == 'onhold').toList()); // Assuming 'onhold' is a status
      when(mockTripsProvider.paidTrips).thenReturn(paidTripsSample);
      when(mockTripsProvider.pendingPayments).thenReturn(pendingTripsSample);
      when(mockTripsProvider.overduePayments).thenReturn(overdueTripsSample);

    });

    testWidgets('Filters for "Paid Only"', (WidgetTester tester) async {
      await pumpTripStatsPage(tester, mockTripsProvider);

      // Find the payment status filter DropdownButtonFormField
      // This assumes the DropdownButtonFormField for payment status has a unique enough finder.
      // If it's wrapped by a Card or specific parent, use that.
      // For now, we find it by type, assuming it's the second one or identifiable.
      final paymentFilterDropdown = find.byType(DropdownButtonFormField<String>).at(1); // Assuming it's the second one
      expect(paymentFilterDropdown, findsOneWidget);
      
      // Change the filter to "Paid Only"
      await tester.tap(paymentFilterDropdown);
      await tester.pumpAndSettle(); // Wait for dropdown items to appear
      await tester.tap(find.text('Paid Only').last); // .last is safer if text appears multiple times
      await tester.pumpAndSettle(); // Wait for filter change to process

      // Verification:
      // We need to access the state of TripStatsPage or check a KPI that reflects this filtering.
      // Since direct state access is hard, let's test a KPI. Total Revenue should only include paid trips.
      // Total paid revenue: 100.0 + 150.0 + 50.0 = 300.0
      // This test will be more robust once KPIs are fully integrated with the filtering.
      // For now, this test primarily ensures the filter can be changed.
      // A more direct test of `_getRawTripsBasedOnPaymentFilter` would be to call it via an exposed method on the state,
      // or check the `paymentFilteredTripsFullDetails` list if it were not private.

      // As a proxy for now, let's check if the "Total Revenue" KPI updates.
      // This requires the KPI to be wired correctly to the filtered data.
      // If `filteredRevenueData` is correctly updated by `_processAndFilterData` after the filter change,
      // then the "Total Revenue" KPI should reflect only paid amounts.
      final totalRevenueText = find.textContaining(RegExp(r'Total Revenue.*\$300\.00')); // Assuming currency formatting
      expect(totalRevenueText, findsOneWidget, reason: "Total Revenue should be $300.00 for 'Paid Only'");
    });

    testWidgets('Filters for "Pending Only"', (WidgetTester tester) async {
      await pumpTripStatsPage(tester, mockTripsProvider);
      
      final paymentFilterDropdown = find.byType(DropdownButtonFormField<String>).at(1);
      await tester.tap(paymentFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pending Only').last);
      await tester.pumpAndSettle();

      // Total pending revenue: 200.0 + 250.0 + 75.0 = 525.0
      final totalRevenueText = find.textContaining(RegExp(r'Total Revenue.*\$525\.00'));
      expect(totalRevenueText, findsOneWidget, reason: "Total Revenue should be $525.00 for 'Pending Only'");
    });

    testWidgets('Filters for "Paid + Pending"', (WidgetTester tester) async {
      await pumpTripStatsPage(tester, mockTripsProvider);

      // Default is "Paid + Pending", so no need to change the filter initially.
      // Total "Paid + Pending" revenue: 300.0 (paid) + 525.0 (pending) = 825.0
      final totalRevenueText = find.textContaining(RegExp(r'Total Revenue.*\$825\.00'));
      expect(totalRevenueText, findsOneWidget, reason: "Total Revenue should be $825.00 for 'Paid + Pending' (initial)");

      // Optional: Change to something else and back to ensure filter change logic works
      final paymentFilterDropdown = find.byType(DropdownButtonFormField<String>).at(1);
      await tester.tap(paymentFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paid Only').last);
      await tester.pumpAndSettle();

      await tester.tap(paymentFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paid + Pending').last);
      await tester.pumpAndSettle();
      
      expect(totalRevenueText, findsOneWidget, reason: "Total Revenue should be $825.00 for 'Paid + Pending' (after re-selecting)");
    });
  });

  group('TripStatsPage - KPI Calculation Tests', () {
    late MockTripsProvider mockTripsProvider;

    setUp(() {
      mockTripsProvider = MockTripsProvider();
      when(mockTripsProvider.trips).thenReturn(sampleTrips);
      when(mockTripsProvider.completedTrips).thenReturn(sampleTrips.where((t) => t['orderStatus'] == 'completed').toList());
      when(mockTripsProvider.pendingTrips).thenReturn(sampleTrips.where((t) => t['orderStatus'] == 'pending').toList());
      when(mockTripsProvider.cancelledTrips).thenReturn([]); // Assuming no cancelled for these specific KPI tests
      when(mockTripsProvider.onHoldTrips).thenReturn([]); // Assuming no onHold for these specific KPI tests
      when(mockTripsProvider.paidTrips).thenReturn(paidTripsSample);
      when(mockTripsProvider.pendingPayments).thenReturn(pendingTripsSample);
      when(mockTripsProvider.overduePayments).thenReturn(overdueTripsSample);
    });

    testWidgets('Total Revenue KPI is correct with "Paid Only" and specific date range', (WidgetTester tester) async {
      await pumpTripStatsPage(tester, mockTripsProvider);

      // Set Payment Filter to "Paid Only"
      final paymentFilterDropdown = find.byType(DropdownButtonFormField<String>).at(1);
      await tester.tap(paymentFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paid Only').last);
      await tester.pumpAndSettle();

      // Set Date Range Filter to "Last Month" (relative to a fixed "now" for testing, e.g., March 15, 2023)
      // For "Paid Only", trips are:
      // id 1: Jan 15, 2023, $100
      // id 2: Jan 20, 2023, $150
      // id 6: Mar 05, 2023, $50
      // If "now" is Mar 15, 2023, "Last Month" is Feb 2023. No paid trips in Feb. Revenue = $0.00
      // Let's adjust to test "Last 6 Months" to include Jan and Mar trips.
      // "Last 6 Months" from Mar 15, 2023 would be from Sep 16, 2022 to Mar 15, 2023.
      // This includes all paid trips: $100 + $150 + $50 = $300

      final dateFilterDropdown = find.byType(DropdownButtonFormField<String>).at(0); // Assuming Date Range is the first
      await tester.tap(dateFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 6 Months').last);
      await tester.pumpAndSettle();
      
      // Note: The date filtering in TripStatsPage uses DateTime.now(). For robust tests,
      // DateTime.now() should be mocked. Assuming for now the logic correctly filters based on current date.
      // For this example, we verify the sum based on sample data.
      // The sample data has dates in Jan and Mar 2023. If today is, for example, Mar 15, 2023,
      // "Last 6 Months" (from Sep 15, 2022 to Mar 15, 2023) includes all paid trips.
      final totalRevenueText = find.textContaining(RegExp(r'Total Revenue.*\$300\.00'));
      expect(totalRevenueText, findsOneWidget, reason: "Total Revenue for 'Paid Only' in 'Last 6 Months' should be $300.00");
    });

    testWidgets('Paid vs Pending Sub-KPI is correct when "Paid + Pending" is selected', (WidgetTester tester) async {
      await pumpTripStatsPage(tester, mockTripsProvider);
      // Default is "Paid + Pending"
      // Default date range is "Last 7 Days". 
      // To make this test robust without date mocking, let's use a wide date range like "Last 6 Months"
      // to ensure all sample data for "Paid + Pending" is included.

      final dateFilterDropdown = find.byType(DropdownButtonFormField<String>).at(0);
      await tester.tap(dateFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 6 Months').last);
      await tester.pumpAndSettle();

      // Paid revenue (all sample paid trips): $100 + $150 + $50 = $300
      // Pending revenue (all sample pending trips): $200 + $250 + $75 = $525
      final paidSubKpi = find.textContaining(RegExp(r'Paid:.*\$300\.00'));
      final pendingSubKpi = find.textContaining(RegExp(r'Pending:.*\$525\.00'));

      expect(paidSubKpi, findsOneWidget, reason: "Paid sub-KPI should be $300.00 for 'Paid + Pending' in 'Last 6 Months'");
      expect(pendingSubKpi, findsOneWidget, reason: "Pending sub-KPI should be $525.00 for 'Paid + Pending' in 'Last 6 Months'");
    });

    testWidgets('Average Revenue Per Trip KPI is correct', (WidgetTester tester) async {
      await pumpTripStatsPage(tester, mockTripsProvider);
      // Default: "Paid + Pending", "Last 7 Days".
      // Using "Last 6 Months" to include all data for predictability.
      final dateFilterDropdown = find.byType(DropdownButtonFormField<String>).at(0);
      await tester.tap(dateFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 6 Months').last);
      await tester.pumpAndSettle();

      // Total revenue for "Paid + Pending" = $300 (paid) + $525 (pending) = $825
      // Total trips for "Paid + Pending" = 3 (paid) + 3 (pending) = 6 trips
      // Average = $825 / 6 = $137.50
      final avgRevenueText = find.textContaining(RegExp(r'Avg. Revenue/Trip.*\$137\.50'));
      expect(avgRevenueText, findsOneWidget, reason: "Average Revenue for 'Paid + Pending' in 'Last 6 Months' should be $137.50");
    });

     testWidgets('Average Revenue Per Trip handles division by zero gracefully', (WidgetTester tester) async {
      // Override mock to return no trips for a specific filter combination
      when(mockTripsProvider.trips).thenReturn([]);
      when(mockTripsProvider.paidTrips).thenReturn([]);
      when(mockTripsProvider.pendingPayments).thenReturn([]);
      
      await pumpTripStatsPage(tester, mockTripsProvider);

      // Set filter to "Paid Only" (which will result in 0 trips based on the override)
      final paymentFilterDropdown = find.byType(DropdownButtonFormField<String>).at(1);
      await tester.tap(paymentFilterDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paid Only').last);
      await tester.pumpAndSettle();
      
      // Average should be $0.00
      final avgRevenueText = find.textContaining(RegExp(r'Avg. Revenue/Trip.*\$0\.00'));
      expect(avgRevenueText, findsOneWidget, reason: "Average Revenue should be $0.00 when no trips match filter");
    });
  });

  group('TripStatsPage - Chart Data Generation Tests', () {
    late MockTripsProvider mockTripsProvider;
    // State for TripStatsPage - needed to call methods directly or inspect properties
    _TripStatsPageState? pageState; 

    setUp(() {
      mockTripsProvider = MockTripsProvider();
      when(mockTripsProvider.trips).thenReturn(sampleTrips);
      when(mockTripsProvider.completedTrips).thenReturn(sampleTrips.where((t) => t['orderStatus'] == 'completed').toList());
      when(mockTripsProvider.pendingTrips).thenReturn(sampleTrips.where((t) => t['orderStatus'] == 'pending').toList());
      when(mockTripsProvider.cancelledTrips).thenReturn([]); 
      when(mockTripsProvider.onHoldTrips).thenReturn([]); 
      when(mockTripsProvider.paidTrips).thenReturn(paidTripsSample);
      when(mockTripsProvider.pendingPayments).thenReturn(pendingTripsSample);
      when(mockTripsProvider.overduePayments).thenReturn(overdueTripsSample);
    });

    // Helper to get the state. This is a bit of a workaround.
    // A better way might be to pass a GlobalKey to TripStatsPage if we need to access its state.
    // For now, we find the stateful widget and get its state.
    Future<void> pumpAndGetState(WidgetTester tester, MockTripsProvider mockProvider) async {
      GlobalKey<_TripStatsPageState> pageKey = GlobalKey();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TripsProvider>.value(value: mockProvider),
          ],
          child: MaterialApp(
            home: Scaffold(body: TripStatsPage(key: pageKey)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      pageState = pageKey.currentState;
      expect(pageState, isNotNull, reason: "Could not get state of TripStatsPage");
    }
    
    testWidgets('Revenue by Order Status data is correct', (WidgetTester tester) async {
      await pumpAndGetState(tester, mockTripsProvider);

      // Default filters: "Paid + Pending", "Last 7 Days"
      // To make test predictable, let's set date range to "Last 6 Months"
      // This should include all sample data.
      pageState!.setState(() {
        pageState!.selectedRange = 'Last 6 Months';
      });
      // Manually trigger data processing after state change
      pageState!._processAndFilterData();
      await tester.pumpAndSettle();


      final List<ChartData> revenueByOrderStatus = pageState!._getRevenueByOrderStatusData();
      
      // Expected (Paid + Pending, Last 6 Months - includes all sample data):
      // Completed: $100 (paid) + $150 (paid) + $250 (pending) + $50 (paid) = $550
      // Pending: $200 (pending) + $300 (overdue, but maps to 'pending' orderStatus) + $75 (pending) = $575
      // Note: The sample data has 'overdue' as a paymentStatus, not an orderStatus.
      // The mapping in _getRevenueByOrderStatusData is:
      // 'in progress' -> 'pending', 'refunded' -> 'cancelled', 'onhold' -> 'overdue'
      // Sample data order statuses: 'completed', 'pending'. No 'in progress', 'refunded', 'onhold'.
      // So, expected based on sample data:
      // COMPLETED: $100 (id1,paid) + $150 (id2,paid) + $250 (id4,pending) + $50 (id6,paid) = $550
      // PENDING: $200 (id3,pending) + $300 (id5,overdue_payment, order_status:pending) + $75 (id7,pending) = $575
      
      expect(revenueByOrderStatus.firstWhere((d) => d.x == 'COMPLETED').y, closeTo(550.0, 0.01));
      expect(revenueByOrderStatus.firstWhere((d) => d.x == 'PENDING').y, closeTo(575.0, 0.01));
      expect(revenueByOrderStatus.where((d) => d.x == 'CANCELLED').isEmptyOr((d) => d.y == 0), isTrue);
      expect(revenueByOrderStatus.where((d) => d.x == 'OVERDUE').isEmptyOr((d) => d.y == 0), isTrue);
    });

    testWidgets('Revenue by Top 5 Destination data is correct', (WidgetTester tester) async {
      await pumpAndGetState(tester, mockTripsProvider);
      // Default filters: "Paid + Pending", "Last 7 Days"
      // Set date range to "Last 6 Months" for all sample data
      pageState!.setState(() {
        pageState!.selectedRange = 'Last 6 Months';
      });
      pageState!._processAndFilterData();
      await tester.pumpAndSettle();

      final List<ChartData> top5Dest = pageState!._getRevenueByTop5DestinationData();

      // Expected (Paid + Pending, Last 6 Months):
      // City X: $100 (id1) + $250 (id4) + $75 (id7) = $425
      // City Y: $150 (id2) + $300 (id5) = $450
      // City Z: $200 (id3) + $50 (id6) = $250
      // Sorted: City Y ($450), City X ($425), City Z ($250)
      
      expect(top5Dest.length, 3); // Only 3 unique destinations in sample
      expect(top5Dest[0].x, 'City Y'); expect(top5Dest[0].y, closeTo(450.0, 0.01));
      expect(top5Dest[1].x, 'City X'); expect(top5Dest[1].y, closeTo(425.0, 0.01));
      expect(top5Dest[2].x, 'City Z'); expect(top5Dest[2].y, closeTo(250.0, 0.01));
    });

    testWidgets('Trip Status Distribution Pie Chart data is correct', (WidgetTester tester) async {
      // This chart uses overall counts from the provider, not filtered by date/payment on the page.
      await pumpAndGetState(tester, mockTripsProvider);
      
      // Get the data used by the pie chart
      final List<StatusData> pieData = pageState!._getTripStatusDistributionData();

      // Based on sampleTrips and how MockTripsProvider is set up for these general counts:
      // Completed: 4 (id1, id2, id4, id6)
      // Pending: 3 (id3, id5, id7)
      // Cancelled: 0
      // OnHold (mapped to Overdue in chart): 0
      
      expect(pieData.firstWhere((d) => d.status == 'Completed').count, 4);
      expect(pieData.firstWhere((d) => d.status == 'Pending').count, 3);
      expect(pieData.firstWhere((d) => d.status == 'Cancelled').count, 0);
      expect(pieData.firstWhere((d) => d.status == 'Overdue').count, 0); // Based on onHoldTrips being empty
    });

  });
}
