import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/api_service.dart';
import '../../utils/app_colors.dart';
import 'goal_detail_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<dynamic> goals = [];
  Map<String, dynamic>? summary;
  bool isLoading = true;

  final NumberFormat _currencyFormat =
      NumberFormat.currency(symbol: '₹'); // FIXED

  @override
  void initState() {
    super.initState();
    loadGoals();
  }

  Future<void> loadGoals() async {
    setState(() => isLoading = true);
    try {
      final goalsData = await ApiService.getGoals();
      final summaryData = await ApiService.getGoalSummary();

      if (!mounted) return;

      setState(() {
        goals = goalsData ?? [];
        summary = summaryData ?? {};
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading goals: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  String _formatCurrency(dynamic value) =>
      _currencyFormat.format(_asDouble(value));

  String _formatDeadline(dynamic value) {
    if (value == null || value.toString().isEmpty) return 'No deadline';
    try {
      return DateFormat('dd MMM yyyy')
          .format(DateTime.parse(value.toString()));
    } catch (_) {
      return value.toString();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF3DDC97);
      case 'behind':
        return const Color(0xFFFF8C6B);
      default:
        return const Color(0xFF6FA8FF);
    }
  }

  Widget _goalMeta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8891BC),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final overallProgress =
        (_asDouble(summary?['overall_progress_percentage']) / 100)
            .clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Financial Goals'),
        backgroundColor: Colors.transparent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadGoals,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 96),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF101B37), Color(0xFF173465)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFF34436E)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.24), // FIXED
                          blurRadius: 28,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Goals Overview',
                          style: TextStyle(
                            color: Color(0xFFB3C7FF),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_asInt(summary?['total_goals'])} active goals',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          '${_formatCurrency(summary?['total_saved_amount'])} / ${_formatCurrency(summary?['total_target_amount'])}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: overallProgress,
                            minHeight: 12,
                            backgroundColor:
                                Colors.white.withOpacity(0.12), // FIXED
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF7EB6FF)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${_asDouble(summary?['overall_progress_percentage']).toStringAsFixed(1)}% overall progress',
                          style: const TextStyle(
                            color: Color(0xFFD0DCFF),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Your Goals',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (goals.isEmpty)
                    const Center(
                      child: Text(
                        'No goals set yet',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                  ...goals.map((item) {
                    final goal = item as Map<String, dynamic>;
                    final progress =
                        (_asDouble(goal['progress_percentage']) / 100)
                            .clamp(0.0, 1.0);

                    final status =
                        goal['status']?.toString() ?? 'on_track';

                    return GestureDetector(
                      onTap: () async {
                        final goalId = _asInt(goal['id']);
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GoalDetailScreen(
                              goalId: goalId,
                              initialGoal: goal,
                            ),
                          ),
                        );
                        loadGoals();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                              color: const Color(0xFF2F3351)),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    goal['name']?.toString() ??
                                        'Goal',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status)
                                        .withOpacity(0.16), // FIXED
                                    borderRadius:
                                        BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    status
                                        .replaceAll('_', ' ')
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color:
                                          _statusColor(status),
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${_formatCurrency(goal['saved_amount'])} saved of ${_formatCurrency(goal['target_amount'])}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 10,
                                backgroundColor:
                                    Colors.white.withOpacity(0.06), // FIXED
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                        _statusColor(status)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _goalMeta(
                                    'Remaining',
                                    _formatCurrency(
                                        goal['remaining_amount']),
                                  ),
                                ),
                                Expanded(
                                  child: _goalMeta(
                                    'Deadline',
                                    _formatDeadline(
                                        goal['deadline']),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${_asDouble(goal['progress_percentage']).toStringAsFixed(1)}% complete',
                              style: const TextStyle(
                                color: Color(0xFF9FA7CD),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-goal')
            .then((_) => loadGoals()),
        backgroundColor: const Color(0xFF7D8CFF),
        child: const Icon(Icons.add),
      ),
    );
  }
}

