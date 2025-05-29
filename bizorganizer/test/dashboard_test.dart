import 'package:bizorganizer/dashboard.dart';
import 'package:bizorganizer/providers/loading_provider.dart';
import 'package:bizorganizer/providers/orders_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart'; // For @GenerateMocks if used
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // For AuthState and Supabase client mock if needed

// It's good practice to have a common place for mocks or generate them.
// Since build_runner is an issue, we'll define a simple mock manually.

class MockCargoJobProvider extends Mock implements CargoJobProvider {
  // Manual stubbing for getters used by Dashboard
  @override
  List<Map<String, dynamic>> get jobs => _mockJobs; // Default to empty or specific mock
  List<Map<String, dynamic>> _mockJobs = [];

  void setMockJobs(List<Map<String, dynamic>> jobs) {
    _mockJobs = jobs;
    // notifyListeners(); // Not strictly needed if tests don't rely on provider listening for this change
  }

  // Constructor needs to satisfy the base class if it has required args.
  // CargoJobProvider now expects a LoadingProvider.
  MockCargoJobProvider(LoadingProvider loadingProvider) : super(loadingProvider);

  // If other methods like fetchJobsData are called, they might need stubbing if they affect UI
  @override
  Future<void> fetchJobsData() async {
    // Do nothing or simulate a delay if needed
    return Future.value();
  }
}

class MockLoadingProvider extends Mock implements LoadingProvider {
  bool _isLoadingValue = false;

  @override
  bool get isLoading => _isLoadingValue;

  @override
  void setLoading(bool value) {
    _isLoadingValue = value;
    // notifyListeners(); // Mockito mocks don't call notifyListeners automatically
  }

  // Manual way to set and notify for testing purposes if needed,
  // but for dashboard test, initial state might be enough.
  void testSetLoading(bool value) {
    _isLoadingValue = value;
    // If we had a real ChangeNotifier, we'd call notifyListeners() here.
    // For a simple mock, direct stubbing of `isLoading` is often sufficient.
  }
}


// Mock Supabase Client if direct calls are made in widgets (not typical for provider-based apps)
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockAuthState extends Mock implements AuthState {}


void main() {
  late MockCargoJobProvider mockCargoJobProvider;
  late MockLoadingProvider mockLoadingProvider;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;

  setUp(() {
    // Initialize mock loading provider
    mockLoadingProvider = MockLoadingProvider();
    mockLoadingProvider.testSetLoading(false); // Default to not loading

    // Initialize mock cargo job provider, passing the loading provider
    mockCargoJobProvider = MockCargoJobProvider(mockLoadingProvider);

    // Mock Supabase client and auth
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    
    // Stub the auth client getter
    when(mockSupabaseClient.auth).thenReturn(mockGoTrueClient);

    // Stub the onAuthStateChange stream
    // Create a mock AuthState or use a real one if simple
    final mockAuthState = MockAuthState();
    // when(mockAuthState.session).thenReturn(null); // Or a mock Session
    
    // Return a stream that emits a mock AuthState or a real one
    when(mockGoTrueClient.onAuthStateChange).thenAnswer((_) => Stream.value(mockAuthState));

    // It's important that the Dashboard's StreamBuilder for Supabase auth state
    // receives a valid stream. For this test, we assume not logged in or handle as needed.
    // If Dashboard directly uses supabase.auth.onAuthStateChange, it needs mocking.
    // The actual Supabase instance is global; this is tricky.
    // For widget tests, it's best if such global dependencies are injectable or wrapped.
    // For now, we assume the Dashboard will render its core UI (like CustomScrollView)
    // even if the auth stream is minimal or not fully mocked for deep interaction.
  });

  Future<void> pumpDashboard(WidgetTester tester) async {
    // Provide the global Supabase client if it's accessed directly.
    // This is a simplified approach. Ideally, use an inherited widget or provider for Supabase.
    // For this test, we'll focus on the parts of Dashboard not deeply tied to Supabase auth state changes.
    
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CargoJobProvider>.value(value: mockCargoJobProvider),
          ChangeNotifierProvider<LoadingProvider>.value(value: mockLoadingProvider),
        ],
        child: MaterialApp(
          home: Dashboard(), // Dashboard itself
        ),
      ),
    );
    // Dashboard uses a StreamBuilder for _jobsStream which comes from Supabase.
    // This stream is initialized in initState.
    // We need to ensure this stream doesn't throw errors.
    // The _getJobsStream method uses the global `supabase` instance.
    // This is a challenge for widget testing.
    // A simple way is to ensure the stream provides some data or completes.
    // For now, the mockCargoJobProvider.jobs will be used by parts of the UI.
    // The StreamBuilder for _jobsStream might need more specific mocking if it's causing issues.
    await tester.pumpAndSettle(); // Allow time for async operations like streams/futures in initState
  }

  testWidgets('Dashboard renders job list components when jobs are empty', (WidgetTester tester) async {
    mockCargoJobProvider.setMockJobs([]); // Ensure jobs are empty
    
    await pumpDashboard(tester);

    expect(find.byType(CustomScrollView), findsOneWidget);
    // The job list is the 3rd sliver.
    // If it's empty, it might not render a SliverList with items, or render an empty state.
    // The structure is SliverPadding -> SliverList.
    // Let's check for the presence of the SliverPadding that wraps the job list.
    // This is less brittle than checking for SliverList if it's conditionally rendered.
    // However, the code shows SliverList is always there, its childCount is just 0.
    expect(find.byType(SliverList), findsNWidgets(2)); // One for summary cards, one for jobs
    
    // Verify "No jobs available." text when job list is empty
    expect(find.text('No jobs available.'), findsNothing); // This is inside StreamBuilder, if stream is empty.
                                                          // Our provider gives empty list, so this should not show.
                                                          // The StreamBuilder itself shows this for its own empty data.
                                                          // Let's assume displayJobs becomes empty from provider.

    // The test setup needs to be more robust regarding the StreamBuilder for jobs.
    // The Dashboard's _jobsStream directly calls the global supabase instance.
    // This makes isolated widget testing hard.
    // If we focus on the provider's role:
    // The UI calculates counts based on `displayJobs` which falls back to `allJobs` (from provider).
    // If `allJobs` is empty, then `_totalJobsCount` is 0.
    // The `SliverChildBuilderDelegate` for jobs will have `childCount: 0`.

    // At least one Card for Revenue Overview, and potentially for Summary Cards
    expect(find.byType(Card), findsWidgets); // Revenue + Summary cards
  });

  testWidgets('Dashboard renders job cards if jobs are provided by provider', (WidgetTester tester) async {
    mockCargoJobProvider.setMockJobs([
      {'id': '1', 'shipper_name': 'Test Shipper 1', 'delivery_status': 'Pending', 'payment_status': 'Paid', 'agreed_price': 100.0},
      {'id': '2', 'shipper_name': 'Test Shipper 2', 'delivery_status': 'Delivered', 'payment_status': 'Pending', 'agreed_price': 200.0},
    ]);

    await pumpDashboard(tester);

    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byType(SliverList), findsNWidgets(2)); // Summary cards + Job list

    // Check for job card specific widgets (e.g., ListTile, or text from the job)
    expect(find.text('Test Shipper 1'), findsOneWidget);
    expect(find.text('Test Shipper 2'), findsOneWidget);
    expect(find.byIcon(Icons.local_shipping), findsNWidgets(2)); // One per job card
  });
}

// Note:
// 1. Mocking Supabase global instance is complex for widget tests.
//    The tests above are simplified and might need adjustment if Supabase interactions
//    in initState or build methods are critical and not properly mocked.
//    Ideally, Supabase client should be provided via Provider or get_it.
// 2. The Dashboard's _jobsStream uses the global `supabase` instance. This stream
//    is used by a StreamBuilder. If this stream isn't properly handled/mocked,
//    it could lead to test failures or unexpected behavior.
//    The current mock setup for Supabase is basic and might not cover this stream.
//    The tests rely more on `jobProvider.jobs` being used by the UI.
// 3. `MockCargoJobProvider` is defined manually. If `@GenerateMocks` were working,
//    it would generate a more complete mock.
// 4. The dashboard's StreamBuilder for auth state is also a factor. The current mock setup
//    provides a basic stream for it.
// 5. The test "Dashboard renders job list components when jobs are empty"
//    has a nuance: "No jobs available." is shown if `displayJobs` is empty.
//    `displayJobs` is `snapshot.data ?? allJobs`. If the stream itself (snapshot.data)
//    is what becomes empty, that text appears. If `allJobs` (from provider) is empty,
//    the list renders with 0 items.
//    The setup for `_jobsStream` in `Dashboard` makes it hard to control `snapshot.data`
//    in this test without a more elaborate Supabase mock.
//    The tests assume `allJobs` from the provider is the primary source for now.The file `bizorganizer/test/dashboard_test.dart` has been created with the specified content in the previous turn.

It includes:
1.  Manual mocks for `MockCargoJobProvider` and `MockLoadingProvider`.
2.  Basic mocks for Supabase related classes (`MockSupabaseClient`, `MockGoTrueClient`, `MockAuthState`) with a simplified setup for the auth stream.
3.  A `pumpDashboard` helper function to wrap `Dashboard` with `MaterialApp` and `MultiProvider`.
4.  Two test cases:
    *   "Dashboard renders job list components when jobs are empty": Checks for `CustomScrollView`, `SliverList`s, and presence of `Card`s (for revenue/summary).
    *   "Dashboard renders job cards if jobs are provided by provider": Provides mock jobs and checks for widgets specific to job cards (e.g., shipper names, icons).

Notes on limitations due to the global Supabase instance and potential `build_runner` issues were included in the generated file.

Now, I will proceed with Part 2: Creating `bizorganizer/test/app_global_widget_test.dart`.
