import 'dart:convert';

import 'package:finance_app/core/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'add_investment_screen.dart';

class InvestmentPortfolioScreen extends StatefulWidget {
  const InvestmentPortfolioScreen({super.key});

  @override
  State<InvestmentPortfolioScreen> createState() =>
      _InvestmentPortfolioScreenState();
}

class _InvestmentPortfolioScreenState extends State<InvestmentPortfolioScreen> {
  static const baseUrl = "http://localhost:8000";

  List<dynamic> investments = [];
  Map<String, dynamic>? portfolio;
  Map<String, dynamic>? analytics;
  bool isLoading = true;
  String selectedMode = "monthly";
  String selectedKey = "";

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

  double parse(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? "0") ?? 0;
  }

  String money(dynamic value) => "Rs. ${parse(value).toStringAsFixed(0)}";

  Future<void> loadPortfolio() async {
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse("$baseUrl/investment/portfolio"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          portfolio = data;
          investments = (data["investments"] as List?) ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading portfolio: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> loadAnalytics() async {
    final data = await ApiService.getInvestmentAnalytics();
    if (data == null || !mounted) return;

    final monthly = (data["monthly_profit"] as Map?) ?? {};
    final yearly = (data["yearly_profit"] as Map?) ?? {};

    setState(() {
      analytics = data;
      if (monthly.isNotEmpty) {
        selectedMode = "monthly";
        selectedKey = monthly.keys.first.toString();
      } else if (yearly.isNotEmpty) {
        selectedMode = "yearly";
        selectedKey = yearly.keys.first.toString();
      } else {
        selectedKey = "";
      }
    });
  }

  double getSelectedProfit() {
    if (analytics == null || selectedKey.isEmpty) return 0;

    final map = selectedMode == "monthly"
        ? (analytics!["monthly_profit"] as Map? ?? {})
        : (analytics!["yearly_profit"] as Map? ?? {});

    return parse(map[selectedKey]);
  }

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

  Future<void> handleAction(int id) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter Sell Value"),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: "Sell value"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value == null || value <= 0) return;
              Navigator.pop(context, value);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    controller.dispose();
    if (confirmed == null) return;

    final token = await getToken();
    await http.post(
      Uri.parse("$baseUrl/investment/sell/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"sell_price": confirmed}),
    );

    if (mounted) loadPortfolio();
  }

  List<dynamic> get active =>
      investments.where((item) => item["is_active"] == true).toList();

  List<dynamic> get sold =>
      investments.where((item) => item["is_active"] == false).toList();

  @override
  Widget build(BuildContext context) {
    final total = parse(portfolio?["portfolio_value"]);
    final unrealized = parse(portfolio?["total_unrealized"]);
    final realized = parse(portfolio?["total_realized"]);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1E3C),
      appBar: AppBar(
        title: const Text("Investments"),
        backgroundColor: const Color(0xFF0B1E3C),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF3D7DFF),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddInvestmentScreen()),
          );

          if (result == true) {
            loadPortfolio();
            loadAnalytics();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Add"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final headerHeight =
                      (constraints.maxHeight * 0.35).clamp(160.0, 210.0);

                  return Column(
                    children: [
                      SizedBox(
                        height: headerHeight,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Column(
                            children: [
                              _portfolioCard(total, unrealized, realized),
                              const SizedBox(height: 10),
                              _analyticsCard(),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: _tabBar(),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _investmentList(active, showAction: true),
                            _investmentList(sold, showAction: false),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }

  Widget _tabBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF12284A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Color(0xFF3D7DFF),
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: [
          Tab(text: "Active"),
          Tab(text: "Sold"),
        ],
      ),
    );
  }

  Widget _portfolioCard(double total, double unrealized, double realized) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF17396C), Color(0xFF0E274D)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Total Portfolio Value",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            money(total),
            style: const TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  "Unrealized",
                  money(unrealized),
                  const Color(0xFF59D78F),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryTile(
                  "Realized",
                  money(realized),
                  const Color(0xFFFFB35C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _analyticsCard() {
    final map = selectedMode == "monthly"
        ? (analytics?["monthly_profit"] as Map? ?? {})
        : (analytics?["yearly_profit"] as Map? ?? {});

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2E4A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Investment Analytics",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ChoiceChip(
                label: const Text("Monthly"),
                selected: selectedMode == "monthly",
                onSelected: (_) => _selectAnalyticsMode("monthly"),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text("Yearly"),
                selected: selectedMode == "yearly",
                onSelected: (_) => _selectAnalyticsMode("yearly"),
              ),
              const Spacer(),
              Text(
                money(getSelectedProfit()),
                style: const TextStyle(
                  color: Color(0xFF59D78F),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedKey.isEmpty ? null : selectedKey,
            dropdownColor: const Color(0xFF1E2E4A),
            decoration: const InputDecoration(
              labelText: "Period",
              isDense: true,
            ),
            items: map.keys.map<DropdownMenuItem<String>>((key) {
              final value = key.toString();
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) => setState(() => selectedKey = value ?? ""),
          ),
        ],
      ),
    );
  }

  void _selectAnalyticsMode(String mode) {
    final map = mode == "monthly"
        ? (analytics?["monthly_profit"] as Map? ?? {})
        : (analytics?["yearly_profit"] as Map? ?? {});

    setState(() {
      selectedMode = mode;
      selectedKey = map.isEmpty ? "" : map.keys.first.toString();
    });
  }

  Widget _investmentList(List<dynamic> items, {required bool showAction}) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          showAction ? "No active investments" : "No sold investments",
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final investment = items[index] as Map<String, dynamic>;
        return showAction
            ? _activeInvestmentCard(investment)
            : _soldInvestmentCard(investment);
      },
    );
  }

  Widget _activeInvestmentCard(Map<String, dynamic> investment) {
    final principal = parse(investment["principal_amount"]);
    final current = parse(investment["current_value"]);
    final unrealized = parse(investment["unrealized_profit"]);
    final type = investment["investment_type"]?.toString() ?? "Investment";
    final name = investment["investment_name"]?.toString() ?? type;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2E4A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2F456B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: Color(0xFF59D78F)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => handleAction(investment["id"]),
                child: Text(getAction(type)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _infoChip("Invested", money(principal)),
              _infoChip("Current", money(current)),
              _infoChip("Unrealized", money(unrealized)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _soldInvestmentCard(Map<String, dynamic> investment) {
    final realized = parse(investment["realized_profit"]);
    final type = investment["investment_type"]?.toString() ?? "Investment";
    final name = investment["investment_name"]?.toString() ?? type;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2E4A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2F456B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timeline_rounded, color: Color(0xFFFF6B6B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  investment["sell_date"]?.toString() ?? "",
                  style: const TextStyle(color: Colors.white60),
                ),
              ],
            ),
          ),
          Text(
            money(realized),
            style: const TextStyle(
              color: Color(0xFFFFB35C),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF12284A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
