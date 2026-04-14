import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final nameController = TextEditingController();
  final targetAmountController = TextEditingController();
  final deadlineController = TextEditingController();
  
  String selectedPriority = 'MEDIUM';
  bool isLoading = false;
  DateTime selectedDate = DateTime.now().add(const Duration(days: 365));

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
        deadlineController.text = picked.toIso8601String().split("T")[0];
      });
    }
  }

  void addGoal() async {
    if (nameController.text.isEmpty || 
        targetAmountController.text.isEmpty || 
        deadlineController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all required fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    final response = await ApiService.createGoal(
      name: nameController.text,
      targetAmount: double.parse(targetAmountController.text),
      deadline: deadlineController.text,
      priority: selectedPriority,
    );

    setState(() => isLoading = false);

    if (response != null) {
      nameController.clear();
      targetAmountController.clear();
      deadlineController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Goal created successfully")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create goal")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1E3C),
      appBar: AppBar(
        title: const Text("Create Goal"),
        backgroundColor: const Color(0xFF1E2E4A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Goal Name (e.g., Buy House, Vacation)",
                prefixIcon: Icon(Icons.edit),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: targetAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Target Amount",
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: deadlineController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Target Deadline",
                prefixIcon: const Icon(Icons.calendar_today),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: selectDate,
                ),
              ),
              onTap: selectDate,
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedPriority,
              decoration: const InputDecoration(
                labelText: "Priority",
                prefixIcon: Icon(Icons.flag),
              ),
              items: const [
                DropdownMenuItem(value: 'LOW', child: Text('Low')),
                DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                DropdownMenuItem(value: 'HIGH', child: Text('High')),
              ],
              onChanged: (value) => setState(() => selectedPriority = value ?? 'MEDIUM'),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isLoading ? null : addGoal,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Create Goal"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    targetAmountController.dispose();
    deadlineController.dispose();
    super.dispose();
  }
}
