import 'package:calculator/calculator_provider.dart';
import 'package:calculator/calculator_riverpod.dart';
import 'package:calculator/homeV1.dart';
import 'package:calculator/riverpodHomeV1.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

//For provider
// void main() {
//   runApp(MultiProvider(
//       providers: [ChangeNotifierProvider(create: (_) => Calc_provider())],
//       child: const MyApp()));
// }

//For riverpod
void main() {
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData.dark(),
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        textTheme:
            TextTheme(bodyMedium: TextStyle(fontSize: 40, color: Colors.white)),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: home2(),
    );
  }
}
