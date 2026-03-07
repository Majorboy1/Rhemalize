import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider with ChangeNotifier {
  final StorageService _storage = StorageService();
  static const String _themeKey = "isDarkMode";

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  // Load the saved setting when the app starts
  Future<void> _loadTheme() async {
    final bool? savedDarkMode = await _storage.getBool(_themeKey);
    if (savedDarkMode != null) {
      _themeMode = savedDarkMode ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    }
  }

  // Toggle between Day and Night and save the choice
  Future<void> toggleTheme(bool isOn) async {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    // This satisfies your requirement: "settings to be saved when I change from night to daylight"
    await _storage.setBool(_themeKey, isOn);
  }
}
