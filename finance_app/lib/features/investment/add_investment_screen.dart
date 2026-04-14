import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class AddInvestmentScreen extends StatefulWidget {
  const AddInvestmentScreen({super.key});

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  final principalController = TextEditingController();
  final rateOfReturnController = TextEditingController();
  final quantityController = TextEditingController();
  final buyPriceController = TextEditingController();
  
  String selectedType = 'STOCK';
  bool autoUpdate = true;
  bool isLoading = false;

  void addInvestment() async {
    if (principalController.text.isEmpty || rateOfReturnController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all required fields")),
      );
      return;
    }

    setState(() => isLoading = true);
    
    int? quantity;
    double? buyPrice;
    
    if (selectedType == 'STOCK') {
      if (quantityController.text.isEmpty || buyPriceController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fill all stock fields")),
        );
        setState(() => isLoading = false);
        return;
      }
      quantity = int.parse(quantityController.text);
      buyPrice = double.parse(buyPriceController.text);
    }

    final response = await ApiService.addInvestment(
      investmentType: selectedType,
      principalAmount: double.parse(principalController.text),
      rateOfReturn: double.parse(rateOfReturnController.text),
      quantity: quantity,
      buyPrice: buyPrice,
      startDate: DateTime.now().toIso8601String().split("T")[0],
      autoUpdate: autoUpdate,
    );

    setState(() => isLoading = false);

    if (response != null) {
      principalController.clear();
      rateOfReturnController.clear();
      quantityController.clear();
      buyPriceController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Investment added successfully")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add investment")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1E3C),
      appBar: AppBar(
        title: const Text("Add Investment"),
        backgroundColor: const Color(0xFF1E2E4A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: "Investment Type",
                prefixIcon: Icon(Icons.trending_up),
              ),
              items: const [
                DropdownMenuItem(value: 'STOCK', child: Text('Stock')),
                DropdownMenuItem(value: 'BOND', child: Text('Bond')),
                DropdownMenuItem(value: 'MUTUAL_FUND', child: Text('Mutual Fund')),
                DropdownMenuItem(value: 'CRYPTO', child: Text('Crypto')),
              ],
              onChanged: (value) => setState(() => selectedType = value ?? 'STOCK'),
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
              controller: rateOfReturnController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Rate of Return (%)",
                prefixIcon: Icon(Icons.percent),
              ),
            ),
            if (selectedType == 'STOCK') ...[
              const SizedBox(height: 15),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Quantity",
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: buyPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Buy Price per Unit",
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
            ],
            const SizedBox(height: 15),
            CheckboxListTile(
              title: const Text("Auto Update"),
              value: autoUpdate,
              onChanged: (value) => setState(() => autoUpdate = value ?? true),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isLoading ? null : addInvestment,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Add Investment"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    principalController.dispose();
    rateOfReturnController.dispose();
    quantityController.dispose();
    buyPriceController.dispose();
    super.dispose();
  }
}
