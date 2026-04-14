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

    print("Expense Summary: $expenseData");
print("Expense List: $expenseList");

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

    return Scaffold(
  backgroundColor: const Color(0xFF0B1E3C),

  floatingActionButton: FloatingActionButton(
    backgroundColor: Colors.green,
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            /// HEALTH SCORE
            const Text(
              "Financial Health Score",
              style: TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2E4A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "Score: $healthScore / 100",
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// BALANCE OVERVIEW
            const Text(
              "Balance Overview",
              style: TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 10),

            Row(
              children: [

                Expanded(
                  child: _balanceCard("Income", income, Colors.green),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: _balanceCard("Expense", expense, Colors.red),
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// PORTFOLIO
            const Text(
              "Investment Portfolio",
              style: TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2E4A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "₹ ${portfolio.toStringAsFixed(0)}",
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// EXPENSE BREAKDOWN CHART
            const Text(
              "Expense Breakdown",
              style: TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 10),

            
           Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: const Color(0xFF1E2E4A),
    borderRadius: BorderRadius.circular(16),
  ),
  child: AspectRatio(
    aspectRatio: 1.6,
    child: expenseBreakdown.isEmpty
        ? const Center(
            child: Text(
              "No expense data",
              style: TextStyle(color: Colors.white60),
            ),
          )
        : ExpenseChart(data: expenseBreakdown),
  ),
),

            const SizedBox(height: 30),

            const SizedBox(height: 30),

/// RECENT TRANSACTIONS
const Text(
  "Recent Transactions",
  style: TextStyle(color: Colors.white70),
),

const SizedBox(height: 10),

Column(
  children: [

    recentTransactions.isEmpty
    ? const Text(
        "No transactions",
        style: TextStyle(color: Colors.white60),
      )
    : Column(
        children: recentTransactions.take(5).map((txn) {

          return _transactionTile(
            txn["category"] ?? "Expense",
            (txn["amount"] ?? 0).toDouble(),
            Icons.receipt,
            Colors.orange,
          );

        }).toList(),
      ),

  ],
),

            /// ALERTS
            const Text(
              "Recent Alerts",
              style: TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 10),

            if (alerts.isEmpty)
              const Text(
                "No alerts",
                style: TextStyle(color: Colors.white60),
              )
            else
              Column(
                children: alerts.map((alert) {

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2E4A),
                      borderRadius: BorderRadius.circular(14),
                    ),

                    child: Row(
                      children: [

                        const Text(
                          "⚠",
                          style: TextStyle(fontSize: 20),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            alert.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        )
                      ],
                    ),
                  );

                }).toList(),
              )

          ],
        ),
      ),
    );
  }

  Widget _balanceCard(String title, double value, Color color) {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF1E2E4A),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,   // 👈 ADD IT HERE
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          "₹ ${value.toStringAsFixed(0)}",
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

Widget _transactionTile(
  String title,
  double amount,
  IconData icon,
  Color color,
) {

  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),

    decoration: BoxDecoration(
      color: const Color(0xFF1E2E4A),
      borderRadius: BorderRadius.circular(14),
    ),

    child: Row(
      children: [

        CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),

        Text(
          "₹${amount.toStringAsFixed(0)}",
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        )
      ],
    ),
  );
}

}