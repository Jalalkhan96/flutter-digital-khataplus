/// A customer of the shop — one page of the shopkeeper's notebook.
///
/// Every customer owns a list of ledger entries (see [KhataEntry]).
/// The customer's balance is never stored; it is always derived from
/// the entries by [ledgerBalance] so the two can never disagree.
class Customer {
  Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    required this.createdAt,
  });

  /// Stable unique id (microseconds since epoch, as a string).
  final String id;

  /// Display name, e.g. "Ahmed Raza".
  final String name;

  /// Optional contact number.
  final String phone;

  /// Optional address / note about where the customer lives.
  final String address;

  /// When this customer was added to the khata.
  final DateTime createdAt;

  Customer copyWith({String? name, String? phone, String? address}) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'phone': phone,
    'address': address,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: (json['phone'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Customer && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
