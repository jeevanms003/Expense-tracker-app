class Transaction {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final int categoryId;
  final int paymentMethodId;

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.paymentMethodId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category_id': categoryId,
      'payment_method_id': paymentMethodId,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      categoryId: map['category_id'],
      paymentMethodId: map['payment_method_id'],
    );
  }
}