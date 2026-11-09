import 'package:flutter_test/flutter_test.dart';
import 'package:khata_plus/models/customer.dart';
import 'package:khata_plus/models/khata_entry.dart';
import 'package:khata_plus/models/ledger.dart';
import 'package:khata_plus/utils/format.dart';

KhataEntry entry(
  String id,
  String customerId,
  EntryType type,
  double amount, {
  DateTime? date,
}) {
  return KhataEntry(
    id: id,
    customerId: customerId,
    type: type,
    amount: amount,
    date: date ?? DateTime(2026, 11, 9),
  );
}

void main() {
  group('ledgerBalance', () {
    test('credit adds, payment subtracts', () {
      final entries = [
        entry('1', 'c1', EntryType.credit, 1000),
        entry('2', 'c1', EntryType.credit, 250),
        entry('3', 'c1', EntryType.payment, 400),
      ];
      expect(ledgerBalance('c1', entries), 850);
    });

    test('other customers are ignored', () {
      final entries = [
        entry('1', 'c1', EntryType.credit, 1000),
        entry('2', 'c2', EntryType.credit, 5000),
      ];
      expect(ledgerBalance('c1', entries), 1000);
      expect(ledgerBalance('nobody', entries), 0);
    });

    test('overpayment makes the balance negative (advance)', () {
      final entries = [
        entry('1', 'c1', EntryType.credit, 300),
        entry('2', 'c1', EntryType.payment, 500),
      ];
      expect(ledgerBalance('c1', entries), -200);
    });
  });

  group('totalReceivable', () {
    test('sums only positive balances', () {
      final entries = [
        entry('1', 'c1', EntryType.credit, 1000),
        entry('2', 'c2', EntryType.credit, 500),
        entry('3', 'c2', EntryType.payment, 700), // c2 is in advance
      ];
      expect(totalReceivable(['c1', 'c2'], entries), 1000);
    });
  });

  group('totalForDay', () {
    test('counts only the given type on the given day', () {
      final entries = [
        entry('1', 'c1', EntryType.credit, 100, date: DateTime(2026, 11, 9, 9)),
        entry('2', 'c1', EntryType.credit, 50, date: DateTime(2026, 11, 9, 21)),
        entry('3', 'c1', EntryType.credit, 999, date: DateTime(2026, 11, 8)),
        entry('4', 'c1', EntryType.payment, 70, date: DateTime(2026, 11, 9)),
      ];
      expect(
        totalForDay(entries, EntryType.credit, DateTime(2026, 11, 9)),
        150,
      );
      expect(
        totalForDay(entries, EntryType.payment, DateTime(2026, 11, 9)),
        70,
      );
    });
  });

  group('runningBalances', () {
    test('walks newest-first back to zero', () {
      final entries = [
        entry('1', 'c1', EntryType.credit, 1000, date: DateTime(2026, 11, 7)),
        entry('2', 'c1', EntryType.payment, 400, date: DateTime(2026, 11, 8)),
        entry('3', 'c1', EntryType.credit, 250, date: DateTime(2026, 11, 9)),
      ];
      // Newest first: after +250 -> 850, after -400 -> 600, after +1000 -> 1000.
      expect(runningBalances('c1', entries), [850, 600, 1000]);
    });
  });

  group('customerMatches', () {
    test('matches name case-insensitively and phone by substring', () {
      expect(customerMatches('Ahmed Raza', '03001234567', 'ahmed'), isTrue);
      expect(customerMatches('Ahmed Raza', '03001234567', '1234'), isTrue);
      expect(customerMatches('Ahmed Raza', '03001234567', 'bilal'), isFalse);
      expect(customerMatches('Ahmed Raza', '03001234567', ''), isTrue);
    });
  });

  group('format helpers', () {
    test('rupees groups thousands and keeps paisa', () {
      expect(rupees(1250), 'Rs 1,250');
      expect(rupees(1250.5), 'Rs 1,250.50');
      expect(rupees(-400), '-Rs 400');
      expect(rupees(0), 'Rs 0');
    });

    test('parseAmount accepts commas, rejects junk and zero', () {
      expect(parseAmount('1,250'), 1250);
      expect(parseAmount(' 250.50 '), 250.5);
      expect(parseAmount('abc'), isNull);
      expect(parseAmount('0'), isNull);
      expect(parseAmount(''), isNull);
    });

    test('shortDate renders day month year', () {
      expect(shortDate(DateTime(2026, 11, 9)), '9 Nov 2026');
    });
  });

  group('json round-trip', () {
    test('customer and entry survive toJson/fromJson', () {
      final customer = Customer(
        id: 'c1',
        name: 'Ahmed Raza',
        phone: '0300',
        createdAt: DateTime(2026, 11, 9),
      );
      final back = Customer.fromJson(customer.toJson());
      expect(back.name, 'Ahmed Raza');
      expect(back.phone, '0300');

      final e = entry('1', 'c1', EntryType.payment, 200);
      final entryBack = KhataEntry.fromJson(e.toJson());
      expect(entryBack.type, EntryType.payment);
      expect(entryBack.amount, 200);
    });
  });
}
