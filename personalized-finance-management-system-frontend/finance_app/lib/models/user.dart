class User {
  final int? id;
  final String name;
  final String email;
  final String? userType;
  final double monthlyIncome;
  final double totalExpenses;
  final double totalSavings;
  final String? riskProfile;

  User({
    this.id,
    required this.name,
    required this.email,
    this.userType,
    this.monthlyIncome = 25000,
    this.totalExpenses = 8500,
    this.totalSavings = 16500,
    this.riskProfile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      userType: json['user_type'],
      monthlyIncome: (json['monthly_income'] ?? 25000).toDouble(),
      totalExpenses: (json['total_expenses'] ?? 8500).toDouble(),
      totalSavings: (json['total_savings'] ?? 16500).toDouble(),
      riskProfile: json['risk_profile'],
    );
  }
}
