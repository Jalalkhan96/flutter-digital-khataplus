/// The two kinds of rows a shopkeeper writes in a khata.
///
/// * [credit] — goods given on credit / money lent ("udhaar diya").
///   This increases what the customer owes the shop.
/// * [payment] — money the customer paid back ("wasool hua").
///   This decreases what the customer owes the shop.
enum EntryType { credit, payment }

extension EntryTypeJson on EntryType {
  String get jsonValue => this == EntryType.credit ? 'credit' : 'payment';

  static EntryType fromJson(String value) =>
      value == 'payment' ? EntryType.payment : EntryType.credit;
}

/// One line in a customer's ledger.
class KhataEntry {
  KhataEntry({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    this.note = '',
    required this.date,
  }) : assert(amount > 0, 'Entry amount must be positive');

  /// Stable unique id (microseconds since epoch, as a string).
  final String id;

  /// The [Customer] this entry belongs to.
  final String customerId;

  /// Credit (customer took goods/money) or payment (customer paid back).
  final EntryType type;

  /// Amount in rupees (PKR). Always positive — the sign comes from [type].
  final double amount;

  /// Optional note, e.g. "2 kg cheeni, 1 litre doodh".
  final String note;

  /// When the transaction happened.
  final DateTime date;

  /// Signed contribution of this entry to the customer's balance:
  /// credit is +amount (customer owes more), payment is -amount.
  double get signedAmount => type == EntryType.credit ? amount : -amount;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'customerId': customerId,
    'type': type.jsonValue,
    'amount': amount,
    'note': note,
    'date': date.toIso8601String(),
  };

  factory KhataEntry.fromJson(Map<String, dynamic> json) {
    return KhataEntry(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      type: EntryTypeJson.fromJson(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      note: (json['note'] as String?) ?? '',
      date: DateTime.parse(json['date'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is KhataEntry && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
