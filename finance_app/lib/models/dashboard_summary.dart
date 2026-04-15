import 'category.dart';

class DashboardSummary {
  final double totalIncome;
  final double totalExpense;
  final List<Category> categories;
  final Map<String, double> categoryBreakdown;

  DashboardSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.categories,
    required this.categoryBreakdown,
  });

  double get savings => totalIncome - totalExpense;
}
