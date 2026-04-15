import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../utils/app_colors.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {

  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  int? selectedCategoryId;

  bool isLoading = false;

  void addExpense() async {

    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> body = {
  "amount": double.parse(amountController.text),
  "date": DateTime.now().toIso8601String().split("T")[0],
  "description": descriptionController.text
};

    // Only send category if user selected it
    if (selectedCategoryId != null) {
      body["category_id"] = selectedCategoryId;
    }

    final response = await ApiService.postWithAuth("/expense", body);

    setState(() {
      isLoading = false;
    });

    if (response != null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Expense added")),
      );

      Navigator.pop(context, true);

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add expense")),
      );

    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.bgDark,

      appBar: AppBar(
        title: const Text("Add Expense"),
        backgroundColor: AppColors.primaryDark,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount",
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "Description",
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: "Category (Optional)",
              ),
              items: const [

                DropdownMenuItem(
                  value: 1,
                  child: Text("Food"),
                ),

                DropdownMenuItem(
                  value: 2,
                  child: Text("Travel"),
                ),

                DropdownMenuItem(
                  value: 3,
                  child: Text("Shopping"),
                ),

                DropdownMenuItem(
                  value: 4,
                  child: Text("Bills"),
                ),

              ],
              onChanged: (value) {
                selectedCategoryId = value;
              },
            ),

            const SizedBox(height: 30),

            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: addExpense,
                    child: const Text("Add Expense"),
                  )
          ],
        ),
      ),
    );
  }
}