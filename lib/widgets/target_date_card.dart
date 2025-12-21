import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/date_data.dart';
import '../providers/date_provider.dart';
import '../services/exchange_rate_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TargetDateCard extends StatefulWidget {
  final DateTime startDate;
  final TargetDate targetDate;
  final int index;

  const TargetDateCard({
    super.key,
    required this.startDate,
    required this.targetDate,
    required this.index,
  });

  @override
  State<TargetDateCard> createState() => _TargetDateCardState();
}

class _TargetDateCardState extends State<TargetDateCard> {
  bool _isExpanded = false;
  Map<String, double> _exchangeRates = {};
  final ExchangeRateService _exchangeRateService = ExchangeRateService();

  @override
  void initState() {
    super.initState();
  }

  /// returns 'USD', 'KRW', 'JPY' based on locale
  String _getTargetCurrency(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    switch (locale) {
      case 'ko':
        return 'KRW';
      case 'ja':
        return 'JPY';
      case 'en':
      default:
        return 'USD';
    }
  }

  Future<void> _fetchExchangeRates() async {
    final rates = await _exchangeRateService.getRates();
    if (mounted) {
      setState(() {
        _exchangeRates = rates;
      });
    }
  }

  Future<void> _showManualRateDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final targetCurrency = _getTargetCurrency(context);
    
    // Determine which rate to edit: USD -> targetCurrency
    // If target is USD, maybe show KRW and JPY?
    // User requirement: "English -> USD".
    // If I'm in USD, I probably don't need to convert unless I have KRW assets.
    // If I have KRW assets and I see USD, I need KRW rate.
    // Let's prompt for the currency relevant to the asset if possible, or just generic.
    
    // Simplest approach satisfying "Keep exchange rate part":
    // If I am in KO, I edit USD->KRW.
    // If I am in JA, I edit USD->JPY.
    // If I am in EN, I edit USD->KRW and USD->JPY? Or just generic list?
    
    String rateKey = 'KRW';
    if (targetCurrency == 'JPY') rateKey = 'JPY';
    if (targetCurrency == 'USD') {
      // In USD mode, we usually don't need a rate to see USD items.
      // But if we have KRW items, we need KRW rate.
      // Let's just default to KRW for now or show a selector if needed.
      // But user said "Remove currency selection".
      // Let's just allow editing KRW rate if in USD, as a fallback default.
      rateKey = 'KRW'; 
    }

    double currentRate = _exchangeRates[rateKey] ?? 0.0;
    // If 0, try cache
    if (currentRate == 0.0) {
      currentRate = await _exchangeRateService.getCachedRate(rateKey) ?? 0.0;
    }

    final TextEditingController controller = TextEditingController(text: currentRate > 0 ? currentRate.toString() : '');
    
    await showDialog(
      context: context,
      barrierDismissible: true, 
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.enterExchangeRate),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.enterExchangeRateDesc),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'USD -> $rateKey', hintText: 'e.g. 1400'),
              ),
            ],
          ),
          actions: [
             TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                 final val = double.tryParse(controller.text);
                 if (val != null && val > 0) {
                   await _exchangeRateService.setManualRate(rateKey, val);
                   await _fetchExchangeRates(); // Refresh rates
                   Navigator.pop(context);
                 }
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  void _toggleExpansion() async {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded && _exchangeRates.isEmpty) {
      await _fetchExchangeRates();
    }
  }
  
  String _formatMoney(double amount, String currencyCode) {
    String locale = 'en_US';
    String symbol = '\$ ';
    if (currencyCode == 'KRW') {
      locale = 'ko_KR';
      symbol = '₩ ';
    } else if (currencyCode == 'JPY') {
      locale = 'ja_JP';
      symbol = '¥ ';
    }

    final formatter = NumberFormat.currency(locale: locale, symbol: symbol);
    return formatter.format(amount);
  }

  /// Converts amount from [sourceCurrency] to [targetCurrency].
  /// Uses USD as base.
  double _convertCurrency(double amount, String sourceCurrency, String targetCurrency) {
    if (sourceCurrency == targetCurrency) return amount;
    
    // Get rates (Base USD = 1.0)
    double rateSource = 1.0;
    if (sourceCurrency != 'USD') {
      rateSource = _exchangeRates[sourceCurrency] ?? 0.0;
      if (rateSource == 0.0) return amount; // Cannot convert
    }
    
    double rateTarget = 1.0;
    if (targetCurrency != 'USD') {
      rateTarget = _exchangeRates[targetCurrency] ?? 0.0;
      if (rateTarget == 0.0) return amount; // Cannot convert
    }

    // Convert Source -> USD
    double amountInUsd = (sourceCurrency == 'USD') ? amount : amount / rateSource;
    
    // Convert USD -> Target
    double amountInTarget = (targetCurrency == 'USD') ? amountInUsd : amountInUsd * rateTarget;
    
    return amountInTarget;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final endDate = widget.targetDate.date;
    final start = DateTime(widget.startDate.year, widget.startDate.month, widget.startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final today = DateTime(now.year, now.month, now.day);

    final totalDays = end.difference(start).inDays;
    final daysPassed = today.difference(start).inDays;
    final daysRemaining = end.difference(today).inDays;

    double percentPassed = 0.0;
    if (totalDays > 0) {
      percentPassed = (daysPassed / totalDays).clamp(0.0, 1.0);
    } else if (totalDays == 0) {
      percentPassed = 1.0;
    }
    
    // Formatting percentages
    final pPassedStr = (percentPassed * 100).toStringAsFixed(2);
    final pRemainingStr = ((1.0 - percentPassed) * 100).toStringAsFixed(2);

    return Card(
      color: _isExpanded ? Colors.blue[50] : null,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header Row (Always Visible)
            _buildHeaderRow(context, l10n, totalDays, endDate),
            
            const SizedBox(height: 8),
            
            // Standard Progress Info (Always Visible)
            _buildProgressInfo(l10n, daysPassed, daysRemaining, start, today, end),
            
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
            
            // Expand Button
            IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: _toggleExpansion,
            ),

            // Expanded Content
            if (_isExpanded) _buildExpandedContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context, AppLocalizations l10n, int totalDays, DateTime endDate) {
    final provider = Provider.of<DateProvider>(context, listen: false);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
                Row(
                  children: [
                    Text(
                      widget.targetDate.title != null && widget.targetDate.title!.isNotEmpty 
                          ? widget.targetDate.title! 
                          : '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat.yMMMd().format(endDate),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Text(
                  '(${l10n.total}: $totalDays)',
                  style: const TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20, color: Colors.blueGrey),
              onPressed: () => _editTargetDate(context, provider),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => provider.removeEndDate(widget.index),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressInfo(AppLocalizations l10n, int daysPassed, int daysRemaining, DateTime start, DateTime today, DateTime end) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
         Padding(
           padding: const EdgeInsets.symmetric(vertical: 2.0),
           child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text(l10n.daysPassed),
               Text(
                 '$daysPassed (${_formatDuration(start, today)})',
                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
               ),
             ],
           ),
         ),
         Padding(
           padding: const EdgeInsets.symmetric(vertical: 2.0),
           child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text(l10n.daysRemaining),
               Text(
                 '$daysRemaining (${_formatDuration(today, end)})',
                 style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
               ),
             ],
           ),
         ),
      ],
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final double? goal = widget.targetDate.goalAmount;
    final double? current = widget.targetDate.currentAmount;
    
    if (goal == null || current == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextButton(
          onPressed: () => _editTargetDate(context, Provider.of<DateProvider>(context, listen: false)),
          child: Text(l10n.setFinancialGoals),
        ),
      );
    }

    final targetCurrency = _getTargetCurrency(context);
    final sourceCurrency = widget.targetDate.currency ?? 'KRW';
    
    // Auto convert
    double displayGoal = _convertCurrency(goal, sourceCurrency, targetCurrency);
    double displayCurrent = _convertCurrency(current, sourceCurrency, targetCurrency);
    
    final double achievementRate = (current / goal).clamp(0.0, 1.0);
    final double remainingAmount = displayGoal - displayCurrent;

    // Determine if we have a valid rate for display purposes (just for info)
    // We show the rate used for conversion if it's not 1:1
    String rateInfo = '';
    if (targetCurrency != 'USD' && _exchangeRates.isNotEmpty) {
       double rate = _exchangeRates[targetCurrency] ?? 0;
       if (rate > 0) rateInfo = '${l10n.rate}: ${rate.toStringAsFixed(1)}';
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Row(
               children: [
                 Text(
                   widget.targetDate.financialTitle ?? l10n.assetGoals, 
                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                 ),
                 const SizedBox(width: 8),
                 Text(
                   _formatMoney(displayGoal, targetCurrency),
                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey),
                 ),
               ],
             ),
             Row(
              children: [
                if ((rateInfo.isNotEmpty || _exchangeRates.isNotEmpty) && targetCurrency != 'USD')
                   InkWell(
                     onTap: () => _showManualRateDialog(),
                     child: Text(
                       rateInfo.isEmpty ? '${l10n.rate}*' : rateInfo, 
                       style: const TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.underline),
                     ),
                   ),
                // Currency Toggle Removed
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFinancialRow(
              l10n.assetAchieved, 
              _formatMoney(displayCurrent, targetCurrency),
              isBold: true,
              fontSize: 16,
            ),
            _buildFinancialRow(
              l10n.assetRemaining, 
              _formatMoney(remainingAmount, targetCurrency),
              isBold: true,
              color: Colors.red,
              fontSize: 16,
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: achievementRate, 
          backgroundColor: Colors.grey[200],
          color: achievementRate >= 1.0 ? Colors.green : Colors.blue,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${l10n.achieved}: ${(achievementRate * 100).toStringAsFixed(1)}%',
            ),
            Text(
               '${l10n.remaining}: ${((1.0 - achievementRate) * 100).clamp(0.0, 100.0).toStringAsFixed(1)}%',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialRow(String label, String value, {bool isBold = false, Color? color, double? fontSize}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value, 
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
              fontSize: fontSize,
            )
          ),
        ],
      ),
    );
  }

  Future<void> _editTargetDate(BuildContext context, DateProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController(text: widget.targetDate.title);
    final financialTitleController = TextEditingController(text: widget.targetDate.financialTitle ?? l10n.assetGoals);
    
    // Convert stored amount to current locale currency for editing
    final targetCurrency = _getTargetCurrency(context);
    final sourceCurrency = widget.targetDate.currency ?? 'KRW';
    
    if (_exchangeRates.isEmpty) {
        // Try fetch if missing
        await _fetchExchangeRates();
    }
    
    double? initialGoal = widget.targetDate.goalAmount;
    double? initialCurrent = widget.targetDate.currentAmount;
    
    if (initialGoal != null) initialGoal = _convertCurrency(initialGoal, sourceCurrency, targetCurrency);
    if (initialCurrent != null) initialCurrent = _convertCurrency(initialCurrent, sourceCurrency, targetCurrency);

    final goalController = TextEditingController(text: initialGoal?.toStringAsFixed(0) ?? '');
    final currentController = TextEditingController(text: initialCurrent?.toStringAsFixed(0) ?? '');
    
    DateTime selectedDate = widget.targetDate.date;
    // We don't need currency selector. We assume input is in current local currency.

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateInternal) {
            return AlertDialog(
              title: Text(l10n.editTargetDate),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(labelText: l10n.title),
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
                              setStateInternal(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: Text(DateFormat.yMMMd().format(selectedDate)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    TextField(
                      controller: financialTitleController,
                      decoration: InputDecoration(labelText: l10n.financialTitleHint),
                    ),
                    const SizedBox(height: 24),
                    // Currency Dropdown Removed
                     TextField(
                      controller: goalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: '${l10n.assetGoalAmount} ($targetCurrency)'),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: currentController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: '${l10n.currentAssetAmount} ($targetCurrency)'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () {
                    provider.updateTargetDate(
                      widget.index, 
                      TargetDate(
                        date: selectedDate, 
                        title: titleController.text,
                        goalAmount: double.tryParse(goalController.text.replaceAll(',', ''))?.floorToDouble(),
                        currentAmount: double.tryParse(currentController.text.replaceAll(',', ''))?.floorToDouble(),
                        currency: targetCurrency, // Save in current currency
                        financialTitle: financialTitleController.text,
                      ),
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
  
  // Copied helper from HomeScreen
  String _formatDuration(DateTime from, DateTime to) {
    if (from.isAfter(to)) return '0 months 0 weeks';
    int months = (to.year - from.year) * 12 + to.month - from.month;
    if (to.day < from.day) months--;
    if (months < 0) months = 0;
    
    DateTime dateAfterMonths = DateTime(from.year, from.month + months, from.day);
    int daysRemaining = to.difference(dateAfterMonths).inDays;
    int weeks = daysRemaining ~/ 7;
    return '$months months $weeks weeks';
  }
}
