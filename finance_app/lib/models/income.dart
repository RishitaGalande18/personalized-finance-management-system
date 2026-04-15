class Income {
  final int? id;
  final String source;
  final double amount;
  final DateTime date;
  final bool recurring;

  Income({
    this.id,
    required this.source,
    required this.amount,
    required this.date,
    this.recurring = false,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'],
      source: json['source'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      recurring: json['recurring'] ?? false,
    );
  }
}
