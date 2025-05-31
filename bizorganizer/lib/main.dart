import 'package:bizorganizer/dashboard.dart';
import 'package:bizorganizer/providers/loading_provider.dart';
import 'package:bizorganizer/providers/orders_providers.dart';
import 'package:bizorganizer/signin.dart';
import 'package:bizorganizer/splash_screen.dart'; // Import the new splash screen
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Keep for now, might be used by GlobalLoadingIndicator if not removed
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Keep for AuthState if needed elsewhere, or supabase instance
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bizorganizer/models/cargo_job.dart';
import 'package:bizorganizer/models/offline_change.dart'; // Import OfflineChange model and adapters

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized

  await Supabase.initialize(
    url: 'https://legzptivatldmbgxhwus.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxlZ3pwdGl2YXRsZG1iZ3hod3VzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIyNjE5MjIsImV4cCI6MjA1NzgzNzkyMn0.1N1Igp__28AxXtD4Lw7x6ja1_pBxoHN-0m6fHCXfMDM',
  );

  await Hive.initFlutter();
  Hive.registerAdapter(CargoJobAdapter());
  Hive.registerAdapter(ChangeOperationAdapter()); // Register ChangeOperationAdapter
  Hive.registerAdapter(OfflineChangeAdapter()); // Register OfflineChangeAdapter
  await Hive.openBox<CargoJob>('cargoJobsBox');
  await Hive.openBox<OfflineChange>('offlineChangesBox'); // Open OfflineChange box
        
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => CargoJobProvider()..fetchJobsData()), // Updated Provider
    ChangeNotifierProvider(create: (_) => LoadingProvider())
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
      home: const BizSplashScreen(), // Set BizSplashScreen as the initial screen
      // The StreamBuilder logic for auth is now handled by AuthHandlerScreen after the splash.
    );
  }
}
