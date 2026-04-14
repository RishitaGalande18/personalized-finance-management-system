import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  List<dynamic> expenses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getExpenses();
      setState(() {
        expenses = data ?? [];
        isLoading = false;
      });
    } catch (e) {
      print("Error loading expenses: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1E3C),
      appBar: AppBar(
        title: const Text("Expense History"),
        backgroundColor: const Color(0xFF1E2E4A),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : expenses.isEmpty
              ? const Center(
                  child: Text("No expenses yet",
                      style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return Card(
                      color: const Color(0xFF1E2E4A),
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(
                          expense['description'] ?? 'Expense',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          expense['date'] ?? '',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: Text(
                          '\$${expense['amount']?.toString() ?? '0'}',
                          style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-expense')
            .then((_) => loadExpenses()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
