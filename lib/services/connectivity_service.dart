import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  ScaffoldMessengerState? _messenger;

  void startMonitoring(BuildContext context) {
    _messenger = ScaffoldMessenger.maybeOf(context);
    _subscription = _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.none)) {
        _showNoInternetSnackBar();
      }
    });
  }

  void stopMonitoring() {
    _subscription?.cancel();
    _messenger = null;
  }

  void _showNoInternetSnackBar() {
    final messenger = _messenger;
    if (messenger == null) return;

    messenger.showSnackBar(
      const SnackBar(
        content: Text("No Internet Connection"),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
