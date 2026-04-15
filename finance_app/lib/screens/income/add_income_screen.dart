import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _sourceController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  bool _isLoading = false;

  final _incomeTypes = [
    {'icon': Icons.work_rounded, 'label': 'Salary', 'color': AppColors.primary},
    {'icon': Icons.laptop_rounded, 'label': 'Freelance', 'color': AppColors.accent},
    {'icon': Icons.trending_up_rounded, 'label': 'Investment', 'color': AppColors.success},
    {'icon': Icons.card_giftcard_rounded, 'label': 'Gift', 'color': AppColors.accentPink},
    {'icon': Icons.more_horiz_rounded, 'label': 'Other', 'color': AppColors.accentOrange},
  ];
  int _selectedTypeIndex = 0;

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
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
            'Income added successfully!',
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
        title: const Text('Add Income'),
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
                            color: AppColors.success,
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

              // ── Income Type ──
              Text(
                'Income Type',
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
                  itemCount: _incomeTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final type = _incomeTypes[index];
                    final selected = _selectedTypeIndex == index;
                    final color = type['color'] as Color;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTypeIndex = index;
                          _sourceController.text = type['label'] as String;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 76,
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withValues(alpha: 0.15)
                              : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? color : AppColors.surfaceLight,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              type['icon'] as IconData,
                              color: selected ? color : AppColors.textMuted,
                              size: 24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              type['label'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: selected ? color : AppColors.textMuted,
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

              // ── Source ──
              CustomTextField(
                label: 'Source',
                hint: 'e.g. Monthly salary',
                controller: _sourceController,
                prefixIcon: Icons.source_rounded,
                validator: (v) => Validators.required(v, 'Source'),
              ),
              const SizedBox(height: 20),

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

              // ── Recurring Toggle ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.surfaceLight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.repeat_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Recurring Income',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isRecurring,
                      onChanged: (v) => setState(() => _isRecurring = v),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Submit ──
              CustomButton(
                text: 'Add Income',
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
