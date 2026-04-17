import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/api_service.dart';
import '../../utils/app_colors.dart';

class GoalDetailScreen extends StatefulWidget {
  const GoalDetailScreen({
    super.key,
    required this.goalId,
    this.initialGoal,
  });

  final int goalId;
  final Map<String, dynamic>? initialGoal;

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹');
  final DateFormat _displayDateFormat = DateFormat('dd MMM yyyy');
  final TextEditingController _amountController = TextEditingController();

  Map<String, dynamic>? goal;
  bool isLoading = true;
  bool isSubmitting = false;
  bool isLinkingInvestment = false;

  @override
  void initState() {
    super.initState();
    goal = widget.initialGoal;
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    setState(() => isLoading = true);

    final response = await ApiService.getGoalDetail(widget.goalId);

    if (!mounted) return;

    setState(() {
      goal = response ?? goal;
      isLoading = false;
    });
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  String _formatCurrency(dynamic value) {
    return _currencyFormat.format(_asDouble(value));
  }

  String _formatDeadline(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'No date';
    }

    try {
      return _displayDateFormat.format(DateTime.parse(value.toString()));
    } catch (_) {
      return value.toString();
    }
  }

  String _investmentTitle(Map<String, dynamic> investment) {
    final name = investment['investment_name']?.toString().trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    return investment['investment_type']?.toString() ?? 'Investment';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF35D07F);
      case 'behind':
        return const Color(0xFFFF8C6B);
      default:
        return const Color(0xFF67A8FF);
    }
  }

  Future<void> _showAddContributionDialog() async {
    _amountController.clear();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Add Contribution',
                style: TextStyle(color: Colors.white),
              ),
              content: TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final amount =
                              double.tryParse(_amountController.text.trim());

                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Enter a valid contribution amount',
                                ),
                              ),
                            );
                            return;
                          }

                          setState(() => isSubmitting = true);
                          setDialogState(() {});

                          final response = await ApiService.contributeToGoal(
                            goalId: widget.goalId,
                            amount: amount,
                          );

                          if (!mounted) return;

                          setState(() => isSubmitting = false);
                          setDialogState(() {});

                          if (response != null) {
                            Navigator.of(dialogContext).pop();
                            setState(() => goal = response);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Contribution added successfully',
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Unable to add contribution'),
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showLinkInvestmentDialog() async {
    final investments = await ApiService.getInvestments();

    if (!mounted) return;

    final linkedInvestments = goal?['linked_investments'];
    final linkedIds = ((linkedInvestments is List ? linkedInvestments : const [])
            .map((item) => _asInt((item as Map<String, dynamic>)['investment_id']))
            .whereType<int>())
        .toSet();

    final availableInvestments = (investments ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((investment) => !linkedIds.contains(_asInt(investment['id'])))
        .toList();

    if (availableInvestments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available investments to link'),
        ),
      );
      return;
    }

    int? selectedInvestmentId = _asInt(availableInvestments.first['id']);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Link Investment',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: availableInvestments.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Color(0xFF343754)),
                  itemBuilder: (context, index) {
                    final investment = availableInvestments[index];
                    final investmentId = _asInt(investment['id']);

                    return RadioListTile<int>(
                      value: investmentId ?? -1,
                      groupValue: selectedInvestmentId,
                      activeColor: AppColors.accent,
                      title: Text(
                        _investmentTitle(investment),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${investment['investment_type'] ?? 'Investment'} • ${_formatCurrency(investment['principal_amount'])}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      onChanged: isLinkingInvestment
                          ? null
                          : (value) {
                              setDialogState(() {
                                selectedInvestmentId = value;
                              });
                            },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLinkingInvestment
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLinkingInvestment || selectedInvestmentId == null
                      ? null
                      : () async {
                          setState(() => isLinkingInvestment = true);
                          setDialogState(() {});

                          final response = await ApiService.linkInvestmentToGoal(
                            goalId: widget.goalId,
                            investmentId: selectedInvestmentId!,
                          );

                          if (response != null) {
                            await _loadGoal();
                          }

                          if (!mounted) return;

                          setState(() => isLinkingInvestment = false);
                          setDialogState(() {});

                          if (response != null) {
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Investment linked successfully'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Unable to link investment'),
                              ),
                            );
                          }
                        },
                  child: isLinkingInvestment
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Link'),
                ),
              ],
            );
          },
        );
      },
    );

    if (mounted && isLinkingInvestment) {
      setState(() => isLinkingInvestment = false);
    }
  }

  Widget _metricTile(String label, String value, IconData icon) {
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
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF99A0C7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Widget? action}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = goal;

    if (isLoading && detail == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (detail == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Unable to load goal details',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final progress =
        (_asDouble(detail['progress_percentage']) / 100).clamp(0.0, 1.0);
    final history = detail['contribution_history'];
    final contributions = history is List ? history : [];
    final linkedInvestments = detail['linked_investments'];
    final investmentItems = linkedInvestments is List ? linkedInvestments : [];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(detail['name']?.toString() ?? 'Goal Details'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadGoal,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF111B38), Color(0xFF1D315F)],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFF34436E)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          detail['name']?.toString() ?? 'Goal',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(detail['status'] ?? 'on_track')
                              .withOpacity(0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          (detail['status'] ?? 'on_track').toString().toUpperCase(),
                          style: TextStyle(
                            color: _statusColor(detail['status'] ?? 'on_track'),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${_formatCurrency(detail['total_saved_amount'] ?? detail['saved_amount'])} of ${_formatCurrency(detail['target_amount'])}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.white.withOpacity(0.12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_asDouble(detail['progress_percentage']).toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Investment Contribution',
                          style: TextStyle(
                            color: Color(0xFFB6BFDE),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatCurrency(detail['investment_contribution']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _metricTile(
                  'Remaining',
                  _formatCurrency(detail['remaining_amount']),
                  Icons.savings,
                ),
                _metricTile(
                  'Days Left',
                  '${_asInt(detail['days_left']) ?? 0}',
                  Icons.schedule,
                ),
                _metricTile(
                  'Required / Month',
                  _formatCurrency(detail['required_monthly_saving']),
                  Icons.trending_up,
                ),
                _metricTile(
                  'Deadline',
                  _formatDeadline(detail['deadline']),
                  Icons.event,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionTitle(
              'Linked Investments',
              action: TextButton.icon(
                onPressed: isLoading ? null : _showLinkInvestmentDialog,
                icon: const Icon(Icons.add_link_rounded, size: 18),
                label: const Text('Link Investment'),
              ),
            ),
            const SizedBox(height: 10),
            if (investmentItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.bgInput,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF343754)),
                ),
                child: const Text(
                  'No linked investments yet',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ...investmentItems.map((item) {
              final investment = item as Map<String, dynamic>;
              final isActive = investment['is_active'] == true;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                        color: const Color(0xFF67A8FF).withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Color(0xFF67A8FF),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            investment['investment_name']?.toString() ??
                                'Investment',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            investment['investment_type']?.toString() ?? '',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatCurrency(investment['contribution']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildTag(
                          isActive ? 'Active' : 'Sold',
                          isActive
                              ? const Color(0xFF67A8FF)
                              : const Color(0xFFFFB35C),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            _buildSectionTitle('Contribution History'),
            const SizedBox(height: 10),
            if (contributions.isEmpty)
              const Center(
                child: Text(
                  'No contributions yet',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ...contributions.map((item) {
              final entry = item as Map<String, dynamic>;
              final source = entry['source']?.toString().toLowerCase() ?? 'manual';
              final isInvestment = source == 'investment';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgInput,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF343754)),
                ),
                child: ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatCurrency(entry['amount']),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      _buildTag(
                        isInvestment ? 'Investment' : 'Manual',
                        isInvestment
                            ? const Color(0xFFFFB35C)
                            : const Color(0xFF67A8FF),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      [
                        _formatDeadline(entry['date']),
                        if ((entry['label']?.toString().trim().isNotEmpty ?? false))
                          entry['label'].toString(),
                      ].join(' • '),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'link_investment',
            onPressed: isLoading ? null : _showLinkInvestmentDialog,
            label: const Text('Link Investment'),
            icon: const Icon(Icons.add_link_rounded),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add_contribution',
            onPressed: isLoading ? null : _showAddContributionDialog,
            label: const Text('Add Contribution'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
