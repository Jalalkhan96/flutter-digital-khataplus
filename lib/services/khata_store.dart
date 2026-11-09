import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/customer.dart';
import '../models/khata_entry.dart';

/// On-device storage for the whole khata.
///
/// The full book (customers + entries) is kept as JSON in
/// SharedPreferences under two keys. That keeps KhataPlus fully offline
/// with zero accounts and zero servers — exactly how a paper notebook
/// behaves, and the data never leaves the shopkeeper's phone.
class KhataStore {
  static const _customersKey = 'khataplus_customers_v1';
  static const _entriesKey = 'khataplus_entries_v1';

  /// Loads every customer, oldest first (the order they were added).
  Future<List<Customer>> loadCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customersKey);
    if (raw == null || raw.isEmpty) return <Customer>[];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Customer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Loads every ledger entry of every customer.
  Future<List<KhataEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_entriesKey);
    if (raw == null || raw.isEmpty) return <KhataEntry>[];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => KhataEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Persists the current book. Called after every change, so closing
  /// the app at any moment never loses an entry.
  Future<void> save({
    required List<Customer> customers,
    required List<KhataEntry> entries,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _customersKey,
      jsonEncode(customers.map((c) => c.toJson()).toList()),
    );
    await prefs.setString(
      _entriesKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}
