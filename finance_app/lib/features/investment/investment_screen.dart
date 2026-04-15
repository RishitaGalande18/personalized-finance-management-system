import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_colors.dart';

class InvestmentPortfolioScreen extends StatefulWidget {
  const InvestmentPortfolioScreen({super.key});

  @override
  State<InvestmentPortfolioScreen> createState() =>
      _InvestmentPortfolioScreenState();
}

class _InvestmentPortfolioScreenState
    extends State<InvestmentPortfolioScreen> {

  List investments = [];
  Map<String, dynamic>? portfolio;
  bool isLoading = true;

  static const baseUrl = "http://192.168.31.109:8000";

  @override
  void initState() {
    super.initState();
    loadPortfolio();
  }

  // 🔑 Get Token
  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token") ?? "";
  }

  // 🔢 Parse helper
  double parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  // 🚀 Load Portfolio
  Future<void> loadPortfolio() async {
    setState(() => isLoading = true);

    final token = await getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/investment/portfolio"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        portfolio = data;
        investments = data["investments"] ?? [];
        isLoading = false;
      });
    } else {
      print("Error: ${response.body}");
      setState(() => isLoading = false);
    }
  }

  // 💰 Sell Dialog
  void _showSellDialog(int id) {
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
              final token = await getToken();
              final price = double.tryParse(controller.text);

              if (price != null) {
                await http.post(
                  Uri.parse("$baseUrl/investment/sell/$id"),
                  headers: {
                    "Authorization": "Bearer $token",
                    "Content-Type": "application/json",
                  },
                  body: jsonEncode({"sell_price": price}),
                );

                Navigator.pop(context);
                loadPortfolio();
              }
            },
            child: const Text("Sell"),
          ),
        ],
      ),
    );
  }

  // 📊 Split data
  List get activeInvestments =>
      investments.where((i) => i["is_active"] == true).toList();

  List get soldInvestments =>
      investments.where((i) => i["is_active"] == false).toList();

  @override
  Widget build(BuildContext context) {

    final total = parseAmount(portfolio?["portfolio_value"]);
    final profit = parseAmount(portfolio?["total_return"]);
    final percent = parseAmount(portfolio?["return_percentage"]);

    return Scaffold(
      backgroundColor: AppColors.bgDark,

      appBar: AppBar(
        title: const Text("Investments"),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(
            onPressed: loadPortfolio,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [

                  /// 🔥 PORTFOLIO CARD
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF17396C), Color(0xFF0E274D)],
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text("Total Portfolio Value",
                            style: TextStyle(color: Colors.white70)),

                        const SizedBox(height: 10),

                        Text(
                          "₹${total.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "₹${profit.toStringAsFixed(2)} (${percent.toStringAsFixed(2)}%)",
                          style: TextStyle(
                            color: profit >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// 🔥 TABS
                  const TabBar(
                    tabs: [
                      Tab(text: "Active"),
                      Tab(text: "Sold"),
                    ],
                  ),

                  /// 🔥 CONTENT
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildActiveInvestments(),
                        _buildSoldInvestments(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // 🟢 ACTIVE TAB
  Widget _buildActiveInvestments() {
    if (activeInvestments.isEmpty) {
      return const Center(
        child: Text("No active investments",
            style: TextStyle(color: Colors.white70)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeInvestments.length,
      itemBuilder: (context, index) {

        final inv = activeInvestments[index];

        final principal = parseAmount(inv["principal_amount"]);
        final current = parseAmount(inv["current_value"]);
        final profit = parseAmount(inv["profit"]);

        return _investmentCard(inv, principal, current, profit, true);
      },
    );
  }

  // 🔴 SOLD TAB (TIMELINE)
  Widget _buildSoldInvestments() {

    if (soldInvestments.isEmpty) {
      return const Center(
        child: Text("No sold investments",
            style: TextStyle(color: Colors.white70)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: soldInvestments.length,
      itemBuilder: (context, index) {
        return _soldTimelineItem(soldInvestments[index]);
      },
    );
  }

  // 📍 TIMELINE ITEM
  Widget _soldTimelineItem(dynamic inv) {

    final profit = parseAmount(inv["profit"]);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Column(
          children: [
            Container(width: 2, height: 20, color: Colors.grey),
            const CircleAvatar(radius: 6, backgroundColor: Colors.red),
            Container(width: 2, height: 80, color: Colors.grey),
          ],
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2E4A),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(inv["investment_type"],
                    style: const TextStyle(color: Colors.white)),

                const SizedBox(height: 6),

                Text(
                  "Profit: ₹${profit.toStringAsFixed(0)}",
                  style: TextStyle(
                    color: profit >= 0 ? Colors.green : Colors.red,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Date: ${inv["sell_date"] ?? "N/A"}",
                  style: const TextStyle(color: Colors.white38),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  // 📦 CARD
  Widget _investmentCard(
      dynamic inv,
      double principal,
      double current,
      double profit,
      bool showSell) {

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2E4A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(inv["investment_type"],
              style: const TextStyle(color: Colors.white)),

          const SizedBox(height: 10),

          Text(
            "₹${principal.toStringAsFixed(0)} → ₹${current.toStringAsFixed(0)}",
            style: const TextStyle(color: Colors.white70),
          ),

          const SizedBox(height: 6),

          Text(
            "₹${profit.toStringAsFixed(0)}",
            style: TextStyle(
              color: profit >= 0 ? Colors.green : Colors.red,
            ),
          ),

          if (showSell)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => _showSellDialog(inv["id"]),
                child: const Text("Sell"),
              ),
            ),
        ],
      ),
    );
  }
}