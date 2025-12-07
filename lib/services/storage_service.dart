import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/date_data.dart';

class StorageService {
  static const String _key = 'date_data';

  Future<void> saveDateData(DateData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data.toJson()));
  }

  Future<DateData> loadDateData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_key);
    if (jsonString != null) {
      return DateData.fromJson(jsonDecode(jsonString));
    }
    return DateData(endDates: []);
  }
}
