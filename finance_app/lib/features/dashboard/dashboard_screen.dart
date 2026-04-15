import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../widgets/dashboard/expense_chart.dart';
import '../expense/add_expense_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double income = 0;
  double expense = 0;
  double portfolio = 0;
  int healthScore = 0;
  Map<String, double> expenseBreakdown = {};
  List alerts = [];
  List recentTransactions = [];
  String userName = "";

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final incomeData = await ApiService.getWithAuth("/income/monthly");
    final expenseData = await ApiService.getWithAuth("/expense/summary");
    final expenseList = await ApiService.getWithAuth("/expense/");
    final healthData = await ApiService.getWithAuth("/health/score");
    final portfolioData = await ApiService.getWithAuth("/investment/portfolio");
    final alertsData = await ApiService.getAlerts();
    final profile = await ApiService.getProfile();

    if (!mounted) {
      return;
    }

    setState(() {
      userName = profile?["name"] ?? "User";
      income = (incomeData?["total_income"] ?? 0).toDouble();
      expense = (expenseData?["total_expense"] ?? 0).toDouble();
      if (expenseData?["category_breakdown"] != null) {
        expenseBreakdown = Map<String, double>.from(
          expenseData!["category_breakdown"].map(
            (key, value) => MapEntry(key, value.toDouble()),
          ),
        );
      }
      recentTransactions = expenseList?["expenses"] ?? [];
      portfolio = (portfolioData?["total_value"] ?? 0).toDouble();
      healthScore = healthData?["score"] ?? 0;
      alerts = alertsData ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardDecoration = BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        const BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.08),
          blurRadius: 24,
          offset: Offset(0, 12),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddExpenseScreen(),
            ),
          );
          if (result == true) {
            loadDashboard();
          }
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              "Hello $userName 👋",
              style: theme.textTheme.displayMedium?.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Financial Health Score",
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$healthScore / 100",
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: const Color(0xFF22C55E),
                          fontSize: 32,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          "Stable",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF4338CA),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "Balance Overview",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _balanceCard(
                    context,
                    "Income",
                    income,
                    const Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _balanceCard(
                    context,
                    "Expense",
                    expense,
                    const Color(0xFFF97316),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              "Investment Portfolio",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Value",
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "₹${portfolio.toStringAsFixed(0)}",
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: const Color(0xFF4338CA),
                      fontSize: 30,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "Expense Breakdown",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: cardDecoration,
              child: AspectRatio(
                aspectRatio: 1.6,
                child: expenseBreakdown.isEmpty
                    ? Center(
                        child: Text(
                          "No expense data",
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : ExpenseChart(data: expenseBreakdown),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "Recent Transactions",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            if (recentTransactions.isEmpty)
              Text(
                "No transactions",
                style: theme.textTheme.bodyMedium,
              )
            else
              Column(
                children: recentTransactions.take(5).map((txn) {
                  return _transactionTile(
                    context,
                    txn["category"] ?? "Expense",
                    (txn["amount"] ?? 0).toDouble(),
                    Icons.receipt,
                    const Color(0xFFFFB020),
                  );
                }).toList(),
              ),
            const SizedBox(height: 30),
            Text(
              "Recent Alerts",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            if (alerts.isEmpty)
              Text(
                "No alerts",
                style: theme.textTheme.bodyMedium,
              )
            else
              Column(
                children: alerts.map((alert) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: cardDecoration.copyWith(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          "⚠",
                          style: TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            alert.toString(),
                            style: theme.textTheme.bodyLarge,
                          ),
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard(
    BuildContext context,
    String title,
    double value,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          const BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.06),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            "₹${value.toStringAsFixed(0)}",
            style: theme.textTheme.displayMedium?.copyWith(
              color: color,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionTile(
    BuildContext context,
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          const BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withAlpha((0.16 * 255).round()),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          Text(
            "₹${amount.toStringAsFixed(0)}",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFFEF4444),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
