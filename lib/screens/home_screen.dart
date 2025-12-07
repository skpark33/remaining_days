import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/date_data.dart';
import '../providers/date_provider.dart';
import '../providers/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: Consumer<DateProvider>(
        builder: (context, provider, child) {
          final startDate = provider.dateData.startDate;
          final endDates = provider.dateData.endDates;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStartDateSection(context, provider, startDate),
                const SizedBox(height: 20),
                Text(
                  l10n.targetDates,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: endDates.length,
                    itemBuilder: (context, index) {
                      final endDate = endDates[index];
                      return _buildEndDateCard(context, provider, startDate, endDate, index);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _selectEndDate(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStartDateSection(BuildContext context, DateProvider provider, DateTime? startDate) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        title: Text(l10n.startDate),
        subtitle: Text(startDate != null ? DateFormat.yMMMd().format(startDate) : l10n.notSet),
        trailing: const Icon(Icons.calendar_today),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: startDate ?? DateTime.now(),
            firstDate: DateTime(1950),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            provider.setStartDate(picked);
          }
        },
      ),
    );
  }

  Widget _buildEndDateCard(BuildContext context, DateProvider provider, DateTime? startDate, TargetDate targetDate, int index) {
    final l10n = AppLocalizations.of(context)!;
    if (startDate == null) {
      return Card(
        child: ListTile(
          title: Text(DateFormat.yMMMd().format(targetDate.date)),
          subtitle: Text(l10n.pleaseSetStartDate),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => provider.removeEndDate(index),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final endDate = targetDate.date;
    // Normalize dates to ignore time components for day calculations
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final today = DateTime(now.year, now.month, now.day);

    final totalDays = end.difference(start).inDays;
    final daysPassed = today.difference(start).inDays;
    final daysRemaining = end.difference(today).inDays;

    double percentPassed = 0.0;
    double percentRemaining = 0.0;

    if (totalDays > 0) {
      percentPassed = (daysPassed / totalDays).clamp(0.0, 1.0);
      percentRemaining = 1.0 - percentPassed;
    } else if (totalDays == 0) {
        // If start and end are same day
        percentPassed = 1.0;
        percentRemaining = 0.0;
    }
    
    // Formatting percentages
    final pPassedStr = (percentPassed * 100).toStringAsFixed(2);
    final pRemainingStr = (percentRemaining * 100).toStringAsFixed(2);


    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                       Text(
                        targetDate.title != null && targetDate.title!.isNotEmpty 
                            ? targetDate.title! 
                            : DateFormat.yMMMd().format(endDate),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                        onPressed: () => _editTargetDate(context, provider, index, targetDate),
                      )
                    ],
                  ),
                ),
                Text(
                  '(${l10n.total}: $totalDays)',
                   style: const TextStyle(color: Colors.grey),
                ),
                 IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => provider.removeEndDate(index),
                ),
              ],
            ),
             if (targetDate.title != null && targetDate.title!.isNotEmpty)
                Text(DateFormat.yMMMd().format(endDate), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${l10n.daysPassed}: $daysPassed (${_formatDuration(start, today)})'),
            Row(
              children: [
                Text('${l10n.daysRemaining}: '),
                Text(
                  '$daysRemaining',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(' (${_formatDuration(today, end)})'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: percentPassed),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${l10n.passed}: $pPassedStr%'),
                Text('${l10n.remaining}: $pRemainingStr%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editTargetDate(BuildContext context, DateProvider provider, int index, TargetDate currentTarget) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentTarget.title);
    DateTime selectedDate = currentTarget.date;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.editTargetDate),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(labelText: l10n.title, hintText: l10n.enterTitle),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('${l10n.date}: '),
                      TextButton(
                        onPressed: () async {
                           final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(1950),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Text(DateFormat.yMMMd().format(selectedDate)),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () {
                    provider.updateTargetDate(
                      index, 
                      TargetDate(date: selectedDate, title: controller.text),
                    );
                    Navigator.pop(context);
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showSettings(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(l10n.selectLanguage),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Provider.of<LocaleProvider>(context, listen: false).setLocale(const Locale('en'));
                Navigator.pop(context);
              },
              child: const Text('English'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Provider.of<LocaleProvider>(context, listen: false).setLocale(const Locale('ko'));
                Navigator.pop(context);
              },
              child: const Text('한국어'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Provider.of<LocaleProvider>(context, listen: false).setLocale(const Locale('ja'));
                Navigator.pop(context);
              },
              child: const Text('日本語'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final provider = Provider.of<DateProvider>(context, listen: false);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      provider.addEndDate(picked);
    }
  }
  String _formatDuration(DateTime from, DateTime to) {
    if (from.isAfter(to)) return '0 months 0 weeks';

    int months = 0;
    DateTime tempDate = from;

    while (true) {
      DateTime nextMonth;
      if (tempDate.month == 12) {
        nextMonth = DateTime(tempDate.year + 1, 1, tempDate.day);
      } else {
        nextMonth = DateTime(tempDate.year, tempDate.month + 1, tempDate.day);
      }
      
      // Handle cases where next month doesn't have the same day (e.g., Jan 31 -> Feb 28)
      if (nextMonth.day != tempDate.day) {
         // This happens if we try to go from Jan 31 to Feb 31, DateTime auto-corrects to March 3 or 2.
         // We need to check if we overshot.
         // Actually, DateTime(2024, 2, 31) becomes March 2. 
         // A safer way to add a month is to increment month and check if day changed.
         // But a simpler loop is:
      }
      
      // Let's use a simpler approach for "full months"
      // We can't easily use DateTime addition for months accurately without edge cases.
      // Let's just increment month count and construct date until it passes 'to'.
      
      DateTime proposedNextMonth = DateTime(from.year, from.month + months + 1, from.day);
      // Adjust for invalid dates (e.g. Feb 30)
      if (proposedNextMonth.day != from.day) {
         // If the day changed, it means the original day doesn't exist in the new month.
         // e.g. Jan 31 -> Feb 31 (which becomes March 3).
         // In this case, we should probably treat "one month" as reaching the end of the next month?
         // Or just take the last valid day of that month.
         // Let's stick to a standard library behavior or simple approximation if exact "month" is ambiguous.
         // However, for "358 months", we need to be somewhat robust.
         
         // Alternative:
         // months = (to.year - from.year) * 12 + to.month - from.month;
         // if (to.day < from.day) months--;
      }
      
      if (proposedNextMonth.isAfter(to)) {
        break;
      }
      months++;
    }
    
    // Re-calculate accurate months
    int m = (to.year - from.year) * 12 + to.month - from.month;
    if (to.day < from.day) {
      m--;
    }
    if (m < 0) m = 0;

    // Now calculate remaining days
    // Add 'm' months to 'from'
    DateTime dateAfterMonths = DateTime(from.year, from.month + m, from.day);
    // Fix for invalid dates (e.g. Jan 31 + 1 month -> Feb 28/29)
    if (dateAfterMonths.month != (from.month + m - 1) % 12 + 1) {
       // If we landed in the wrong month (skipped one), it means the day didn't exist.
       // e.g. Jan 31 + 1 month should be Feb 28 (or 29).
       // But DateTime(2023, 2, 31) is March 3.
       // So we need to clamp to the last day of the target month.
       // Actually, let's just use the 'm' we calculated and be careful.
       
       // Let's use a robust "add months" logic:
       int targetYear = from.year + (from.month + m - 1) ~/ 12;
       int targetMonth = (from.month + m - 1) % 12 + 1;
       int lastDayOfTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
       int targetDay = from.day <= lastDayOfTargetMonth ? from.day : lastDayOfTargetMonth;
       
       dateAfterMonths = DateTime(targetYear, targetMonth, targetDay);
    }

    int daysRemaining = to.difference(dateAfterMonths).inDays;
    int weeks = daysRemaining ~/ 7;
    // int days = daysRemaining % 7; // User didn't ask for days, just months and weeks.

    return '$m months $weeks weeks';
  }
}
