// Standalone check for the pure-Dart heart of KhataPlus (models, ledger
// maths and formatting). Runs without Flutter:
//
//   dart run tool/logic_check.dart
//
// Exits non-zero on the first failed expectation.
import '../lib/models/customer.dart';
import '../lib/models/khata_entry.dart';
import '../lib/models/ledger.dart';
import '../lib/utils/format.dart';

int _passed = 0;

void check(Object? actual, Object? expected, String label) {
  if (actual != expected) {
    throw StateError('FAIL $label: expected <$expected>, got <$actual>');
  }
  _passed++;
  print('ok $_passed - $label');
}

KhataEntry e(
  String id,
  String cust,
  EntryType type,
  double amount, {
  DateTime? date,
}) => KhataEntry(
  id: id,
  customerId: cust,
  type: type,
  amount: amount,
  date: date ?? DateTime(2026, 11, 9),
);

void main() {
  final entries = [
    e('1', 'c1', EntryType.credit, 1000, date: DateTime(2026, 11, 7)),
    e('2', 'c1', EntryType.payment, 400, date: DateTime(2026, 11, 8)),
    e('3', 'c1', EntryType.credit, 250, date: DateTime(2026, 11, 9)),
    e('4', 'c2', EntryType.credit, 500),
    e('5', 'c2', EntryType.payment, 700),
  ];

  check(ledgerBalance('c1', entries), 850.0, 'balance c1');
  check(ledgerBalance('c2', entries), -200.0, 'balance c2 (advance)');
  check(ledgerBalance('nobody', entries), 0.0, 'balance unknown');
  check(totalReceivable(['c1', 'c2'], entries), 850.0, 'total receivable');
  check(
    totalForDay(entries, EntryType.credit, DateTime(2026, 11, 9)),
    750.0,
    'today credit',
  );
  check(
    totalForDay(entries, EntryType.payment, DateTime(2026, 11, 9)),
    700.0,
    'today payments',
  );
  check(
    runningBalances('c1', entries).join(','),
    '850.0,600.0,1000.0',
    'running balances',
  );
  check(
    customerMatches('Ahmed Raza', '03001234567', 'ahmed'),
    true,
    'search name',
  );
  check(
    customerMatches('Ahmed Raza', '03001234567', '1234'),
    true,
    'search phone',
  );
  check(
    customerMatches('Ahmed Raza', '03001234567', 'bilal'),
    false,
    'search miss',
  );

  check(rupees(1250), 'Rs 1,250', 'rupees whole');
  check(rupees(1250.5), 'Rs 1,250.50', 'rupees paisa');
  check(rupees(-400), '-Rs 400', 'rupees negative');
  check(rupees(1000000), 'Rs 1,000,000', 'rupees million');
  check(parseAmount('1,250'), 1250.0, 'parse commas');
  check(parseAmount('abc'), null, 'parse junk');
  check(parseAmount('0'), null, 'parse zero');
  check(shortDate(DateTime(2026, 11, 9)), '9 Nov 2026', 'short date');

  final customer = Customer(
    id: 'c1',
    name: 'Ahmed Raza',
    phone: '0300',
    createdAt: DateTime(2026, 11, 9),
  );
  check(
    Customer.fromJson(customer.toJson()).name,
    'Ahmed Raza',
    'customer json round-trip',
  );
  check(
    KhataEntry.fromJson(entries.first.toJson()).amount,
    1000.0,
    'entry json round-trip',
  );

  print('\nAll $_passed checks passed.');
}
