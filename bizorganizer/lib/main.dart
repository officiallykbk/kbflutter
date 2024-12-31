import 'package:bizorganizer/dashboard.dart';
import 'package:bizorganizer/providers/loading_provider.dart';
import 'package:bizorganizer/providers/orders_providers.dart';
import 'package:bizorganizer/signin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://uebnszlrsqnkddwfzcxd.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVlYm5zemxyc3Fua2Rkd2Z6Y3hkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA5NzExMjcsImV4cCI6MjA0NjU0NzEyN30.8MW_ZQhV9A-uLTzsxLtWY6XoKqb6K5DQjR1OKq5rzoM',
  );

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => TripsProvider()..fetchTripsData()),
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
      home:
          // Dashboard()
          StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // Waiting for the initial auth state to load
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: SpinKitSquareCircle(
                  color: Colors.blue,
                ),
              ),
            );
          }

          // Checking if a user session is present
          final session = snapshot.data?.session;
          if (session != null) {
            return Dashboard(); // User is authenticated
          } else {
            return SignInScreen(); // No user session, redirect to SignIn
          }
        },
      ),
    );
  }
}
