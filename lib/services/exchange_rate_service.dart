import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExchangeRateService {
  static const String _apiUrl = 'https://open.er-api.com/v6/latest/USD';
  static const String _cacheKeyKrw = 'usd_krw_rate';
  static const String _cacheKeyJpy = 'usd_jpy_rate';
  static const String _cacheTimeKey = 'exchange_rate_timestamp';
  
  // Cache validity duration: 24 hours
  static const Duration _cacheDuration = Duration(hours: 24);

  /// Returns a map of rates based on USD.
  /// Keys: 'KRW', 'JPY'
  Future<Map<String, double>> getRates() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, double> rates = {};

    // Try fetching from API
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ratesData = data['rates'];
        
        final double? rateKrw = (ratesData['KRW'] as num?)?.toDouble();
        final double? rateJpy = (ratesData['JPY'] as num?)?.toDouble();
        
        if (rateKrw != null) {
          rates['KRW'] = rateKrw;
          await prefs.setDouble(_cacheKeyKrw, rateKrw);
        }
        if (rateJpy != null) {
          rates['JPY'] = rateJpy;
          await prefs.setDouble(_cacheKeyJpy, rateJpy);
        }

        await prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());
        return rates;
      }
    } catch (e) {
      print('Exchange Rate API failed: $e');
    }

    // Fallback to cache
    if (prefs.containsKey(_cacheKeyKrw)) {
      rates['KRW'] = prefs.getDouble(_cacheKeyKrw)!;
    }
    if (prefs.containsKey(_cacheKeyJpy)) {
      rates['JPY'] = prefs.getDouble(_cacheKeyJpy)!;
    }

    return rates;
  }
  
  /// Gets cached rate for specific currency
  Future<double?> getCachedRate(String currency) async {
     final prefs = await SharedPreferences.getInstance();
     if (currency == 'KRW' && prefs.containsKey(_cacheKeyKrw)) {
       return prefs.getDouble(_cacheKeyKrw);
     }
     if (currency == 'JPY' && prefs.containsKey(_cacheKeyJpy)) {
       return prefs.getDouble(_cacheKeyJpy);
     }
     return null;
  }

  Future<void> setManualRate(String currency, double rate) async {
    final prefs = await SharedPreferences.getInstance();
    if (currency == 'KRW') {
      await prefs.setDouble(_cacheKeyKrw, rate);
    } else if (currency == 'JPY') {
      await prefs.setDouble(_cacheKeyJpy, rate);
    }
    // Set timestamp to now
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
