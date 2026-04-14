import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class HealthAlertsScreen extends StatefulWidget {
  const HealthAlertsScreen({super.key});

  @override
  State<HealthAlertsScreen> createState() => _HealthAlertsScreenState();
}

class _HealthAlertsScreenState extends State<HealthAlertsScreen> {
  double healthScore = 0.0;
  List<dynamic> alerts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHealthAndAlerts();
  }

  Future<void> loadHealthAndAlerts() async {
    setState(() => isLoading = true);
    try {
      final healthData = await ApiService.getHealthScore();
      final alertsData = await ApiService.getAlerts();
      
      setState(() {
        healthScore = (healthData?['score'] ?? 0).toDouble();
        alerts = alertsData ?? [];
        isLoading = false;
      });
    } catch (e) {
      print("Error loading health/alerts: $e");
      setState(() => isLoading = false);
    }
  }

  Color getHealthColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1E3C),
      appBar: AppBar(
        title: const Text("Financial Health & Alerts"),
        backgroundColor: const Color(0xFF1E2E4A),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Health Score Card
                  Card(
                    color: const Color(0xFF1E2E4A),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text(
                            "Financial Health Score",
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                height: 150,
                                width: 150,
                                child: CircularProgressIndicator(
                                  value: healthScore / 100,
                                  strokeWidth: 12,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    getHealthColor(healthScore),
                                  ),
                                  backgroundColor: Colors.grey[700],
                                ),
                              ),
                              Text(
                                '${healthScore.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            healthScore >= 80
                                ? "Excellent Financial Health"
                                : healthScore >= 60
                                    ? "Good Financial Health"
                                    : "Needs Improvement",
                            style: TextStyle(
                              color: getHealthColor(healthScore),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Alerts Section
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      "Alerts",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (alerts.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "No alerts at this time",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        return Card(
                          color: alert['severity'] == 'critical'
                              ? const Color(0xFF4A1E1E)
                              : alert['severity'] == 'warning'
                                  ? const Color(0xFF4A3A1E)
                                  : const Color(0xFF1E2E4A),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        alert['message'] ?? 'Alert',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        alert['severity'] ?? 'info',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10),
                                      ),
                                      backgroundColor: alert['severity'] ==
                                              'critical'
                                          ? Colors.red
                                          : alert['severity'] == 'warning'
                                              ? Colors.orange
                                              : Colors.blue,
                                    ),
                                  ],
                                ),
                                if (alert['description'] != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    alert['description'],
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await ApiService.generateAlerts();
          loadHealthAndAlerts();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
