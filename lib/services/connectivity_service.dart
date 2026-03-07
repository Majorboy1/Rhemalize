import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void startMonitoring(BuildContext context) {
    _subscription = _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      // Check if none of the results indicate a valid connection
      if (results.contains(ConnectivityResult.none)) {
        _showNoInternetSnackBar(context);
      }
    });
  }

  void stopMonitoring() {
    _subscription?.cancel();
  }

  void _showNoInternetSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("No Internet Connection"),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
