import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../utils/app_colors.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<dynamic> goals = [];
  List<dynamic> goalProgress = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadGoals();
  }

  Future<void> loadGoals() async {
    setState(() => isLoading = true);
    try {
      final goalsData = await ApiService.getGoals();
      final progressData = await ApiService.getGoalProgress();
      setState(() {
        goals = goalsData ?? [];
        goalProgress = progressData ?? [];
        isLoading = false;
      });
    } catch (e) {
      print("Error loading goals: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text("Financial Goals"),
        backgroundColor: AppColors.primaryDark,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : goals.isEmpty
              ? const Center(
                  child: Text("No goals set yet",
                      style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    final progress = goalProgress.isNotEmpty && index < goalProgress.length
                        ? goalProgress[index]['progress'] ?? 0.0
                        : 0.0;
                    
                    return Card(
                      color: AppColors.bgCard,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal['name'] ?? 'Goal',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Target Amount:",
                                    style:
                                        TextStyle(color: Colors.white70)),
                                Text(
                                  '\$${goal['target_amount']?.toStringAsFixed(2) ?? '0'}',
                                  style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Saved Amount:",
                                    style:
                                        TextStyle(color: Colors.white70)),
                                Text(
                                  '\$${goal['saved_amount']?.toStringAsFixed(2) ?? '0'}',
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Deadline:",
                                    style:
                                        TextStyle(color: Colors.white70)),
                                Text(
                                  goal['deadline'] ?? '-',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress / 100,
                                minHeight: 8,
                                backgroundColor: Colors.grey[700],
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        Colors.blue),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${progress.toStringAsFixed(1)}% Complete",
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            Chip(
                              label: Text(
                                goal['priority'] ?? 'Medium',
                                style:
                                    const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: goal['priority'] == 'High'
                                  ? Colors.red
                                  : goal['priority'] == 'Medium'
                                      ? Colors.orange
                                      : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.pushNamed(context, '/add-goal').then((_) => loadGoals()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
