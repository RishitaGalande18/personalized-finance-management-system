import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/navigation/main_navigation.dart';
import 'features/expense/add_expense_screen.dart';
import 'features/expense/expense_list_screen.dart';
import 'features/income/income_screen.dart';
import 'features/health/health_alerts_screen.dart';
import 'features/investment/add_investment_screen.dart';
import 'features/debt/add_debt_screen.dart';
import 'features/goal/add_goal_screen.dart';

void main() {
  runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainNavigation(),
        '/add-expense': (context) => const AddExpenseScreen(),
        '/expenses': (context) => const ExpenseListScreen(),
        '/income': (context) => const IncomeManagementScreen(),
        '/health-alerts': (context) => const HealthAlertsScreen(),
        '/add-investment': (context) => const AddInvestmentScreen(),
        '/add-debt': (context) => const AddDebtScreen(),
        '/add-goal': (context) => const AddGoalScreen(),
      },
    );
  }
}