import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../dashboard/dashboard_screen.dart';
import '../expense/expense_list_screen.dart';
import '../investment/investment_screen.dart';
import '../debt/debt_screen.dart';
import '../goal/goal_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {

  int currentIndex = 0;

  final screens = [
    const DashboardScreen(),
    const ExpenseListScreen(),
    const InvestmentPortfolioScreen(),
    const DebtManagementScreen(),
    const GoalsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: screens[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.primaryDark,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: "Expenses",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: "Investments",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: "Debt",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: "Goals",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}