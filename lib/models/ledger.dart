import 'khata_entry.dart';

/// Pure ledger maths for KhataPlus.
///
/// Everything in this file is plain Dart with no Flutter imports, so the
/// money rules of the app can be unit-tested directly and can never drift
/// away from what the screens show: the UI always calls these functions
/// instead of doing its own arithmetic.

/// What [customerId] currently owes the shop.
///
/// Positive = the customer still has to pay this much.
/// Zero     = the account is settled ("hisaab barabar").
/// Negative = the customer has paid in advance / the shop owes them.
double ledgerBalance(String customerId, List<KhataEntry> entries) {
  var total = 0.0;
  for (final entry in entries) {
    if (entry.customerId == customerId) {
      total += entry.signedAmount;
    }
  }
  return total;
}

/// Total of every customer's outstanding balance — the money the shop
/// is still to receive ("kul lena").
double totalReceivable(List<String> customerIds, List<KhataEntry> entries) {
  var total = 0.0;
  for (final id in customerIds) {
    final balance = ledgerBalance(id, entries);
    if (balance > 0) total += balance;
  }
  return total;
}

/// Sum of all entries of one [type] made on a given calendar day —
/// used by the home screen's "today" strip (aaj ka udhaar / aaj ki wasooli).
double totalForDay(List<KhataEntry> entries, EntryType type, DateTime day) {
  var total = 0.0;
  for (final entry in entries) {
    if (entry.type == type && isSameDay(entry.date, day)) {
      total += entry.amount;
    }
  }
  return total;
}

/// Calendar-day comparison that ignores the time of day.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Entries for one customer, newest first — ledger order on screen.
List<KhataEntry> entriesForCustomer(
  String customerId,
  List<KhataEntry> entries,
) {
  final mine = entries.where((e) => e.customerId == customerId).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return mine;
}

/// Running balance after each entry, in the same (newest-first) order as
/// [entriesForCustomer]: the first value is today's balance, and each
/// step back in time undoes one entry.
List<double> runningBalances(String customerId, List<KhataEntry> entries) {
  final mine = entriesForCustomer(customerId, entries);
  final result = <double>[];
  var balance = ledgerBalance(customerId, entries);
  for (final entry in mine) {
    result.add(balance);
    balance -= entry.signedAmount;
  }
  return result;
}

/// Case-insensitive name/phone search used by the home screen.
bool customerMatches(String name, String phone, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return name.toLowerCase().contains(q) || phone.contains(q);
}
