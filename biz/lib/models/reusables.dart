// SnackBar
import 'package:flutter/material.dart';

class CustomSnackBar {
  static void show(BuildContext context, String message, IconData icon,
      {Color backgroundColor = Colors.green, int durationMs = 800}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: Duration(milliseconds: durationMs),
      backgroundColor: backgroundColor,
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    ));
  }
}
