import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/date_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/home_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DateProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const remaining_daysApp(),
    ),
  );
}

class remaining_daysApp extends StatelessWidget {
  const remaining_daysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Remaining Days',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('ko'), // Korean
            Locale('ja'), // Japanese
          ],
          home: const HomeScreen(),
        );
      },
    );
  }
}
