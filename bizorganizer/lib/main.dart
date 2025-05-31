import 'package:bizorganizer/dashboard.dart'; // Keep for AuthHandlerScreen
import 'package:bizorganizer/providers/loading_provider.dart';
import 'package:bizorganizer/providers/orders_providers.dart';
import 'package:bizorganizer/signin.dart'; // Keep for AuthHandlerScreen
import 'package:bizorganizer/splash_screen.dart'; // Import splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Keep for GlobalLoadingIndicator if used, or remove if splash replaces all initial loading
import 'package:provider/provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://legzptivatldmbgxhwus.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxlZ3pwdGl2YXRsZG1iZ3hod3VzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIyNjE5MjIsImV4cCI6MjA1NzgzNzkyMn0.1N1Igp__28AxXtD4Lw7x6ja1_pBxoHN-0m6fHCXfMDM',
  );
        
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => LoadingProvider()), // LoadingProvider first
    ChangeNotifierProvider( // Then CargoJobProvider
      create: (context) {
        final loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
        final cargoJobProvider = CargoJobProvider(loadingProvider);
        // cargoJobProvider.fetchJobsData(); // Call fetchJobsData here
        return cargoJobProvider;
      },
    ),
  ], child: const MyApp()));
}

final supabase = Supabase.instance.client;
final String businessName = 'BizOrganizer';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BizOrganizer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          primary: Colors.deepPurple,
          secondary: Colors.orangeAccent,
          tertiary: Colors.greenAccent,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87, fontSize: 18),
          bodyMedium: TextStyle(color: Colors.black87, fontSize: 16),
          headlineSmall: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(color: Colors.black54),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.deepPurpleAccent,
        ),
        cardTheme: CardTheme(
          color: Colors.deepPurple.shade50,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 4,
        ),
        iconTheme:
            const IconThemeData(color: Colors.deepPurpleAccent, size: 24),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
          secondary: Colors.tealAccent,
          surface: Color(0xFF1F1F1F),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white70, fontSize: 18),
          bodyMedium: TextStyle(color: Colors.white60, fontSize: 16),
          headlineSmall: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(color: Colors.white54),
        ),
        cardTheme: CardTheme(
          color: Color(0xFF1F1F1F),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        iconTheme: const IconThemeData(color: Colors.tealAccent, size: 24),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const BizSplashScreen(), // Set BizSplashScreen as home
    );
  }
}

// The GlobalLoadingIndicator logic is now separate.
// If it needs to overlay the entire app (post-splash),
// the structure of how BizSplashScreen navigates to AuthHandlerScreen,
// and then to Dashboard/SignInScreen needs to be such that MaterialApp's builder
// or a root widget wraps the authenticated app part with the Stack and Consumer.
// For now, per instruction, home is just BizSplashScreen.
// The existing Stack in main.dart for GlobalLoadingIndicator has been removed by this change.
// To keep GlobalLoadingIndicator, it should be added to the screens loaded *after* the splash.
// Or, MaterialApp's `builder` property could be used.

// Let's assume the Stack for GlobalLoadingIndicator should remain at MaterialApp level.
// This means BizSplashScreen should not be `home`, but part of the Stack.
// Re-interpreting: The home *content* (StreamBuilder) is replaced by BizSplashScreen,
// but the Stack for GlobalLoadingIndicator remains.

/*
Alternative interpretation based on keeping the GlobalLoadingIndicator Stack:
      home: Stack(
        children: [
          const BizSplashScreen(), // BizSplashScreen replaces the StreamBuilder
          Consumer<LoadingProvider>(
            builder: (context, loadingProvider, child) {
              return loadingProvider.isLoading
                  ? GlobalLoadingIndicator(loadState: true)
                  : SizedBox.shrink();
            },
          ),
        ],
      ),
*/
// The most direct interpretation of "change the home property ... to be const BizSplashScreen()"
// is what was initially done. If the GlobalLoadingIndicator is meant to persist over everything
// including the splash screen (which is unusual), or over the app *after* the splash,
// then the structure in main.dart's build or the navigation from AuthHandlerScreen needs adjustment.

// Given the code in splash_screen.dart, AuthHandlerScreen itself returns a Scaffold,
// which means it's intended to be a full screen.
// The GlobalLoadingIndicator should ideally be part of the MaterialApp's builder
// or on top of the Navigator.

// For this step, I will stick to the direct instruction: home: const BizSplashScreen();
// This means the GlobalLoadingIndicator which was previously in the Stack in main.dart's home
// is removed. If it needs to be re-added, it would typically be inside the Dashboard and SignInScreen,
// or using a builder in MaterialApp.
