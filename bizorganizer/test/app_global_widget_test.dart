import 'package:bizorganizer/providers/loading_provider.dart'; // For GlobalLoadingIndicator and LoadingProvider
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // To find the SpinKitSquareCircle

void main() {
  group('GlobalLoadingIndicator visibility tests', () {
    late LoadingProvider loadingProvider;

    setUp(() {
      // Use a real LoadingProvider instance as it's simple and handles notifyListeners correctly.
      loadingProvider = LoadingProvider();
    });

    Future<void> pumpTestWidget(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<LoadingProvider>.value(value: loadingProvider),
            ],
            child: Scaffold( // Using Scaffold as a simple host
              body: Stack(
                children: [
                  const Text("Content Screen"), // Placeholder for Dashboard/SignInScreen
                  Consumer<LoadingProvider>(
                    builder: (context, providerInstance, child) {
                      // Accessing the providerInstance passed by Consumer
                      return providerInstance.isLoading
                          ? GlobalLoadingIndicator(loadState: true) 
                          : SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Indicator not visible initially (isLoading is false)', (WidgetTester tester) async {
      // loadingProvider.isLoading is false by default after instantiation
      await pumpTestWidget(tester);

      // Verify GlobalLoadingIndicator is not present
      expect(find.byType(GlobalLoadingIndicator), findsNothing);
      // Verify the specific spinner is not present
      expect(find.byType(SpinKitSquareCircle), findsNothing);
    });

    testWidgets('Indicator visible when loading (isLoading is true)', (WidgetTester tester) async {
      // Set loading to true
      loadingProvider.setLoading(true); // This calls notifyListeners internally

      await pumpTestWidget(tester);
      
      // Important: Need to pump again after state change if the change happens
      // after the initial pumpTestWidget call structure.
      // However, here setLoading is called *before* pumpTestWidget in this specific test ordering.
      // If we were to call setLoading *after* an initial pump, an extra tester.pump() would be needed.
      // For clarity and robustness if test order changes:
      await tester.pump(); // Ensure UI updates if setLoading was called after an initial build.
                           // If pumpTestWidget is the first build after setLoading, this might be redundant
                           // but doesn't harm.

      // Verify GlobalLoadingIndicator is present
      expect(find.byType(GlobalLoadingIndicator), findsOneWidget);
      // Verify the specific spinner is present
      expect(find.byType(SpinKitSquareCircle), findsOneWidget);
    });

    testWidgets('Indicator hides when loading state changes from true to false', (WidgetTester tester) async {
      // 1. Start with loading true
      loadingProvider.setLoading(true);
      await pumpTestWidget(tester);
      await tester.pump(); // Ensure it's built in the loading state

      expect(find.byType(GlobalLoadingIndicator), findsOneWidget, reason: "Should be visible initially with isLoading true");
      expect(find.byType(SpinKitSquareCircle), findsOneWidget, reason: "Spinner should be visible initially");

      // 2. Change loading state to false
      loadingProvider.setLoading(false); // This calls notifyListeners
      await tester.pump(); // Rebuild the widget tree with the new state

      // Verify GlobalLoadingIndicator is not present
      expect(find.byType(GlobalLoadingIndicator), findsNothing, reason: "Should hide when isLoading becomes false");
      // Verify the specific spinner is not present
      expect(find.byType(SpinKitSquareCircle), findsNothing, reason: "Spinner should hide when isLoading becomes false");
    });
  });
}
