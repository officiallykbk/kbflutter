import 'package:biz/dashboard.dart';
import 'package:biz/firebase_options.dart';
import 'package:biz/providers/orders_providers.dart';
import 'package:biz/signin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => OrdersProviders())],
      child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'BizOrganizer',
        theme: ThemeData(
            appBarTheme: const AppBarTheme(
                color: Colors.transparent, foregroundColor: Colors.white),
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color.fromARGB(255, 1, 26, 46),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: const TextStyle(color: Colors.white),
            )),
        debugShowCheckedModeBanner: false,
        home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, AsyncSnapshot<User?> snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Dashboard();
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                      child: SpinKitSquareCircle(
                    color: Colors.blue,
                  )),
                );
              }
              return SignInScreen();
            }));
  }
}
