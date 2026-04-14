import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import 'category_details_screen.dart';

IconData getCategoryIcon(String categoryName) {
  switch (categoryName.toLowerCase()) {
    case 'food':
    case 'dining':
      return Icons.restaurant_rounded;
    case 'travel':
    case 'transport':
      return Icons.directions_car_rounded;
    case 'shopping':
      return Icons.shopping_bag_rounded;
    case 'bills':
    case 'utilities':
      return Icons.receipt_long_rounded;
    case 'health':
    case 'medical':
      return Icons.favorite_rounded;
    case 'education':
      return Icons.school_rounded;
    case 'entertainment':
      return Icons.movie_rounded;
    case 'rent':
    case 'home':
      return Icons.home_rounded;
    case 'salary':
    case 'income':
      return Icons.account_balance_wallet_rounded;
    default:
      return Icons.category_rounded;
  }
}

class ExpenseCategoriesScreen extends StatefulWidget {
  const ExpenseCategoriesScreen({super.key});

  @override
  State<ExpenseCategoriesScreen> createState() => _ExpenseCategoriesScreenState();
}

class _ExpenseCategoriesScreenState extends State<ExpenseCategoriesScreen> {
  static const Color _background = Color(0xFF0B1E3C);
  static const Color _surface = Color(0xFF10264B);
  static const Color _surfaceSoft = Color(0xFF16315D);
  static const Color _textMuted = Color(0xFF8FA7CE);

  bool _isLoading = true;
  String? _errorMessage;
  double _totalExpense = 0;
  List<_ExpenseCategoryItem> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadExpenseSummary();
  }

  Future<void> _loadExpenseSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await ApiService.getExpenseSummary();
      final categoriesResponse = await ApiService.getCategories();
      final categories = _buildCategories(
        summary: summary,
        categoryResponse: categoriesResponse,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _totalExpense = _readDouble(summary?['total_expense']);
        _categories = categories;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load expenses right now.';
      });
      debugPrint('Expense summary load error: $error');
    }
  }

  List<_ExpenseCategoryItem> _buildCategories({
    Map<String, dynamic>? summary,
    List<dynamic>? categoryResponse,
  }) {
    final categoriesByName = <String, Map<String, dynamic>>{};
    final categoriesById = <int, Map<String, dynamic>>{};
    final amountsById = <int, double>{};
    final amountsByName = <String, double>{};
    final limitById = <int, double?>{};
    final limitByName = <String, double?>{};

    for (final item in categoryResponse ?? <dynamic>[]) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final name = (item['name'] ?? '').toString().trim();
      if (name.isNotEmpty) {
        categoriesByName[name.toLowerCase()] = item;
      }

      final id = _readInt(item['id']);
      if (id != null) {
        categoriesById[id] = item;
      }
    }

    final summaryCategories = summary?['categories'];
    if (summaryCategories is List) {
      for (final item in summaryCategories.whereType<Map<String, dynamic>>()) {
        final id = _readInt(item['id']);
        final name = (item['name'] ?? '').toString().trim();
        final amount = _readDouble(item['amount']);
        final limit = _readNullableDouble(item['limit']);

        if (id != null) {
          amountsById[id] = amount;
          limitById[id] = limit;
        }

        if (name.isNotEmpty) {
          amountsByName[name.toLowerCase()] = amount;
          limitByName[name.toLowerCase()] = limit;
        }
      }
    }

    final categoryBreakdown = summary?['category_breakdown'];
    if (categoryBreakdown is Map<String, dynamic>) {
      for (final entry in categoryBreakdown.entries) {
        amountsByName[entry.key.toLowerCase()] = _readDouble(entry.value);
      }
    }

    final categories = <_ExpenseCategoryItem>[];
    for (final item in categoryResponse ?? <dynamic>[]) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final id = _readInt(item['id']);
      final name = (item['name'] ?? 'Others').toString();
      final key = name.toLowerCase();
      final amount = (id != null ? amountsById[id] : null) ?? amountsByName[key] ?? 0;
      final limit = _readNullableDouble(item['budget_limit']) ??
          (id != null ? limitById[id] : null) ??
          limitByName[key];

      categories.add(_ExpenseCategoryItem(
        id: id,
        name: name,
        amount: amount,
        limit: limit,
      ));
    }

    if (categories.isNotEmpty) {
      return categories;
    }

    if (summaryCategories is List) {
      return summaryCategories
          .whereType<Map<String, dynamic>>()
          .map((item) {
            final id = _readInt(item['id']);
            final name = (item['name'] ?? 'Others').toString();
            return _ExpenseCategoryItem(
              id: id,
              name: name,
              amount: _readDouble(item['amount']),
              limit: _readNullableDouble(item['limit']),
            );
          })
          .toList();
    }

    if (categoryBreakdown is Map<String, dynamic>) {
      return categoryBreakdown.entries.map((entry) {
        final linkedCategory = categoriesByName[entry.key.toLowerCase()];
        return _ExpenseCategoryItem(
          id: _readInt(linkedCategory?['id']),
          name: entry.key,
          amount: _readDouble(entry.value),
          limit: _readNullableDouble(linkedCategory?['budget_limit']),
        );
      }).toList();
    }

    return <_ExpenseCategoryItem>[];
  }

  double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  double? _readNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is String && value.trim().isEmpty) {
      return null;
    }

    return _readDouble(value);
  }

  int? _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  String _formatCurrency(double amount) {
    return '\u20B9${amount.toStringAsFixed(0)}';
  }

  void _openCategory(_ExpenseCategoryItem category) {
    final categoryId = category.id;
    if (categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category details are unavailable for this item.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryDetailsScreen(
          categoryId: categoryId,
          categoryName: category.name,
        ),
      ),
    ).then((_) => _loadExpenseSummary());
  }

  Future<void> _showSetLimitDialog(_ExpenseCategoryItem category) async {
    if (category.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot set limit for this category right now.')),
      );
      return;
    }

    final controller = TextEditingController(
      text: category.limit != null ? category.limit!.toStringAsFixed(0) : '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Set Category Limit',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter limit amount',
              hintStyle: const TextStyle(color: _textMuted),
              prefixText: '9 ',
              prefixStyle: const TextStyle(color: Colors.white),
              filled: true,
              fillColor: _surfaceSoft,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF244673)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF2E6BFF)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final value = double.tryParse(controller.text.trim());
                if (value == null || value <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid limit amount.'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                await _setLimit(category.id!, value);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E6BFF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _setLimit(int categoryId, double value) async {
    final messenger = ScaffoldMessenger.of(context);
    final response = await ApiService.setCategoryLimit(
      categoryId: categoryId,
      limit: value,
    );

    if (!mounted) {
      return;
    }

    if (response == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to update category limit.')),
      );
      return;
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Category limit updated successfully.')),
    );

    await _loadExpenseSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _background,
        title: const Text(
          'Expenses',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadExpenseSummary,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _errorMessage != null
                ? _ErrorState(
                    message: _errorMessage!,
                    onRetry: _loadExpenseSummary,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                        child: _buildSummaryCard(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Categories',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${_categories.length} total',
                              style: const TextStyle(
                                color: _textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: _categories.isEmpty
                            ? _EmptyState(onRefresh: _loadExpenseSummary)
                            : Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: GridView.builder(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  itemCount: _categories.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    childAspectRatio: 0.86,
                                  ),
                                  itemBuilder: (context, index) {
                                    final category = _categories[index];
                                    return _CategoryCard(
                                      category: category,
                                      formatCurrency: _formatCurrency,
                                                              onTap: () => _openCategory(category),
                                      onLimitPressed: () => _showSetLimitDialog(category),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E6BFF),
        onPressed: () {
          Navigator.pushNamed(context, '/add-expense').then((_) => _loadExpenseSummary());
        },
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF17396C), Color(0xFF0E274D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.18),
            blurRadius: 26,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Expense',
            style: TextStyle(
              color: _textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _formatCurrency(_totalExpense),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Monitor category spend and budget limits in one place',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.formatCurrency,
    required this.onTap,
    required this.onLimitPressed,
  });

  final _ExpenseCategoryItem category;
  final String Function(double amount) formatCurrency;
  final VoidCallback onTap;
  final VoidCallback onLimitPressed;

  static const Color _surface = Color(0xFF10264B);
  static const Color _surfaceSoft = Color(0xFF16315D);
  static const Color _textMuted = Color(0xFF8FA7CE);
  static const Color _green = Color(0xFF2ED47A);
  static const Color _red = Color(0xFFFF5A6B);

  @override
  Widget build(BuildContext context) {
    final exceeded = category.hasLimit && category.amount > category.limit!;
    final ringColor = exceeded
        ? _red
        : category.hasLimit
            ? _green
            : const Color(0xFF4E78C9);

    final amountColor = exceeded ? _red : Colors.white;
    final icon = getCategoryIcon(category.name);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // ✅ FIXED
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔹 TOP CONTENT
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ringColor, width: 2),
                  ),
                  child: CircleAvatar(
                    backgroundColor: _surfaceSoft,
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  formatCurrency(category.amount),
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  category.hasLimit
                      ? "Limit: ${formatCurrency(category.limit!)}"
                      : "No limit set",
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),

            /// 🔹 BOTTOM ACTIONS
            Row(
              children: [

                Expanded(
                  child: GestureDetector(
                    onTap: onLimitPressed,
                    child: Text(
                      category.hasLimit ? "Edit" : "Set",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: exceeded ? _red : _green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                Flexible(
                  child: Text(
                    exceeded ? "Exceeded" : "View",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: exceeded ? _red : _green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pie_chart_rounded,
              color: Colors.white54,
              size: 54,
            ),
            const SizedBox(height: 14),
            const Text(
              'No expense categories available yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a few expenses and your category budget view will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8FA7CE),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onRefresh,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF305A94)),
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white54,
              size: 54,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E6BFF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseCategoryItem {
  const _ExpenseCategoryItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.limit,
  });

  final int? id;
  final String name;
  final double amount;
  final double? limit;

  bool get hasLimit => limit != null && limit! > 0;
}
