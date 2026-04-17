import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_app/core/services/api_service.dart';
import 'add_investment_screen.dart';

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

  Map<String, dynamic>? analytics;
  String selectedMode = "monthly";
  String selectedKey = "";

  static const baseUrl = "http://localhost:8000";

  @override
  void initState() {
    super.initState();
    loadPortfolio();
    loadAnalytics();
  }

  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token") ?? "";
  }

  double parse(dynamic v) => (v ?? 0).toDouble();

  Future<void> loadPortfolio() async {
    final token = await getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/investment/portfolio"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        portfolio = data;
        investments = data["investments"];
        isLoading = false;
      });
    }
  }

  Future<void> loadAnalytics() async {
  final data = await ApiService.getInvestmentAnalytics();

  if (data != null) {
    final monthly = data["monthly_profit"] ?? {};
    final yearly = data["yearly_profit"] ?? {};

    if (!mounted) return; 

    setState(() {
      analytics = data;

      if (monthly.isNotEmpty) {
        selectedKey = monthly.keys.first;
        selectedMode = "monthly";
      } else if (yearly.isNotEmpty) {
        selectedKey = yearly.keys.first;
        selectedMode = "yearly";
      } else {
        selectedKey = "";
      }
    });
  }
}

double getSelectedProfit() {
  if (analytics == null || selectedKey.isEmpty) return 0;

  final map = selectedMode == "monthly"
      ? (analytics!["monthly_profit"] ?? {})
      : (analytics!["yearly_profit"] ?? {});

  return (map[selectedKey] ?? 0).toDouble();
}

  // 🔥 ACTION LABEL
  String getAction(String type) {
    switch (type) {
      case "FD":
        return "Withdraw";
      case "SIP":
        return "Stop";
      case "REAL_ESTATE":
        return "Sell Property";
      case "GOLD":
        return "Sell Gold";
      default:
        return "Sell";
    }
  }

  // 🔥 SELL / ACTION
  void handleAction(int id) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter Sell Value"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final token = await getToken();

              await http.post(
                Uri.parse("$baseUrl/investment/sell/$id"),
                headers: {
                  "Authorization": "Bearer $token",
                  "Content-Type": "application/json"
                },
                body: jsonEncode({
                  "sell_price": double.parse(controller.text)
                }),
              );

              Navigator.pop(context);
              loadPortfolio();
            },
            child: const Text("Confirm"),
          )
        ],
      ),
    );
  }

  List get active =>
      investments.where((e) => e["is_active"] == true).toList();

  List get sold =>
      investments.where((e) => e["is_active"] == false).toList();

  @override
  Widget build(BuildContext context) {

    final total = parse(portfolio?["portfolio_value"]);
    final unrealized = parse(portfolio?["total_unrealized"]);
    final realized = parse(portfolio?["total_realized"]);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1E3C),
      appBar: AppBar(title: const Text("Investments")),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddInvestmentScreen(),
            ),
          );

          if (result == true) {
            loadPortfolio();
          }
        },
        child: const Icon(Icons.add),
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

                        const Text("Total Value",
                            style: TextStyle(color: Colors.white70)),

                        Text("₹${total.toStringAsFixed(0)}",
                            style: const TextStyle(
                                fontSize: 26, color: Colors.white)),

                        const SizedBox(height: 10),

                        Text("Unrealized: ₹${unrealized.toStringAsFixed(0)}",
                            style: const TextStyle(color: Colors.green)),

                        Text("Realized: ₹${realized.toStringAsFixed(0)}",
                            style: const TextStyle(color: Colors.orange)),
                      ],
                    ),
                  ),

                  Container(
  margin: const EdgeInsets.symmetric(horizontal: 16),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: const Color(0xFF1E2E4A),
    borderRadius: BorderRadius.circular(16),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const Text(
        "Investment Analytics",
        style: TextStyle(color: Colors.white70),
      ),

      const SizedBox(height: 10),

      /// TOGGLE
      Row(
        children: [
          ChoiceChip(
            label: const Text("Monthly"),
            selected: selectedMode == "monthly",
            onSelected: (_) {
              setState(() {
                selectedMode = "monthly";
                selectedKey = analytics?["monthly_profit"]?.keys.first ?? "";
              });
            },
          ),
          const SizedBox(width: 10),
          ChoiceChip(
            label: const Text("Yearly"),
            selected: selectedMode == "yearly",
            onSelected: (_) {
              setState(() {
                selectedMode = "yearly";
                selectedKey = analytics?["yearly_profit"]?.keys.first ?? "";
              });
            },
          ),
        ],
      ),

      const SizedBox(height: 10),

      /// DROPDOWN
      Builder(
  builder: (context) {
    Map<String, dynamic> dataMap =
        selectedMode == "monthly"
            ? (analytics?["monthly_profit"] ?? {})
            : (analytics?["yearly_profit"] ?? {});

    return DropdownButton<String>(
      value: selectedKey.isEmpty ? null : selectedKey,
      dropdownColor: const Color(0xFF1E2E4A),
      hint: const Text("Select period",
          style: TextStyle(color: Colors.white)),
      items: dataMap.keys.map<DropdownMenuItem<String>>((key) {
        return DropdownMenuItem(
          value: key,
          child: Text(key,
              style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => selectedKey = value ?? "");
      },
    );
  },
),

      const SizedBox(height: 10),

      /// PROFIT DISPLAY
      Text(
        "Profit: ₹${getSelectedProfit()}",
        style: const TextStyle(
          color: Colors.green,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      )
    ],
  ),
),

                  const TabBar(
                    tabs: [
                      Tab(text: "Active"),
                      Tab(text: "Sold"),
                    ],
                  ),

                  Expanded(
                    child: TabBarView(
                      children: [
                        _activeList(),
                        _soldList(),
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }

  // 🔵 ACTIVE
  Widget _activeList() {
    if (active.isEmpty) {
      return const Center(child: Text("No active investments"));
    }

    return ListView.builder(
      itemCount: active.length,
      itemBuilder: (_, i) {

        final inv = active[i];

        final p = parse(inv["principal_amount"]);
        final c = parse(inv["current_value"]);
        final u = parse(inv["unrealized_profit"]);

        return Card(
          color: const Color(0xFF1E2E4A),
          child: ListTile(
            title: Text(inv["investment_name"] ?? inv["investment_type"],
                style: const TextStyle(color: Colors.white)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("₹${p.toStringAsFixed(0)} → ₹${c.toStringAsFixed(0)}",
                    style: const TextStyle(color: Colors.white70)),
                Text("Unrealized: ₹${u.toStringAsFixed(0)}",
                    style: const TextStyle(color: Colors.green)),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => handleAction(inv["id"]),
              child: Text(getAction(inv["investment_type"])),
            ),
          ),
        );
      },
    );
  }

  // 🔴 SOLD (TIMELINE)
  Widget _soldList() {
    if (sold.isEmpty) {
      return const Center(child: Text("No sold investments"));
    }

    return ListView.builder(
      itemCount: sold.length,
      itemBuilder: (_, i) {

        final inv = sold[i];
        final r = parse(inv["realized_profit"]);

        return ListTile(
          leading: const Icon(Icons.timeline, color: Colors.red),
          title: Text(inv["investment_name"] ?? inv["investment_type"]),
          subtitle: Text(
              "Profit ₹${r.toStringAsFixed(0)} • ${inv["sell_date"] ?? ""}"),
        );
      },
    );
  }
}