class Transaction {
  final String id;
  final String description;
  final double amount;
  final String type;
  final String category;
  final DateTime date;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
  });

  bool get isIncome => type == 'income';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      description: map['description'],
      amount: (map['amount'] as num).toDouble(),
      type: map['type'],
      category: map['category'],
      date: DateTime.parse(map['date']),
    );
  }
}
