import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExchangeRateService {
  static const String _apiUrl = 'https://open.er-api.com/v6/latest/USD';
  static const String _cacheKey = 'usd_krw_rate';
  static const String _cacheTimeKey = 'usd_krw_rate_timestamp';
  
  // Cache validity duration: 24 hours
  static const Duration _cacheDuration = Duration(hours: 24);

  /// Returns the current USD to KRW rate.
  /// 
  /// 1. Tries to fetch from API.
  /// 2. If API fails, checks cache.
  /// 3. If no cache, returns null.
  Future<double?> getUsdToKrwRate() async {
    final prefs = await SharedPreferences.getInstance();

    // Try fetching from API
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final double rate = (data['rates']['KRW'] as num).toDouble();
        
        // Save to cache
        await prefs.setDouble(_cacheKey, rate);
        await prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());
        
        return rate;
      }
    } catch (e) {
      // API call failed, fall through to cache
      print('Exchange Rate API failed: $e');
    }

    // Check cache
    if (prefs.containsKey(_cacheKey)) {
      return prefs.getDouble(_cacheKey);
    }

    return null;
  }
  
  /// Gets the cached rate if available, regardless of expiry.
  Future<double?> getCachedRate() async {
     final prefs = await SharedPreferences.getInstance();
     if (prefs.containsKey(_cacheKey)) {
      return prefs.getDouble(_cacheKey);
    }
    return null;
  }

  Future<void> setManualRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_cacheKey, rate);
    // Set timestamp to now, effectively treating manual entry as a fresh "fetch"
    await prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());
  }

  Future<DateTime?> getLastUpdated() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString(_cacheTimeKey);
    if (timeStr != null) {
      return DateTime.parse(timeStr);
    }
    return null;
  }
}
