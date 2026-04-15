import 'package:flutter/material.dart';

class Category {
  final int? id;
  final String name;
  final int? budgetLimit;
  final double spent;
  final IconData icon;
  final Color color;

  Category({
    this.id,
    required this.name,
    this.budgetLimit,
    this.spent = 0,
    this.icon = Icons.category_rounded,
    this.color = const Color(0xFF6C5CE7),
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'] ?? '',
      budgetLimit: json['budget_limit'] != null
          ? (json['budget_limit'] as num).toInt()
          : null,
      spent: json['spent'] != null ? (json['spent'] as num).toDouble() : 0,
    );
  }

  /// Default categories with icons and colors for display
  static List<Category> get defaults => [
    Category(name: 'Food', icon: Icons.restaurant_rounded, color: const Color(0xFFFF9100)),
    Category(name: 'Transport', icon: Icons.directions_car_rounded, color: const Color(0xFF448AFF)),
    Category(name: 'Shopping', icon: Icons.shopping_bag_rounded, color: const Color(0xFFFF6B9D)),
    Category(name: 'Entertainment', icon: Icons.movie_rounded, color: const Color(0xFFE040FB)),
    Category(name: 'Health', icon: Icons.favorite_rounded, color: const Color(0xFFFF5252)),
    Category(name: 'Bills', icon: Icons.receipt_long_rounded, color: const Color(0xFFFFAB40)),
    Category(name: 'Education', icon: Icons.school_rounded, color: const Color(0xFF00D2FF)),
    Category(name: 'Others', icon: Icons.more_horiz_rounded, color: const Color(0xFF6B7094)),
  ];

  /// Get icon for a category name
  static IconData iconFor(String name) {
    final match = defaults.where(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
    );
    return match.isNotEmpty ? match.first.icon : Icons.category_rounded;
  }

  /// Get color for a category name
  static Color colorFor(String name) {
    final match = defaults.where(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
    );
    return match.isNotEmpty ? match.first.color : const Color(0xFF6C5CE7);
  }
}
