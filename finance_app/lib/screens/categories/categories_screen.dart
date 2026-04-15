import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../utils/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/validators.dart';
import '../../models/category.dart' as models;
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoryPageData {
  final List<models.Category> categories;
  final Map<String, double> categoryExpenseBreakdown;
  final double totalExpense;

  _CategoryPageData({
    required this.categories,
    required this.categoryExpenseBreakdown,
    required this.totalExpense,
  });
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<_CategoryPageData> _pageFuture;

  @override
  void initState() {
    super.initState();
    _pageFuture = _loadPageData();
  }

  Future<_CategoryPageData> _loadPageData() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final categories = await ApiService.fetchCategories(token);
    final summaryValues = await ApiService.fetchExpenseSummary(token);
    final totalExpense = summaryValues['totalExpense'] ?? 0;
    final breakdown = Map<String, double>.fromEntries(
      summaryValues.entries
          .where((entry) => entry.key != 'totalExpense')
          .map((entry) => MapEntry(entry.key, entry.value)),
    );

    return _CategoryPageData(
      categories: categories,
      categoryExpenseBreakdown: breakdown,
      totalExpense: totalExpense,
    );
  }

  Future<void> _refreshCategories() async {
    setState(() {
      _pageFuture = _loadPageData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<_CategoryPageData>(
          future: _pageFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to load categories.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            final totalBudget = data.categories.fold<int>(0, (sum, category) {
              return sum + (category.budgetLimit ?? 0);
            });

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Categories',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showAddCategoryDialog,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Budget',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹$totalBudget',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total Spent',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${data.totalExpense.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentOrange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: data.categories.length,
                    itemBuilder: (context, index) {
                      final category = data.categories[index];
                      final spent = data.categoryExpenseBreakdown[category.name] ?? 0;
                      return _buildCategoryTile(category, spent);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryTile(models.Category category, double spent) {
    final budget = category.budgetLimit?.toDouble() ?? 0;
    final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = spent > budget;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: models.Category.colorFor(category.name).withAlpha((0.15 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(models.Category.iconFor(category.name), color: models.Category.colorFor(category.name), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${spent.toStringAsFixed(0)} of ₹${budget.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOverBudget)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha((0.15 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Over',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                )
              else
                Text(
                  '${(progress * 100).toInt()}%',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: progress > 0.8 ? AppColors.warning : AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.bgInput,
              color: isOverBudget
                  ? AppColors.error
                  : progress > 0.8
                      ? AppColors.warning
                      : models.Category.colorFor(category.name),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final budgetController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'New Category',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  label: 'Category Name',
                  hint: 'e.g. Subscriptions',
                  controller: nameController,
                  prefixIcon: Icons.category_rounded,
                  validator: Validators.name,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Budget Limit',
                  hint: 'e.g. 5000',
                  controller: budgetController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.currency_rupee_rounded,
                  validator: Validators.amount,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Add Category',
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    try {
                      final token = context.read<AuthProvider>().token;
                      if (token == null) {
                        throw Exception('Not authenticated');
                      }

                      await ApiService.addCategory(
                        token,
                        nameController.text.trim(),
                        int.tryParse(budgetController.text.trim()),
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        await _refreshCategories();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Category added!',
                              style: GoogleFonts.inter(),
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error.toString()),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
