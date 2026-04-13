import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // ── Header ──
              _buildHeader(),
              const SizedBox(height: 24),

              // ── Financial Health Card ──
              _buildHealthCard(),
              const SizedBox(height: 24),

              // ── Income/Expenses/Savings Row ──
              _buildIndicatorRow(),
              const SizedBox(height: 24),

              // ── Expense Breakdown Card ──
              _buildBreakdownCard(),
              const SizedBox(height: 32),

              // ── Expense Categories Section ──
              _buildExpenseCategories(),
              const SizedBox(height: 32),
            ],
          ),
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

  Widget _buildHealthCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEBFF), // Soft light violet background
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Text(
            '86',
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
                  'Your score is looking great!\nKeep saving',
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

  Widget _buildIndicatorRow() {
    return Row(
      children: [
        _indicatorCard(
          label: 'INCOME',
          amount: '₹25,000',
          bgColor: AppColors.incomeBg,
          textColor: AppColors.incomeText,
        ),
        const SizedBox(width: 12),
        _indicatorCard(
          label: 'EXPENSES',
          amount: '₹8,500',
          bgColor: AppColors.expenseBg,
          textColor: AppColors.expenseText,
        ),
        const SizedBox(width: 12),
        _indicatorCard(
          label: 'SAVINGS',
          amount: '₹16,500',
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                color: textColor.withValues(alpha: 0.7),
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

  Widget _buildBreakdownCard() {
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
          
          // Donut Chart
          Center(
            child: SizedBox(
              height: 180,
              width: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 45,
                  startDegreeOffset: -90,
                  sections: [
                    PieChartSectionData(
                      value: 50,
                      color: AppColors.chartColors[0], // Blue/Violet (Rent)
                      radius: 35,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: 15,
                      color: AppColors.chartColors[1], // Orange (Food)
                      radius: 35,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: 35,
                      color: AppColors.chartColors[2], // Green (Travel)
                      radius: 35,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Legends Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legendItem('Rent', '₹5,000', AppColors.chartColors[0]),
              _legendItem('Food', '₹2,000', AppColors.chartColors[1]),
            ],
          ),
          const SizedBox(height: 12),
          _legendItem('Travel', '₹1,500', AppColors.chartColors[2]),
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

  Widget _buildExpenseCategories() {
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
            children: [
              _categoryCard('🏠', 'RENT', '₹5,000'),
              const SizedBox(width: 16),
              _categoryCard('🍔', 'FOOD', '₹2,000'),
              const SizedBox(width: 16),
              _categoryCard('🚗', 'TRAVEL', '₹1,500'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _categoryCard(String emoji, String label, String amount) {
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
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
