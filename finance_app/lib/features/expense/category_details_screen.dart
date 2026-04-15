import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import 'expense_categories_screen.dart';

class CategoryDetailsScreen extends StatefulWidget {
  const CategoryDetailsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  final int categoryId;
  final String categoryName;

  @override
  State<CategoryDetailsScreen> createState() => _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends State<CategoryDetailsScreen> {
  static const Color _background = Color(0xFF0B1E3C);
  static const Color _surface = Color(0xFF10264B);
  static const Color _surfaceSoft = Color(0xFF16315D);
  static const Color _textMuted = Color(0xFF8FA7CE);
  static const Color _green = Color(0xFF2ED47A);
  static const Color _red = Color(0xFFFF5A6B);

  bool _isLoading = true;
  bool _isSavingLimit = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _transactions = [];
  double _amountSpent = 0;
  double? _limit;

  @override
  void initState() {
    super.initState();
    _loadCategoryDetails();
  }

  Future<void> _loadCategoryDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categoryExpenses = await ApiService.getExpensesByCategory(widget.categoryId);
      final summary = await ApiService.getExpenseSummary();
      final categories = await ApiService.getCategories();

      final transactions = _normalizeTransactions(categoryExpenses)
          .where(_matchesCurrentCategory)
          .toList();
      final categorySummary = _resolveCategorySummary(summary, categories);

      if (!mounted) {
        return;
      }

      setState(() {
        _transactions = transactions;
        _amountSpent = categorySummary.amount > 0
            ? categorySummary.amount
            : _calculateAmount(transactions);
        _limit = categorySummary.limit;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load this category right now.';
      });
      debugPrint('Category details load error: $error');
    }
  }

  List<Map<String, dynamic>> _normalizeTransactions(List<dynamic>? response) {
    if (response == null) {
      return <Map<String, dynamic>>[];
    }

    return response
        .whereType<Map<String, dynamic>>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  bool _matchesCurrentCategory(Map<String, dynamic> expense) {
    final categoryId = _readInt(expense['category_id']);
    if (categoryId != null) {
      return categoryId == widget.categoryId;
    }

    final categoryName = _extractCategoryName(expense);
    return categoryName.toLowerCase() == widget.categoryName.toLowerCase();
  }

  _CategorySnapshot _resolveCategorySummary(
    Map<String, dynamic>? summary,
    List<dynamic>? categories,
  ) {
    double amount = 0;
    double? limit;

    final summaryCategories = summary?['categories'];
    if (summaryCategories is List) {
      for (final item in summaryCategories.whereType<Map<String, dynamic>>()) {
        if (_readInt(item['id']) == widget.categoryId) {
          amount = _readDouble(item['amount']);
          limit = _readNullableDouble(item['limit']);
          break;
        }
      }
    }

    if (amount == 0) {
      final breakdown = summary?['category_breakdown'];
      if (breakdown is Map<String, dynamic>) {
        for (final entry in breakdown.entries) {
          if (entry.key.toLowerCase() == widget.categoryName.toLowerCase()) {
            amount = _readDouble(entry.value);
            break;
          }
        }
      }
    }

    for (final item in categories ?? <dynamic>[]) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final itemId = _readInt(item['id']);
      if (itemId == widget.categoryId) {
        limit ??= _readNullableDouble(item['budget_limit']);
        break;
      }
    }

    return _CategorySnapshot(amount: amount, limit: limit);
  }

  double _calculateAmount(List<Map<String, dynamic>> transactions) {
    return transactions.fold<double>(0, (sum, item) {
      return sum + _readDouble(item['amount']);
    });
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

  String _extractCategoryName(Map<String, dynamic> expense) {
    final category = expense['category'];
    if (category is String) {
      return category;
    }

    if (category is Map<String, dynamic> && category['name'] != null) {
      return category['name'].toString();
    }

    if (expense['category_name'] != null) {
      return expense['category_name'].toString();
    }

    return '';
  }

  DateTime? _parseDate(dynamic rawDate) {
    if (rawDate is String) {
      return DateTime.tryParse(rawDate);
    }

    if (rawDate is DateTime) {
      return rawDate;
    }

    return null;
  }

  String _formatCurrency(double amount) {
    return '\u20B9${amount.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'No date';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _showSetLimitDialog() async {
    final controller = TextEditingController(
      text: _limit != null ? _limit!.toStringAsFixed(0) : '',
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
            'Set Limit',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter category limit',
              hintStyle: const TextStyle(color: _textMuted),
              prefixText: '\u20B9 ',
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
              onPressed: _isSavingLimit ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isSavingLimit
                  ? null
                  : () async {
                      final value = double.tryParse(controller.text.trim());
                      if (value == null || value <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid limit amount.'),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(dialogContext);
                      await _setLimit(value);
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

  Future<void> _setLimit(double value) async {
    setState(() {
      _isSavingLimit = true;
    });

    final response = await ApiService.setCategoryLimit(
      categoryId: widget.categoryId,
      limit: value,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSavingLimit = false;
    });

    if (response == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update category limit.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Category limit updated successfully.')),
    );

    await _loadCategoryDetails();
  }

  @override
  Widget build(BuildContext context) {
    final exceeded = _limit != null && _amountSpent > _limit!;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _background,
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadCategoryDetails,
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
                ? _CategoryErrorState(
                    message: _errorMessage!,
                    onRetry: _loadCategoryDetails,
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                        child: _buildHeaderCard(exceeded),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Transactions',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${_transactions.length} items',
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
                        child: _transactions.isEmpty
                            ? const _NoTransactionsState()
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                itemCount: _transactions.length,
                                itemBuilder: (context, index) {
                                  final transaction = _transactions[index];
                                  final amount = _readDouble(transaction['amount']);
                                  final date = _parseDate(
                                    transaction['date'] ??
                                        transaction['transaction_date'] ??
                                        transaction['created_at'],
                                  );

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color.fromRGBO(255, 255, 255, 0.05),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: _surfaceSoft,
                                          child: Icon(
                                            getCategoryIcon(widget.categoryName),
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (transaction['description'] ?? 'Expense')
                                                    .toString(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatDate(date),
                                                style: const TextStyle(
                                                  color: _textMuted,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _formatCurrency(amount),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildHeaderCard(bool exceeded) {
    final ringColor = exceeded
        ? _red
        : _limit != null
            ? _green
            : const Color(0xFF4E78C9);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.16),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor, width: 2.5),
                ),
                child: CircleAvatar(
                  backgroundColor: _surfaceSoft,
                  child: Icon(
                    getCategoryIcon(widget.categoryName),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.categoryName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _limit != null
                          ? 'Limit: ${_formatCurrency(_limit!)}'
                          : 'No budget limit set yet',
                      style: const TextStyle(
                        color: _textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _formatCurrency(_amountSpent),
            style: TextStyle(
              color: exceeded ? _red : Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            exceeded ? 'Limit exceeded' : 'Current spend in this category',
            style: TextStyle(
              color: exceeded ? _red : _green,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSavingLimit ? null : _showSetLimitDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E6BFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(_isSavingLimit ? 'Saving...' : 'Set Limit'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoTransactionsState extends StatelessWidget {
  const _NoTransactionsState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              color: Colors.white54,
              size: 52,
            ),
            SizedBox(height: 14),
            Text(
              'No transactions found for this category.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'New expenses in this category will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8FA7CE),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryErrorState extends StatelessWidget {
  const _CategoryErrorState({
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

class _CategorySnapshot {
  const _CategorySnapshot({
    required this.amount,
    required this.limit,
  });

  final double amount;
  final double? limit;
}
