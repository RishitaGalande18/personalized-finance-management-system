import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../models/category.dart' as models;

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int _selectedCategoryIndex = 0;
  bool _isLoading = false;

  final categories = models.Category.defaults;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.bgCard,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.bgDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Expense added successfully!',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Amount Input ──
              Center(
                child: Column(
                  children: [
                    Text(
                      'How much?',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹',
                          style: GoogleFonts.inter(
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IntrinsicWidth(
                          child: TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            validator: Validators.amount,
                            style: GoogleFonts.inter(
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 42,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textHint,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              filled: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Category Selection ──
              Text(
                'Category',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final selected = _selectedCategoryIndex == index;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategoryIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 76,
                        decoration: BoxDecoration(
                          color: selected
                              ? cat.color.withValues(alpha: 0.15)
                              : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? cat.color
                                : AppColors.surfaceLight,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              cat.icon,
                              color: selected
                                  ? cat.color
                                  : AppColors.textMuted,
                              size: 24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cat.name,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: selected
                                    ? cat.color
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ── Date ──
              CustomTextField(
                label: 'Date',
                hint: DateFormat('dd MMM yyyy').format(_selectedDate),
                readOnly: true,
                onTap: _selectDate,
                prefixIcon: Icons.calendar_today_rounded,
                suffix: const Icon(
                  Icons.arrow_drop_down_rounded,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),

              // ── Description ──
              CustomTextField(
                label: 'Description (optional)',
                hint: 'What was this expense for?',
                controller: _descriptionController,
                prefixIcon: Icons.notes_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // ── Submit ──
              CustomButton(
                text: 'Add Expense',
                icon: Icons.add_rounded,
                isLoading: _isLoading,
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
