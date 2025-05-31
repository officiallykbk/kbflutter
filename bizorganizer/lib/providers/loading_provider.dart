import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class GlobalLoadingIndicator extends StatelessWidget {
  const GlobalLoadingIndicator({super.key, required this.loadState});

  final bool loadState;

  @override
  Widget build(BuildContext context) {
    return loadState
        ? Container(
            color: Colors.black.withOpacity(0), // Semi-transparent overlay
            child: Center(
                child: SpinKitSquareCircle(
              color: Theme.of(context).colorScheme.primary,
            )),
          )
        : SizedBox.shrink();
  }
}

class LoadingProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void showloading() {
    _isLoading = true;
  }

  void hideloading() {
    _isLoading = false;
  }
}
