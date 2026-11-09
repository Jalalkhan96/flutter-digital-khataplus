import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/khata_store.dart';
import 'state/khata_controller.dart';

/// KhataPlus — a shopkeeper's notebook, digitised.
///
/// One book, on the device: add a customer once, then write credit
/// ("udhaar diya") and payment ("wasool hua") entries as they happen.
/// Balances, totals and the daily summary are always calculated from
/// the entries themselves, never typed in by hand.
void main() {
  runApp(const KhataPlusApp());
}

class KhataPlusApp extends StatefulWidget {
  const KhataPlusApp({super.key});

  @override
  State<KhataPlusApp> createState() => _KhataPlusAppState();
}

class _KhataPlusAppState extends State<KhataPlusApp> {
  final KhataController _controller = KhataController(KhataStore());

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0E7C86),
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'KhataPlus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      home: HomeScreen(controller: _controller),
    );
  }
}
