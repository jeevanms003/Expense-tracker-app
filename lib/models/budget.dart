class Budget {
  final int? id;
  final int categoryId;
  final String month; // Format: YYYY-MM (e.g., 2025-05)
  final double amount;
  final String? goal; // Added for user financial goals

  Budget({
    this.id,
    required this.categoryId,
    required this.month,
    required this.amount,
    this.goal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'month': month,
      'amount': amount,
      'goal': goal,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      categoryId: map['category_id'],
      month: map['month'],
      amount: map['amount'],
      goal: map['goal'],
    );
  }
}