import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../utils/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/category.dart';
import '../../models/dashboard_summary.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Future<DashboardSummary> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboardData();
  }

  Future<DashboardSummary> _loadDashboardData() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      throw Exception('User is not authenticated');
    }

    final categories = await ApiService.fetchCategories(token);
    final totalIncome = await ApiService.fetchMonthlyIncome(token);
    final summaryValues = await ApiService.fetchExpenseSummary(token);
    final totalExpense = summaryValues['totalExpense'] ?? 0;

    final breakdown = <String, double>{};
    summaryValues.forEach((key, value) {
      if (key != 'totalExpense') {
        breakdown[key] = value;
      }
    });

    return DashboardSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      categories: categories,
      categoryBreakdown: breakdown,
    );
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0)}';
  }

  int _computeHealthScore(DashboardSummary data) {
    if (data.totalIncome <= 0) return 50;
    final ratio = data.savings / data.totalIncome;
    return (50 + (ratio * 50)).clamp(10, 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<DashboardSummary>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to load dashboard data.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            final sortedBreakdown = data.categoryBreakdown.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            final topBreakdown = sortedBreakdown.take(3).toList();
            final chartSections = topBreakdown.isNotEmpty
                ? List.generate(topBreakdown.length, (index) {
                    final entry = topBreakdown[index];
                    return PieChartSectionData(
                      value: entry.value,
                      color: AppColors.chartColors[index % AppColors.chartColors.length],
                      radius: 35,
                      showTitle: false,
                    );
                  })
                : [
                    PieChartSectionData(
                      value: 1,
                      color: AppColors.chartColors[0],
                      radius: 35,
                      showTitle: false,
                    ),
                  ];

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildHealthCard(data),
                  const SizedBox(height: 24),
                  _buildIndicatorRow(data),
                  const SizedBox(height: 24),
                  _buildBreakdownCard(data, chartSections, topBreakdown),
                  const SizedBox(height: 32),
                  _buildExpenseCategories(data),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Hi Srushti ',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text('👋', style: TextStyle(fontSize: 22)),
              ],
            ),
            Text(
              'Welcome back to your finances',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEAEAEE),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildHealthCard(DashboardSummary data) {
    final score = _computeHealthScore(data);
    final statusText = data.savings >= 0 ? 'Keep saving' : 'Review spending';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEBFF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Text(
            '$score',
            style: GoogleFonts.poppins(
              fontSize: 54,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Health',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$statusText',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5C61F2),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Based on income, expenses and savings',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorRow(DashboardSummary data) {
    return Row(
      children: [
        _indicatorCard(
          label: 'INCOME',
          amount: _formatCurrency(data.totalIncome),
          bgColor: AppColors.incomeBg,
          textColor: AppColors.incomeText,
        ),
        const SizedBox(width: 12),
        _indicatorCard(
          label: 'EXPENSES',
          amount: _formatCurrency(data.totalExpense),
          bgColor: AppColors.expenseBg,
          textColor: AppColors.expenseText,
        ),
        const SizedBox(width: 12),
        _indicatorCard(
          label: 'SAVINGS',
          amount: _formatCurrency(data.savings),
          bgColor: AppColors.savingsBg,
          textColor: AppColors.savingsText,
        ),
      ],
    );
  }

  Widget _indicatorCard({
    required String label,
    required String amount,
    required Color bgColor,
    required Color textColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.04),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textColor.withAlpha((0.7 * 255).round()),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              amount,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownCard(
    DashboardSummary data,
    List<PieChartSectionData> sections,
    List<MapEntry<String, double>> topBreakdown,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expense Breakdown',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Icon(Icons.access_time_rounded, color: Colors.black26, size: 20),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              height: 180,
              width: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 45,
                  startDegreeOffset: -90,
                  sections: sections,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          if (topBreakdown.isEmpty) ...[
            Text(
              'No expense categories available yet.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _legendItem(
                  topBreakdown[0].key,
                  _formatCurrency(topBreakdown[0].value),
                  AppColors.chartColors[0],
                ),
                if (topBreakdown.length > 1)
                  _legendItem(
                    topBreakdown[1].key,
                    _formatCurrency(topBreakdown[1].value),
                    AppColors.chartColors[1],
                  )
                else
                  const SizedBox(),
              ],
            ),
            const SizedBox(height: 12),
            if (topBreakdown.length > 2)
              _legendItem(
                topBreakdown[2].key,
                _formatCurrency(topBreakdown[2].value),
                AppColors.chartColors[2],
              ),
          ],
        ],
      ),
    );
  }

  Widget _legendItem(String label, String amount, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 24),
        Text(
          amount,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseCategories(DashboardSummary data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expense categories',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: data.categories.map((category) {
              final spent = data.categoryBreakdown[category.name] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _categoryCard(
                  category,
                  spent,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _categoryCard(Category category, double spent) {
    final budget = category.budgetLimit?.toDouble() ?? 0;
    final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final iconData = Category.iconFor(category.name);
    final color = Category.colorFor(category.name);

    return Container(
      width: 156,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Icon(iconData, size: 28, color: color),
          const SizedBox(height: 12),
          Text(
            category.name.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(spent),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.bgInput,
              color: progress > 0.85
                  ? AppColors.error
                  : progress > 0.6
                      ? AppColors.warning
                      : color,
            ),
          ),
        ],
      ),
    );
  }
}
