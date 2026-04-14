import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class InvestmentPortfolioScreen extends StatefulWidget {
  const InvestmentPortfolioScreen({super.key});

  @override
  State<InvestmentPortfolioScreen> createState() =>
      _InvestmentPortfolioScreenState();
}

class _InvestmentPortfolioScreenState extends State<InvestmentPortfolioScreen> {
  List<dynamic> investments = [];
  Map<String, dynamic>? portfolio;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadInvestments();
  }

  Future<void> loadInvestments() async {
    setState(() => isLoading = true);
    try {
      final investmentsData = await ApiService.getInvestments();
      final portfolioData = await ApiService.getPortfolio();
      setState(() {
        investments = investmentsData ?? [];
        portfolio = portfolioData;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading investments: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1E3C),
      appBar: AppBar(
        title: const Text("Investment Portfolio"),
        backgroundColor: const Color(0xFF1E2E4A),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (portfolio != null)
                    Card(
                      color: const Color(0xFF1E2E4A),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text("Portfolio Value",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 8),
                            Text(
                              '\$${portfolio!['portfolio_value']?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text("Total Return",
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${portfolio!['total_return']?.toStringAsFixed(2) ?? '0.00'}',
                                      style: TextStyle(
                                        color: (portfolio!['total_return'] ??
                                                    0) >=
                                                0
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text("Return %",
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${portfolio!['return_percentage']?.toStringAsFixed(2) ?? '0.00'}%',
                                      style: TextStyle(
                                        color: (portfolio!['return_percentage'] ??
                                                    0) >=
                                                0
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text("Investments",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  investments.isEmpty
                      ? const Center(
                          child: Text("No investments yet",
                              style: TextStyle(color: Colors.white70)))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: investments.length,
                          itemBuilder: (context, index) {
                            final investment = investments[index];
                            return Card(
                              color: const Color(0xFF1E2E4A),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          investment['investment_type'] ??
                                              'Investment',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        if (investment['is_active'] == false)
                                          const Chip(
                                            label: Text("Sold",
                                                style: TextStyle(
                                                    fontSize: 10)),
                                            backgroundColor: Colors.red,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text("Principal:",
                                            style: TextStyle(
                                                color: Colors.white70)),
                                        Text(
                                          '\$${investment['principal_amount']?.toStringAsFixed(2) ?? '0'}',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text("Current Value:",
                                            style: TextStyle(
                                                color: Colors.white70)),
                                        Text(
                                          '\$${investment['current_value']?.toStringAsFixed(2) ?? '0'}',
                                          style: const TextStyle(
                                              color: Colors.blue),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text("Rate of Return:",
                                            style: TextStyle(
                                                color: Colors.white70)),
                                        Text(
                                          '${investment['rate_of_return']?.toStringAsFixed(2) ?? '0'}%',
                                          style: TextStyle(
                                            color: (investment[
                                                        'rate_of_return'] ??
                                                    0) >=
                                                0
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-investment')
            .then((_) => loadInvestments()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
