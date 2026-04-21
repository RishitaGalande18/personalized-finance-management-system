import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/api_service.dart';
import '../../utils/app_colors.dart';

class DebtManagementScreen extends StatefulWidget {
  const DebtManagementScreen({super.key});

  @override
  State<DebtManagementScreen> createState() => _DebtManagementScreenState();
}

class _DebtManagementScreenState extends State<DebtManagementScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs. ',
  );
  final DateFormat _dateFormat = DateFormat('dd MMM');

  List<dynamic> debts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDebts();
  }

  Future<void> loadDebts() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getDebts();
      if (!mounted) return;
      setState(() {
        debts = data ?? [];
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading debts: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  String _formatCurrency(dynamic value) {
    return _currencyFormat.format(_asDouble(value));
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String _formatDueDate(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return 'No due date';
    return _dateFormat.format(date);
  }

  String _formatPaymentDate(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy').format(date);
  }

  int _monthsLeft(dynamic dueDateValue) {
    final dueDate = _parseDate(dueDateValue);
    if (dueDate == null) return 1;

    final now = DateTime.now();
    final differenceInDays = dueDate.difference(now).inDays;
    if (differenceInDays <= 0) return 1;

    final months = (differenceInDays / 30).ceil();
    return months <= 0 ? 1 : months;
  }

  double _estimatedMonthlyEmi(Map<String, dynamic> debt) {
    final providedEmi = _asDouble(debt['emi_amount']);
    if (providedEmi > 0) return providedEmi;

    final principal = _asDouble(debt['remaining_amount']);
    final monthsLeft = _monthsLeft(debt['due_date']);
    if (principal <= 0) return 0;
    return principal / monthsLeft;
  }

  double _paidProgress(Map<String, dynamic> debt) {
    final apiProgress = _asDouble(debt['progress_paid_percentage']);
    if (apiProgress > 0) {
      return (apiProgress / 100).clamp(0.0, 1.0);
    }

    final principal = _asDouble(debt['principal_amount']);
    final remaining = _asDouble(debt['remaining_amount']);
    if (principal > 0) {
      return ((principal - remaining) / principal).clamp(0.0, 1.0);
    }

    final dueDate = _parseDate(debt['due_date']);
    if (dueDate == null) return 0;

    final now = DateTime.now();
    final totalDurationDays = 365.0;
    final remainingDays = dueDate.difference(now).inDays.toDouble();
    final normalizedRemaining = (remainingDays / totalDurationDays).clamp(0.0, 1.0);
    return (1 - normalizedRemaining).clamp(0.0, 1.0);
  }

  String _debtLabel(String value) {
    switch (value) {
      case 'CAR_LOAN':
        return 'Car Loan';
      case 'CREDIT_CARD':
        return 'Credit Card';
      case 'MORTGAGE':
        return 'Mortgage';
      case 'EDUCATION_LOAN':
        return 'Education Loan';
      case 'LOAN':
        return 'Loan';
      default:
        return value.replaceAll('_', ' ');
    }
  }

  IconData _debtIcon(String value) {
    switch (value) {
      case 'CAR_LOAN':
        return Icons.directions_car_rounded;
      case 'CREDIT_CARD':
        return Icons.credit_card_rounded;
      case 'MORTGAGE':
        return Icons.home_rounded;
      case 'EDUCATION_LOAN':
        return Icons.school_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  List<String> _buildInsights({
    required double totalDebt,
    required double monthlyEmi,
    required double avgInterest,
  }) {
    final insights = <String>[];

    if (totalDebt > 200000) {
      insights.add('Focus extra payments on the highest-interest debt first to reduce total cost faster.');
    }
    if (avgInterest >= 12) {
      insights.add('Your average interest rate is on the higher side. Consider refinancing or restructuring if available.');
    }
    if (monthlyEmi > 0) {
      insights.add('Set aside at least ${_formatCurrency(monthlyEmi)} every month to stay on track with estimated payments.');
    }
    if (insights.isEmpty) {
      insights.add('Your debt load looks manageable. Keep paying consistently and review due dates regularly.');
    }

    return insights;
  }

  List<Map<String, dynamic>> get _activeDebts {
    return debts
        .cast<Map<String, dynamic>>()
        .where(
          (debt) =>
              debt['is_active'] != false &&
              _asDouble(debt['remaining_amount']) > 0,
        )
        .toList();
  }

  Future<void> _showPaymentAction([Map<String, dynamic>? initialDebt]) async {
    final availableDebts = _activeDebts;
    if (availableDebts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active debt available for payment')),
      );
      return;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DebtPaymentSheet(
        debts: availableDebts,
        initialDebtId: (initialDebt?['id'] as num?)?.toInt() ??
            (availableDebts.first['id'] as num).toInt(),
        formatCurrency: _formatCurrency,
        formatPaymentDate: _formatPaymentDate,
        debtLabel: _debtLabel,
        asDouble: _asDouble,
      ),
    );

    if (result == true && mounted) {
      await loadDebts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded successfully')),
      );
    }
  }

  Widget _summaryMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF343754)),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF9EA8CA),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalDebt = debts.fold<double>(
      0,
      (sum, debt) => sum + _asDouble((debt as Map<String, dynamic>)['remaining_amount']),
    );
    final monthlyEmiTotal = debts.fold<double>(
      0,
      (sum, debt) => sum + _estimatedMonthlyEmi(debt as Map<String, dynamic>),
    );
    final avgInterest = debts.isEmpty
        ? 0.0
        : debts.fold<double>(
              0,
              (sum, debt) => sum + _asDouble((debt as Map<String, dynamic>)['interest_rate']),
            ) /
            debts.length;
    final remainingProgress = debts.isEmpty
        ? 0.0
        : (debts.fold<double>(
              0,
              (sum, debt) {
                final item = debt as Map<String, dynamic>;
                final apiProgress = _asDouble(item['progress_remaining_percentage']);
                if (apiProgress > 0) return sum + (apiProgress / 100);
                return sum + (1 - _paidProgress(item));
              },
            ) /
            debts.length);
    final insights = _buildInsights(
      totalDebt: totalDebt,
      monthlyEmi: monthlyEmiTotal,
      avgInterest: avgInterest,
    );

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text("Debt Management"),
        backgroundColor: AppColors.primaryDark,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadDebts,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF111B38), Color(0xFF1D315F)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFF34436E)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Debt Summary Card',
                          style: TextStyle(
                            color: Color(0xFFB8C2E6),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Total Debt: ${_formatCurrency(totalDebt)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Monthly EMI: ${_formatCurrency(monthlyEmiTotal)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _summaryMetric(
                                label: 'Average Interest',
                                value: '${avgInterest.toStringAsFixed(1)}%',
                                icon: Icons.percent_rounded,
                                color: const Color(0xFFFFB35C),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _summaryMetric(
                                label: 'Active Debts',
                                value: debts.length.toString(),
                                icon: Icons.account_balance_wallet_rounded,
                                color: const Color(0xFF67A8FF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Debt-free Progress',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: remainingProgress.clamp(0.0, 1.0),
                            minHeight: 12,
                            backgroundColor: Colors.white.withOpacity(0.12),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFFF8C6B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(remainingProgress * 100).toStringAsFixed(0)}% remaining',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showPaymentAction,
                          icon: const Icon(Icons.payments_rounded),
                          label: const Text('Pay / Add Payment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C4DA4),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Debt List',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (debts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFF343754)),
                      ),
                      child: const Text(
                        'No debts recorded',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  else
                    ...debts.map((item) {
                      final debt = item as Map<String, dynamic>;
                      final debtType = debt['debt_type']?.toString() ?? 'Debt';
                      final paidProgress = _paidProgress(debt);
                      final emi = _estimatedMonthlyEmi(debt);
                      final payments = ((debt['payments'] as List?) ?? [])
                          .whereType<Map>()
                          .map((payment) => Map<String, dynamic>.from(payment))
                          .toList();
                      final isActive = debt['is_active'] != false &&
                          _asDouble(debt['remaining_amount']) > 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF343754)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _debtIcon(debtType),
                                  color: const Color(0xFF67A8FF),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _debtLabel(debtType),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              runSpacing: 10,
                              spacing: 10,
                              children: [
                                _debtInfoChip(
                                  'Remaining',
                                  _formatCurrency(debt['remaining_amount']),
                                ),
                                _debtInfoChip(
                                  'EMI',
                                  _formatCurrency(emi),
                                ),
                                _debtInfoChip(
                                  'Interest',
                                  '${_asDouble(debt['interest_rate']).toStringAsFixed(1)}%',
                                ),
                                _debtInfoChip(
                                  'Due',
                                  _formatDueDate(debt['due_date']),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: paidProgress.clamp(0.0, 1.0),
                                minHeight: 10,
                                backgroundColor: Colors.white.withOpacity(0.12),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF67A8FF),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(paidProgress * 100).toStringAsFixed(0)}% paid',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: isActive
                                    ? () => _showPaymentAction(debt)
                                    : null,
                                icon: const Icon(Icons.payments_rounded),
                                label: Text(
                                  isActive ? 'Record Payment' : 'Fully Paid',
                                ),
                              ),
                            ),
                            if (payments.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _paymentHistory(payments.take(3).toList()),
                            ],
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 22),
                  const Text(
                    'Insights / Suggestions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...insights.map(
                    (insight) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgInput,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF343754)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.lightbulb_outline_rounded,
                              color: Color(0xFFFFB35C),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              insight,
                              style: const TextStyle(
                                color: Colors.white,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(
          context,
          '/add-debt',
        ).then((_) => loadDebts()),
        icon: const Icon(Icons.add),
        label: const Text('Add Debt'),
      ),
    );
  }

  Widget _paymentHistory(List<Map<String, dynamic>> payments) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Payments',
            style: TextStyle(
              color: Color(0xFF9EA8CA),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...payments.map(
            (payment) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF67D28D),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatPaymentDate(payment['payment_date']),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  Text(
                    _formatCurrency(payment['amount']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _debtInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(16),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'inherit'),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Color(0xFF9EA8CA),
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtPaymentSheet extends StatefulWidget {
  const _DebtPaymentSheet({
    required this.debts,
    required this.initialDebtId,
    required this.formatCurrency,
    required this.formatPaymentDate,
    required this.debtLabel,
    required this.asDouble,
  });

  final List<Map<String, dynamic>> debts;
  final int initialDebtId;
  final String Function(dynamic value) formatCurrency;
  final String Function(dynamic value) formatPaymentDate;
  final String Function(String value) debtLabel;
  final double Function(dynamic value) asDouble;

  @override
  State<_DebtPaymentSheet> createState() => _DebtPaymentSheetState();
}

class _DebtPaymentSheetState extends State<_DebtPaymentSheet> {
  final TextEditingController _amountController = TextEditingController();
  late int _selectedDebtId;
  DateTime _selectedPaymentDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDebtId = widget.initialDebtId;
  }

  Map<String, dynamic> get _selectedDebt {
    return widget.debts.firstWhere(
      (debt) => (debt['id'] as num).toInt() == _selectedDebtId,
      orElse: () => widget.debts.first,
    );
  }

  Future<void> _selectPaymentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedPaymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedPaymentDate = picked);
  }

  Future<void> _submitPayment() async {
    final amount = double.tryParse(_amountController.text.trim());
    final remainingAmount = widget.asDouble(_selectedDebt['remaining_amount']);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid payment amount')),
      );
      return;
    }

    if (amount > remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment cannot exceed ${widget.formatCurrency(remainingAmount)}',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final response = await ApiService.addDebtPayment(
      debtId: _selectedDebtId,
      amount: amount,
      paymentDate: _selectedPaymentDate.toIso8601String().split('T')[0],
    );

    if (!mounted) return;

    if (response == null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to record payment')),
      );
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final remainingAmount = widget.asDouble(_selectedDebt['remaining_amount']);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Record Payment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.white70,
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedDebtId,
              dropdownColor: AppColors.bgCard,
              decoration: const InputDecoration(
                labelText: 'Debt',
                prefixIcon: Icon(Icons.account_balance_wallet_rounded),
              ),
              items: widget.debts.map((debt) {
                final id = (debt['id'] as num).toInt();
                final type = debt['debt_type']?.toString() ?? 'Debt';
                return DropdownMenuItem<int>(
                  value: id,
                  child: Text(widget.debtLabel(type)),
                );
              }).toList(),
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedDebtId = value;
                        _amountController.clear();
                      });
                    },
            ),
            const SizedBox(height: 12),
            Text(
              'Remaining: ${widget.formatCurrency(remainingAmount)}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              enabled: !_isSaving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Payment Amount',
                prefixIcon: Icon(Icons.payments_rounded),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.calendar_today_rounded,
                color: Color(0xFF67A8FF),
              ),
              title: const Text(
                'Payment Date',
                style: TextStyle(color: Colors.white70),
              ),
              subtitle: Text(
                widget.formatPaymentDate(_selectedPaymentDate.toIso8601String()),
                style: const TextStyle(color: Colors.white),
              ),
              trailing: const Icon(
                Icons.edit_calendar_rounded,
                color: Colors.white70,
              ),
              onTap: _isSaving ? null : _selectPaymentDate,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _submitPayment,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(_isSaving ? 'Saving...' : 'Save Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C4DA4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
