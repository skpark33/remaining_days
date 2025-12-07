import 'dart:convert';

class DateData {
  DateTime? startDate;
  List<DateTime> endDates;

  DateData({this.startDate, required this.endDates});

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate?.toIso8601String(),
      'endDates': endDates.map((e) => e.toIso8601String()).toList(),
    };
  }

  factory DateData.fromJson(Map<String, dynamic> json) {
    return DateData(
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDates: (json['endDates'] as List<dynamic>)
          .map((e) => DateTime.parse(e))
          .toList(),
    );
  }
}
