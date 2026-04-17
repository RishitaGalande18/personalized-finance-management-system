class Expense {
  final int? id;
  final double amount;
  final DateTime date;
  final String? description;
  final int? categoryId;
  final String? categoryName;

  Expense({
    this.id,
    required this.amount,
    required this.date,
    this.description,
    this.categoryId,
    this.categoryName,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      description: json['description'],
      categoryId: json['category_id'],
      categoryName: json['category_name'],
    );
  }
}
