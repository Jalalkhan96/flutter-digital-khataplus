import 'package:flutter/foundation.dart';

import '../models/customer.dart';
import '../models/khata_entry.dart';
import '../models/ledger.dart' as ledger;
import '../services/khata_store.dart';

/// App-wide state for KhataPlus: the whole book in memory, mirrored to
/// [KhataStore] after every change.
///
/// Screens read through the getters here (which use the pure functions
/// in `ledger.dart`) and mutate only through the methods, so a balance
/// shown anywhere in the app always comes from the same calculation.
class KhataController extends ChangeNotifier {
  KhataController(this._store);

  final KhataStore _store;

  List<Customer> _customers = <Customer>[];
  List<KhataEntry> _entries = <KhataEntry>[];
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<Customer> get customers => List.unmodifiable(_customers);
  List<KhataEntry> get entries => List.unmodifiable(_entries);

  /// Loads the saved book once, at app start.
  Future<void> load() async {
    _customers = await _store.loadCustomers();
    _entries = await _store.loadEntries();
    _loaded = true;
    notifyListeners();
  }

  // -- Queries ------------------------------------------------------------

  double balanceOf(String customerId) =>
      ledger.ledgerBalance(customerId, _entries);

  double get totalReceivable => ledger.totalReceivable(
      _customers.map((c) => c.id).toList(), _entries);

  double get todayCredit =>
      ledger.totalForDay(_entries, EntryType.credit, DateTime.now());

  double get todayPayments =>
      ledger.totalForDay(_entries, EntryType.payment, DateTime.now());

  List<KhataEntry> entriesOf(String customerId) =>
      ledger.entriesForCustomer(customerId, _entries);

  /// How many customers still owe the shop something.
  int get customersWithDue =>
      _customers.where((c) => balanceOf(c.id) > 0).length;

  // -- Mutations ----------------------------------------------------------

  Future<Customer> addCustomer({
    required String name,
    String phone = '',
    String address = '',
  }) async {
    final customer = Customer(
      id: _newId(),
      name: name.trim(),
      phone: phone.trim(),
      address: address.trim(),
      createdAt: DateTime.now(),
    );
    _customers.add(customer);
    await _persist();
    return customer;
  }

  Future<void> updateCustomer(Customer updated) async {
    final index = _customers.indexWhere((c) => c.id == updated.id);
    if (index == -1) return;
    _customers[index] = updated;
    await _persist();
  }

  /// Removes a customer and every entry in their ledger.
  Future<void> deleteCustomer(String customerId) async {
    _customers.removeWhere((c) => c.id == customerId);
    _entries.removeWhere((e) => e.customerId == customerId);
    await _persist();
  }

  Future<KhataEntry> addEntry({
    required String customerId,
    required EntryType type,
    required double amount,
    String note = '',
    DateTime? date,
  }) async {
    final entry = KhataEntry(
      id: _newId(),
      customerId: customerId,
      type: type,
      amount: amount,
      note: note.trim(),
      date: date ?? DateTime.now(),
    );
    _entries.add(entry);
    await _persist();
    return entry;
  }

  Future<void> deleteEntry(String entryId) async {
    _entries.removeWhere((e) => e.id == entryId);
    await _persist();
  }

  // -- Internals ----------------------------------------------------------

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> _persist() async {
    await _store.save(customers: _customers, entries: _entries);
    notifyListeners();
  }
}
