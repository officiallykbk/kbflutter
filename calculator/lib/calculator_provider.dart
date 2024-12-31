import 'package:flutter/material.dart';
import 'package:function_tree/function_tree.dart';

class Calc_provider extends ChangeNotifier {
  String displayText = '0';
  String get DisplayText => displayText;
  String mathText = '0';
  receiver(String value) {
    switch (value) {
      case "AC":
        displayText = '0';
        mathText = displayText;
      case '+/-':
        switcher();
      case '=':
        calculate(mathText);
      default:
        if (value == '×') {
          displayText = '';
          mathText += '*';
        } else if (value == '÷') {
          displayText = '';
          mathText += '/';
        } else if (value == '+') {
          displayText = '';
          mathText += value;
        } else if (value == '-') {
          displayText = '';
          mathText += value;
        } else {
          if (displayText == '0') {
            displayText = value;
          } else {
            displayText += value;
          }
          mathText += value;
        }
    }
    notifyListeners();
  }

  switcher() {
    try {
      if (displayText[0] == '-') {
        displayText = displayText.substring(1);
      } else {
        displayText = '-' + displayText;
      }
    } catch (e) {
      print('Error encountered $e');
    }
    notifyListeners();
  }

  calculate(String fn) {
    try {
      num results = fn.interpret();
      displayText = results.toString();
      print(mathText);
    } catch (e) {
      displayText = 'Error';
    }
    notifyListeners();
  }
}
