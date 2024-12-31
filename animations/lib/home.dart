import 'dart:math';

import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 10));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..rotateZ(_controller.value * 2 * pi)
                  ..rotateY(_controller.value * 2 * pi)
                  ..rotateZ(_controller.value * 2 * pi),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(color: Colors.red, height: 100),
                    Container(color: Colors.blue, height: 100),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
