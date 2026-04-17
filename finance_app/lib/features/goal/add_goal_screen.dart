import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../utils/app_colors.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final nameController = TextEditingController();
  final targetAmountController = TextEditingController();
  final deadlineController = TextEditingController();

  int selectedPriority = 3;
  bool isLoading = false;

  DateTime selectedDate =
      DateTime.now().add(const Duration(days: 365));

  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();

    /// ✅ Set default deadline
    deadlineController.text = _dateFormat.format(selectedDate);
  }

  Future<void> selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        deadlineController.text = _dateFormat.format(picked);
      });
    }
  }

  void addGoal() async {
    final name = nameController.text.trim();
    final amountText = targetAmountController.text.trim();

    /// ✅ Validation
    if (name.isEmpty ||
        amountText.isEmpty ||
        deadlineController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all required fields")),
      );
      return;
    }

    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid amount")),
      );
      return;
    }

    setState(() => isLoading = true);

    final response = await ApiService.createGoal(
      name: name,
      targetAmount: amount,
      deadline: deadlineController.text,
      priority: selectedPriority,
    );

    setState(() => isLoading = false);

    if (response != null) {
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.bgCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text("Create Goal"),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// Goal Name
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration:
                  _inputDecoration("Goal Name", Icons.edit),
            ),

            const SizedBox(height: 15),

            /// Amount
            TextField(
              controller: targetAmountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                  "Target Amount (₹)", Icons.currency_rupee),
            ),

            const SizedBox(height: 15),

            /// Deadline
            TextField(
              controller: deadlineController,
              readOnly: true,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                "Target Deadline",
                Icons.calendar_today,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: selectDate,
                ),
              ),
              onTap: selectDate,
            ),

            const SizedBox(height: 15),

            /// Priority
            DropdownButtonFormField<String>(
              value: selectedPriority.toString(),
              dropdownColor: AppColors.bgCard,
              decoration:
                  _inputDecoration("Priority", Icons.flag),
              items: const [
                DropdownMenuItem(value: '1', child: Text('High')),
                DropdownMenuItem(value: '3', child: Text('Medium')),
                DropdownMenuItem(value: '5', child: Text('Low')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedPriority =
                      int.tryParse(value ?? '3') ?? 3;
                });
              },
            ),

            const SizedBox(height: 30),

            /// Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : addGoal,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF7D8CFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white),
                      )
                    : const Text(
                        "Create Goal",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
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

