import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class GlobalLoadingIndicator extends StatelessWidget { // Renamed class
  const GlobalLoadingIndicator({super.key, required this.loadState}); // Updated constructor

  final bool loadState;

  @override
  Widget build(BuildContext context) {
    return loadState
        ? Container(
            color: Colors.black.withOpacity(0.5), // Adjusted opacity
            child: const Center(
                child: SpinKitSquareCircle(
              color: Colors.green, // Kept color
            )),
          )
        : SizedBox.shrink();
  }
}

class LoadingProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool value) { // Added setLoading
    _isLoading = value;
    notifyListeners(); // Added notifyListeners
  }
}
