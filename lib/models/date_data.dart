import 'dart:convert';

class TargetDate implements Comparable<TargetDate> {
  DateTime date;
  String? title;
  double? goalAmount;
  double? currentAmount;
  String? currency; // 'KRW' or 'USD'
  String? financialTitle;

  TargetDate({
    required this.date,
    this.title,
    this.goalAmount,
    this.currentAmount,
    this.currency,
    this.financialTitle,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'title': title,
      'goalAmount': goalAmount,
      'currentAmount': currentAmount,
      'currency': currency,
      'financialTitle': financialTitle,
    };
  }

  factory TargetDate.fromJson(Map<String, dynamic> json) {
    return TargetDate(
      date: DateTime.parse(json['date']),
      title: json['title'],
      goalAmount: json['goalAmount']?.toDouble(),
      currentAmount: json['currentAmount']?.toDouble(),
      currency: json['currency'],
      financialTitle: json['financialTitle'],
    );
  }

  @override
  int compareTo(TargetDate other) {
    return date.compareTo(other.date);
  }
}

class DateData {
  DateTime? startDate;
  List<TargetDate> endDates;

  DateData({this.startDate, required this.endDates});

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate?.toIso8601String(),
      'endDates': endDates.map((e) => e.toJson()).toList(),
    };
  }

  factory DateData.fromJson(Map<String, dynamic> json) {
    var endDatesJson = json['endDates'];
    List<TargetDate> loadedEndDates = [];

    if (endDatesJson != null) {
      if (endDatesJson is List && endDatesJson.isNotEmpty && endDatesJson.first is String) {
        // Legacy support: List<String> (ISO8601 dates)
        loadedEndDates = (endDatesJson as List<dynamic>)
            .map((e) => TargetDate(date: DateTime.parse(e)))
            .toList();
      } else {
        // New format: List<Map>
        loadedEndDates = (endDatesJson as List<dynamic>)
            .map((e) => TargetDate.fromJson(e))
            .toList();
      }
    }

    return DateData(
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDates: loadedEndDates,
    );
  }
}
