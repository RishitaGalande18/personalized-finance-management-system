import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class IncomeManagementScreen extends StatefulWidget {
  const IncomeManagementScreen({super.key});

  @override
  State<IncomeManagementScreen> createState() => _IncomeManagementScreenState();
}

class _IncomeManagementScreenState extends State<IncomeManagementScreen> {
  final sourceController = TextEditingController();
  final amountController = TextEditingController();
  bool recurringChecked = false;
  Map<String, dynamic>? monthlySummary;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadMonthlySummary();
  }

  Future<void> loadMonthlySummary() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getMonthlySummary();
      setState(() {
        monthlySummary = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void addIncome() async {
    if (sourceController.text.isEmpty || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    setState(() => isLoading = true);
    final response = await ApiService.addIncome(
      source: sourceController.text,
      amount: double.parse(amountController.text),
      date: DateTime.now().toIso8601String().split("T")[0],
      recurring: recurringChecked,
    );

    setState(() => isLoading = false);

    if (response != null) {
      sourceController.clear();
      amountController.clear();
      recurringChecked = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Income added successfully")),
      );
      loadMonthlySummary();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add income")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1E3C),
      appBar: AppBar(
        title: const Text("Income Management"),
        backgroundColor: const Color(0xFF1E2E4A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (!isLoading && monthlySummary != null)
              Card(
                color: const Color(0xFF1E2E4A),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text("Monthly Income",
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(
                        '\$${monthlySummary!['income']?.toString() ?? '0'}',
                        style: const TextStyle(
                            color: Colors.green,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 30),
            const Text("Add New Income",
                style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 20),
            TextField(
              controller: sourceController,
              decoration: const InputDecoration(
                labelText: "Income Source (e.g., Salary, Freelance)",
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount",
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 15),
            CheckboxListTile(
              title: const Text("Recurring Income"),
              value: recurringChecked,
              onChanged: (value) =>
                  setState(() => recurringChecked = value ?? false),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : addIncome,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Add Income"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    sourceController.dispose();
    amountController.dispose();
    super.dispose();
  }
}
