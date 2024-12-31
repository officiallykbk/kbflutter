import 'package:flutter/material.dart';
import 'package:flutter_youtube/navbar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(elevation: 0, toolbarHeight: 40),
        textTheme: const TextTheme(),
        // brightness: Brightness.dark,
      ),
      home: const NavBar(),
    );
  }
}
