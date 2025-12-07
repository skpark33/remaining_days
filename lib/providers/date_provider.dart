import 'package:flutter/material.dart';
import '../models/date_data.dart';
import '../services/storage_service.dart';

class DateProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  DateData _dateData = DateData(endDates: []);

  DateData get dateData => _dateData;

  DateProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    _dateData = await _storageService.loadDateData();
    notifyListeners();
  }

  Future<void> setStartDate(DateTime date) async {
    _dateData.startDate = date;
    await _storageService.saveDateData(_dateData);
    notifyListeners();
  }

  Future<void> addEndDate(DateTime date) async {
    _dateData.endDates.add(date);
    _dateData.endDates.sort(); // Keep them sorted
    await _storageService.saveDateData(_dateData);
    notifyListeners();
  }

  Future<void> removeEndDate(int index) async {
    _dateData.endDates.removeAt(index);
    await _storageService.saveDateData(_dateData);
    notifyListeners();
  }
}
