import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../utils/app_colors.dart';

class DebtManagementScreen extends StatefulWidget {
  const DebtManagementScreen({super.key});

  @override
  State<DebtManagementScreen> createState() => _DebtManagementScreenState();
}

class _DebtManagementScreenState extends State<DebtManagementScreen> {
  List<dynamic> debts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDebts();
  }

  Future<void> loadDebts() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getDebts();
      setState(() {
        debts = data ?? [];
        isLoading = false;
      });
    } catch (e) {
      print("Error loading debts: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text("Debt Management"),
        backgroundColor: AppColors.primaryDark,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : debts.isEmpty
              ? const Center(
                  child: Text("No debts recorded",
                      style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: debts.length,
                  itemBuilder: (context, index) {
                    final debt = debts[index];
                    return Card(
                      color: AppColors.bgCard,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  debt['debt_type'] ?? 'Debt',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                if (debt['is_active'] == false)
                                  const Chip(
                                    label: Text("Paid",
                                        style: TextStyle(fontSize: 10)),
                                    backgroundColor: Colors.green,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Principal:",
                                    style:
                                        TextStyle(color: Colors.white70)),
                                Text(
                                  '\$${debt['principal_amount']?.toStringAsFixed(2) ?? '0'}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Interest Rate:",
                                    style:
                                        TextStyle(color: Colors.white70)),
                                Text(
                                  '${debt['interest_rate']?.toStringAsFixed(2) ?? '0'}%',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Due Date:",
                                    style:
                                        TextStyle(color: Colors.white70)),
                                Text(
                                  debt['due_date'] ?? '-',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.pushNamed(context, '/add-debt').then((_) => loadDebts()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
