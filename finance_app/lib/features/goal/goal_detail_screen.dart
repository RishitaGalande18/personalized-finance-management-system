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
  final NumberFormat _currencyFormat =
      NumberFormat.currency(symbol: '₹');

  final DateFormat _displayDateFormat =
      DateFormat('dd MMM yyyy');

  final TextEditingController _amountController =
      TextEditingController();

  Map<String, dynamic>? goal;
  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    goal = widget.initialGoal;
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    setState(() => isLoading = true);

    final response =
        await ApiService.getGoalDetail(widget.goalId);

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
    if (value == null || value.toString().isEmpty)
      return 'No deadline';
    try {
      return _displayDateFormat
          .format(DateTime.parse(value.toString()));
    } catch (_) {
      return value.toString();
    }
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
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                    const TextInputType.numberWithOptions(
                        decimal: true),
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon:
                      Icon(Icons.attach_money_rounded),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final amount = double.tryParse(
                              _amountController.text.trim());

                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Enter a valid contribution amount'),
                              ),
                            );
                            return;
                          }

                          setState(() => isSubmitting = true);
                          setDialogState(() {});

                          final response =
                              await ApiService
                                  .contributeToGoal(
                            goalId: widget.goalId,
                            amount: amount,
                          );

                          if (!mounted) return;

                          setState(() => isSubmitting = false);
                          setDialogState(() {});

                          if (response != null) {
                            Navigator.of(context).pop();
                            setState(() => goal = response);

                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Contribution added successfully'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Unable to add contribution'),
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
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

  Widget _metricTile(
      String label, String value, IconData icon) {
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
        (_asDouble(detail['progress_percentage']) / 100)
            .clamp(0.0, 1.0);

    final history = detail['contribution_history'];
    final contributions =
        history is List ? history : [];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title:
            Text(detail['name']?.toString() ?? 'Goal Details'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadGoal,
        child: ListView(
          padding:
              const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [

            /// HEADER CARD
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF111B38), Color(0xFF1D315F)],
                ),
                borderRadius: BorderRadius.circular(30),
                border:
                    Border.all(color: const Color(0xFF34436E)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          detail['name'] ?? 'Goal',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8),
                        decoration: BoxDecoration(
                          color: _statusColor(
                                  detail['status'] ??
                                      'on_track')
                              .withOpacity(0.16),
                          borderRadius:
                              BorderRadius.circular(999),
                        ),
                        child: Text(
                          (detail['status'] ?? 'on_track')
                              .toUpperCase(),
                          style: TextStyle(
                            color: _statusColor(
                                detail['status'] ??
                                    'on_track'),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Text(
                    '${_formatCurrency(detail['saved_amount'])} of ${_formatCurrency(detail['target_amount'])}',
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
                    backgroundColor:
                        Colors.white.withOpacity(0.12),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '${_asDouble(detail['progress_percentage']).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// METRICS GRID
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _metricTile(
                    "Remaining",
                    _formatCurrency(
                        detail['remaining_amount']),
                    Icons.savings),
                _metricTile(
                    "Days Left",
                    '${_asInt(detail['days_left']) ?? 0}',
                    Icons.schedule),
                _metricTile(
                    "Required / Month",
                    _formatCurrency(
                        detail['required_monthly_saving']),
                    Icons.trending_up),
                _metricTile("Deadline",
                    _formatDeadline(detail['deadline']),
                    Icons.event),
              ],
            ),

            const SizedBox(height: 20),

            /// HISTORY
            const Text(
              "Contribution History",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            if (contributions.isEmpty)
              const Center(
                child: Text(
                  "No contributions yet",
                  style: TextStyle(color: Colors.white70),
                ),
              ),

            ...contributions.map((item) {
              final entry = item as Map<String, dynamic>;

              return ListTile(
                title: Text(
                  _formatCurrency(entry['amount']),
                  style:
                      const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  _formatDeadline(entry['date']),
                  style: const TextStyle(
                      color: Colors.white70),
                ),
              );
            }),
          ],
        ),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            isLoading ? null : _showAddContributionDialog,
        label: const Text("Add Contribution"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}

