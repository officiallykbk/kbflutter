import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:function_tree/function_tree.dart';

class CalcNotifier extends StateNotifier<String> {
  CalcNotifier() : super('0');

  String mathText = '0';

  void receiver(String value) {
    switch (value) {
      case "AC":
        state = '0';
        mathText = state;
        break;
      case '+/-':
        switcher();
        break;
      case '=':
        calculate(mathText);
        break;
      default:
        if (value == '×') {
          state = '';
          mathText += '*';
        } else if (value == '÷') {
          state = '';
          mathText += '/';
        } else if (value == '+') {
          state = '';
          mathText += value;
        } else if (value == '-') {
          state = '';
          mathText += value;
        } else {
          if (state == '0') {
            state = value;
          } else {
            state += value;
          }
          mathText += value;
        }
    }
  }

  void switcher() {
    try {
      if (state[0] == '-') {
        state = state.substring(1);
      } else {
        state = '-' + state;
      }
    } catch (e) {
      print('Error encountered $e');
    }
  }

  void calculate(String fn) {
    try {
      num results = fn.interpret();
      state = results.toString();
      print(mathText);
    } catch (e) {
      state = 'Error';
    }
  }
}

// Define a provider for CalcNotifier
final calcProvider = StateNotifierProvider<CalcNotifier, String>((ref) {
  return CalcNotifier();
});
