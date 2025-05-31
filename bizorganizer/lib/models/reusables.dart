// SnackBar
import 'package:flutter/material.dart';

class CustomSnackBar {
  static void show(BuildContext context, String message, String state,
      { int durationMs = 800}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: Duration(milliseconds: durationMs),
      backgroundColor: state == 'error' ? Colors.red : Colors.green,
      content: Row(
        children: [
          Icon(state == 'error' ? Icons.error : Icons.check, color: Colors.white),
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
