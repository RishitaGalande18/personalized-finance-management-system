import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'dashboard_screen.dart';
import '../categories/categories_screen.dart';
import '../profile/profile_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    CategoriesScreen(),
    Center(child: Text('Insights/AI')), // Placeholder for the 3rd icon (Sparkles)
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home_rounded),
              _buildNavItem(1, Icons.track_changes_rounded, Icons.track_changes_rounded),
              _buildNavItem(2, Icons.auto_awesome_outlined, Icons.auto_awesome_rounded),
              _buildNavItem(3, Icons.trending_up_rounded, Icons.trending_up_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon) {
    final selected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? selectedIcon : icon,
            size: 28,
            color: selected ? Colors.white : const Color(0xFFB0B3C6),
          ),
          const SizedBox(height: 4),
          if (selected)
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
