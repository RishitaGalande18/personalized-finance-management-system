import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../utils/app_colors.dart';

class AddInvestmentScreen extends StatefulWidget {
  const AddInvestmentScreen({super.key});

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {

  final nameController = TextEditingController();
  final principalController = TextEditingController();
  final rateController = TextEditingController();
  final quantityController = TextEditingController();
  final buyPriceController = TextEditingController();
  final symbolController = TextEditingController();

  String selectedType = 'STOCK';
  bool autoUpdate = true;
  bool isLoading = false;

  void addInvestment() async {

    if (nameController.text.isEmpty) {
      showError("Enter investment name");
      return;
    }

    setState(() => isLoading = true);

    final response = await ApiService.addInvestment(
      investmentType: selectedType,
      investmentName: nameController.text,
      principalAmount: principalController.text.isEmpty
          ? null
          : double.parse(principalController.text),
      rateOfReturn: rateController.text.isEmpty
          ? null
          : double.parse(rateController.text),
      quantity: quantityController.text.isEmpty
          ? null
          : double.parse(quantityController.text),
      buyPrice: buyPriceController.text.isEmpty
          ? null
          : double.parse(buyPriceController.text),
      symbol: symbolController.text.isEmpty
          ? null
          : symbolController.text,
      startDate: DateTime.now().toIso8601String().split("T")[0],
      autoUpdate: autoUpdate,
    );

    setState(() => isLoading = false);

    if (response != null) {
      Navigator.pop(context, true);
    } else {
      showError("Failed to add investment");
    }
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text("Add Investment"),
        backgroundColor: AppColors.primaryDark,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// TYPE
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(labelText: "Type"),
              items: const [
                DropdownMenuItem(value: 'STOCK', child: Text('Stock')),
                DropdownMenuItem(value: 'FD', child: Text('FD')),
                DropdownMenuItem(value: 'SIP', child: Text('SIP')),
                DropdownMenuItem(value: 'GOLD', child: Text('Gold')),
                DropdownMenuItem(value: 'REAL_ESTATE', child: Text('Real Estate')),
              ],
              onChanged: (v) => setState(() => selectedType = v!),
            ),

            const SizedBox(height: 15),

            /// NAME
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),

            const SizedBox(height: 15),

            /// PRINCIPAL (not needed for STOCK)
            if (selectedType != "STOCK")
              TextField(
                controller: principalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Principal"),
              ),

            /// RATE (FD/SIP only)
            if (selectedType == "FD" || selectedType == "SIP")
              TextField(
                controller: rateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Rate (%)"),
              ),

            /// STOCK FIELDS
            if (selectedType == "STOCK") ...[
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quantity"),
              ),
              TextField(
                controller: buyPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Buy Price"),
              ),
              TextField(
                controller: symbolController,
                decoration: const InputDecoration(labelText: "Stock Symbol (e.g. AAPL)"),
              ),
            ],

            const SizedBox(height: 20),

            CheckboxListTile(
              title: const Text("Auto Update"),
              value: autoUpdate,
              onChanged: (v) => setState(() => autoUpdate = v!),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: isLoading ? null : addInvestment,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Add Investment"),
            )
          ],
        ),
      ),
    );
  }
}