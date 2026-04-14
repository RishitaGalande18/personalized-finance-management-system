import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../utils/app_colors.dart';

class InvestmentPortfolioScreen extends StatefulWidget {
  const InvestmentPortfolioScreen({super.key});

  @override
  State<InvestmentPortfolioScreen> createState() =>
      _InvestmentPortfolioScreenState();
}

class _InvestmentPortfolioScreenState
    extends State<InvestmentPortfolioScreen> {
  List<dynamic> investments = [];
  Map<String, dynamic>? portfolio;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadInvestments();
  }

  double parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
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

  void _showSellDialog(int investmentId) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sell Investment"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: "Enter sell price",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(controller.text);

              if (price != null) {
                await ApiService.postWithAuth(
                  "/investment/sell/$investmentId",
                  {"sell_price": price},
                );

                Navigator.pop(context);
                loadInvestments();
              }
            },
            child: const Text("Sell"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final portfolioValue =
        parseAmount(portfolio?['portfolio_value']);
    final totalReturn =
        parseAmount(portfolio?['total_return']);
    final returnPercent =
        parseAmount(portfolio?['return_percentage']);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text("Investment Portfolio"),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(
            onPressed: loadInvestments,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  /// 🔥 PORTFOLIO CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF17396C), Color(0xFF0E274D)],
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text("Portfolio Value",
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 10),
                        Text(
                          "₹${portfolioValue.toStringAsFixed(2)}",
                          style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 28,
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
                                        color: Colors.white70)),
                                const SizedBox(height: 4),
                                Text(
                                  "₹${totalReturn.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: totalReturn >= 0
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
                                        color: Colors.white70)),
                                const SizedBox(height: 4),
                                Text(
                                  "${returnPercent.toStringAsFixed(2)}%",
                                  style: TextStyle(
                                    color: returnPercent >= 0
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

                  const SizedBox(height: 24),

                  /// 🔥 TITLE
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      "Investments",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 12),

                  investments.isEmpty
                      ? const Text("No investments yet",
                          style: TextStyle(color: Colors.white70))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          itemCount: investments.length,
                          itemBuilder: (context, index) {
                            final investment = investments[index];

                            final principal =
                                parseAmount(investment['principal_amount']);
                            final current =
                                parseAmount(investment['current_value']);
                            final rate =
                                parseAmount(investment['rate_of_return']);

                            final profit = current - principal;

                            return Container(
                              margin:
                                  const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.bgCard,
                                borderRadius:
                                    BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [

                                  /// TOP ROW
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        investment['investment_type'] ??
                                            'Investment',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight:
                                                FontWeight.bold),
                                      ),

                                      if (investment['is_active'] ==
                                          false)
                                        const Chip(
                                          label: Text("Sold"),
                                          backgroundColor: Colors.red,
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  /// DATA
                                  _row("Principal", principal),
                                  _row("Current Value", current,
                                      color: Colors.blue),

                                  _row("Return %", rate,
                                      suffix: "%",
                                      color: rate >= 0
                                          ? Colors.green
                                          : Colors.red),

                                  _row("Profit", profit,
                                      color: profit >= 0
                                          ? Colors.green
                                          : Colors.red),

                                  const SizedBox(height: 10),

                                  /// SELL BUTTON
                                  if (investment['is_active'] == true)
                                    Align(
                                      alignment:
                                          Alignment.centerRight,
                                      child: ElevatedButton(
                                        style: ElevatedButton
                                            .styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () {
                                          _showSellDialog(
                                              investment['id']);
                                        },
                                        child: const Text("Sell"),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),

      /// ADD INVESTMENT
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E6BFF),
        onPressed: () => Navigator.pushNamed(context, '/add-investment')
            .then((_) => loadInvestments()),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// 🔹 COMMON ROW WIDGET
  Widget _row(String label, double value,
      {String suffix = "", Color color = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70)),
          Text(
            "₹${value.toStringAsFixed(2)}$suffix",
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }
}