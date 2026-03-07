import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sermon.dart';

class StorageService {
  static const String _sermonsKey = 'cached_sermons';

  // --- GENERAL PURPOSE METHODS ---
  // These handle theme settings (Night/Daylight) and basic user flags

  Future<bool> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  Future<bool> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(key);
  }

  // --- SERMON CACHING METHODS ---

  /// Converts the list of Sermon objects into a JSON string and saves it locally.
  Future<void> saveSermons(List<Sermon> sermons) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedData = jsonEncode(
        sermons.map((s) => s.toJson()).toList(),
      );
      await prefs.setString(_sermonsKey, encodedData);
    } catch (e) {
      print("Error caching sermons: $e");
    }
  }

  /// Retrieves the JSON string from local storage and converts it back into Sermon objects.
  Future<List<Sermon>> getSavedSermons() async {
    final prefs = await SharedPreferences.getInstance();
    final String? sermonsString = prefs.getString(_sermonsKey);

    if (sermonsString == null || sermonsString.isEmpty) return [];

    try {
      final List<dynamic> jsonData = jsonDecode(sermonsString);
      return jsonData.map<Sermon>((item) {
        return Sermon.fromJson(item as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print("Error decoding cached sermons: $e");
      // If data is corrupted, clear it to prevent repeated crashes
      await prefs.remove(_sermonsKey);
      return [];
    }
  }

  /// Helper to clear all cached data (useful for logout)
  Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
