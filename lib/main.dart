import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'screens/agent/day_screen.dart';
import 'screens/manager/dashboard_screen.dart';
import 'state/demo_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  Intl.defaultLocale = 'fr_FR';
  final store = DemoStore();
  await store.init();
  runApp(ChangeNotifierProvider.value(value: store, child: const DemoApp()));
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DemoStore>();
    return MaterialApp(
      title: store.companyName,
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: buildTheme(store.config.color),
      home: store.isManager ? const DashboardScreen() : const DayScreen(),
    );
  }
}

/// Thème pensé pour l'extérieur : gros boutons, texte lisible, contraste fort.
ThemeData buildTheme(Color primary) {
  final scheme = ColorScheme.fromSeed(seedColor: primary).copyWith(
    primary: primary,
    onPrimary: Colors.white,
    surface: Colors.white,
    onSurface: const Color(0xFF111111),
  );
  const buttonSize = Size.fromHeight(56);
  const buttonText = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF2F4F7),
    appBarTheme: AppBarTheme(backgroundColor: primary, foregroundColor: Colors.white),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 16),
      bodyLarge: TextStyle(fontSize: 18),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: buttonSize, textStyle: buttonText, shape: shape),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: buttonSize,
        textStyle: buttonText,
        shape: shape,
        side: BorderSide(color: primary, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFDDE1E6)),
      ),
    ),
    checkboxTheme: const CheckboxThemeData(visualDensity: VisualDensity.standard),
  );
}
