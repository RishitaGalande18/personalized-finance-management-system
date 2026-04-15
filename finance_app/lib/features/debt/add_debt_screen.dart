import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../utils/app_colors.dart';

class AddDebtScreen extends StatefulWidget {
  const AddDebtScreen({super.key});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final principalController = TextEditingController();
  final interestRateController = TextEditingController();
  final dueDateController = TextEditingController();
  
  String selectedDebtType = 'CREDIT_CARD';
  bool isLoading = false;
  DateTime selectedDate = DateTime.now().add(const Duration(days: 30));

  Future<void> selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dueDateController.text = picked.toIso8601String().split("T")[0];
      });
    }
  }

  void addDebt() async {
    if (principalController.text.isEmpty || 
        interestRateController.text.isEmpty || 
        dueDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all required fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    final response = await ApiService.addDebt(
      debtType: selectedDebtType,
      principalAmount: double.parse(principalController.text),
      interestRate: double.parse(interestRateController.text),
      dueDate: dueDateController.text,
    );

    setState(() => isLoading = false);

    if (response != null) {
      principalController.clear();
      interestRateController.clear();
      dueDateController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debt added successfully")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add debt")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text("Add Debt"),
        backgroundColor: AppColors.primaryDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedDebtType,
              decoration: const InputDecoration(
                labelText: "Debt Type",
                prefixIcon: Icon(Icons.account_balance),
              ),
              items: const [
                DropdownMenuItem(value: 'CREDIT_CARD', child: Text('Credit Card')),
                DropdownMenuItem(value: 'LOAN', child: Text('Loan')),
                DropdownMenuItem(value: 'MORTGAGE', child: Text('Mortgage')),
                DropdownMenuItem(value: 'CAR_LOAN', child: Text('Car Loan')),
                DropdownMenuItem(value: 'EDUCATION_LOAN', child: Text('Education Loan')),
              ],
              onChanged: (value) => setState(() => selectedDebtType = value ?? 'CREDIT_CARD'),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: principalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Principal Amount",
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: interestRateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Interest Rate (%)",
                prefixIcon: Icon(Icons.percent),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: dueDateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Due Date",
                prefixIcon: const Icon(Icons.calendar_today),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: selectDate,
                ),
              ),
              onTap: selectDate,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isLoading ? null : addDebt,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Add Debt"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    principalController.dispose();
    interestRateController.dispose();
    dueDateController.dispose();
    super.dispose();
  }
}
