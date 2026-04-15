class User {
  final int? id;
  final String name;
  final String email;
  final String? userType;
  final int? monthlyIncome;
  final String? riskProfile;

  User({
    this.id,
    required this.name,
    required this.email,
    this.userType,
    this.monthlyIncome,
    this.riskProfile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      userType: json['user_type'],
      monthlyIncome: json['monthly_income'],
      riskProfile: json['risk_profile'],
    );
  }
}
