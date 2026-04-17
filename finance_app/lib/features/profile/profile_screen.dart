import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/api_service.dart';
import '../income/income_screen.dart';
import '../../utils/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹');

  Map<String, dynamic>? userProfile;
  List<dynamic> incomeSources = [];
  int totalGoals = 0;
  double totalIncome = 0;
  double totalExpense = 0;
  double investmentValue = 0;
  bool isLoading = true;
  bool notificationsEnabled = true;
  String selectedCurrency = 'INR';
  String selectedRiskProfile = 'medium';

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  String _formatCurrency(dynamic value) {
    return _currencyFormat.format(_asDouble(value));
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  Future<void> loadProfile() async {
    setState(() => isLoading = true);

    try {
      final profile = await ApiService.getProfile();
      final incomeData = await ApiService.getMonthlyIncome();
      final expenseData = await ApiService.getExpenseSummary();
      final portfolioData = await ApiService.getPortfolio();
      final goalsData = await ApiService.getGoals();

      if (!mounted) return;

      setState(() {
        userProfile = profile;
        incomeSources = incomeData?['records'] is List ? incomeData!['records'] as List<dynamic> : [];
        totalIncome = _asDouble(incomeData?['total_income']);
        totalExpense = _asDouble(expenseData?['total_expense']);
        investmentValue = _asDouble(
          portfolioData?['portfolio_value'] ?? portfolioData?['total_value'],
        );
        totalGoals = goalsData?.length ?? 0;
        selectedRiskProfile = (profile?['risk_profile']?.toString() ?? 'medium').toLowerCase();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label will be connected next')),
    );
  }

  Future<void> _openAddIncomeSource() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const IncomeManagementScreen(),
      ),
    );

    if (!mounted) return;
    await loadProfile();
  }

  Future<void> logout() async {
    await ApiService.logout();
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(20),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF212A4D), Color(0xFF1A2140)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF343D65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _overviewTile({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF343754)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9EA8CA),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF343754)),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF6F7DF2).withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = userProfile;
    final savings = totalIncome - totalExpense;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
              ? const Center(
                  child: Text(
                    'Failed to load profile',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadProfile,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF101A38), Color(0xFF1A2E63)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: const Color(0xFF34436E)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Profile Header',
                              style: TextStyle(
                                color: Color(0xFFB8C2E6),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Manage your personal finance identity',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Keep your account details, income sources, and preferences in one place.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle('User Card'),
                      _glassCard(
                        child: Row(
                          children: [
                            Container(
                              height: 74,
                              width: 74,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6F7DF2), Color(0xFF3FA8FF)],
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile['name']?.toString() ?? 'User',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    profile['email']?.toString() ?? '',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _showComingSoon('Profile edit'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Color(0xFF4F5A8A)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              label: const Text('Edit'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle('Income Card'),
                      _glassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Total Income',
                                    style: TextStyle(
                                      color: Color(0xFFB8C2E6),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _openAddIncomeSource,
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Add Source'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatCurrency(totalIncome),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Income Sources List',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (incomeSources.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.bgInput,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Text(
                                  'No income sources added yet',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              )
                            else
                              ...incomeSources.take(5).map((item) {
                                final source = item as Map<String, dynamic>;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgInput,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: const Color(0xFF343754)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        height: 40,
                                        width: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF35D07F).withOpacity(0.14),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.account_balance_wallet_rounded,
                                          color: Color(0xFF35D07F),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              source['source']?.toString() ?? 'Income Source',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              source['date']?.toString() ?? '',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        _formatCurrency(source['amount']),
                                        style: const TextStyle(
                                          color: Color(0xFF35D07F),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle('Financial Overview'),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.92,
                        children: [
                          _overviewTile(
                            label: 'Savings',
                            value: _formatCurrency(savings < 0 ? 0 : savings),
                            subtitle: 'Income - Expense',
                            icon: Icons.savings_rounded,
                            accent: const Color(0xFF35D07F),
                          ),
                          _overviewTile(
                            label: 'Investments',
                            value: _formatCurrency(investmentValue),
                            subtitle: 'Portfolio value',
                            icon: Icons.trending_up_rounded,
                            accent: const Color(0xFF67A8FF),
                          ),
                          _overviewTile(
                            label: 'Goals',
                            value: totalGoals.toString(),
                            subtitle: 'Active plans',
                            icon: Icons.flag_rounded,
                            accent: const Color(0xFFFFB35C),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle('Risk Profile'),
                      _glassCard(
                        child: Row(
                          children: [
                            Container(
                              height: 52,
                              width: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB35C).withOpacity(0.14),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.shield_outlined,
                                color: Color(0xFFFFB35C),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Risk Profile',
                                    style: TextStyle(
                                      color: Color(0xFFB8C2E6),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _titleCase(selectedRiskProfile),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedRiskProfile,
                                dropdownColor: AppColors.bgCard,
                                style: const TextStyle(color: Colors.white),
                                items: const [
                                  DropdownMenuItem(value: 'low', child: Text('Low')),
                                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                                  DropdownMenuItem(value: 'high', child: Text('High')),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => selectedRiskProfile = value);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle('Settings'),
                      _glassCard(
                        child: Column(
                          children: [
                            _settingsTile(
                              icon: Icons.notifications_active_outlined,
                              title: 'Notifications',
                              trailing: Switch(
                                value: notificationsEnabled,
                                activeColor: AppColors.accent,
                                onChanged: (value) {
                                  setState(() => notificationsEnabled = value);
                                },
                              ),
                            ),
                            _settingsTile(
                              icon: Icons.currency_rupee_rounded,
                              title: 'Currency',
                              trailing: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedCurrency,
                                  dropdownColor: AppColors.bgCard,
                                  style: const TextStyle(color: Colors.white),
                                  items: const [
                                    DropdownMenuItem(value: 'INR', child: Text('INR')),
                                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                                    DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => selectedCurrency = value);
                                  },
                                ),
                              ),
                            ),
                            _settingsTile(
                              icon: Icons.logout_rounded,
                              title: 'Logout',
                              trailing: TextButton(
                                onPressed: logout,
                                child: const Text(
                                  'Logout',
                                  style: TextStyle(
                                    color: Color(0xFFFF8C6B),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
