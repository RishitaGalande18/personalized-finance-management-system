import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.height = 54,
    this.borderRadius = 14,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: widget.width ?? double.infinity,
          height: widget.height,
          child: widget.isOutlined
              ? _buildOutlinedButton()
              : _buildFilledButton(),
        ),
      ),
    );
  }

  Widget _buildFilledButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: widget.onPressed != null
            ? AppColors.primaryGradient
            : null,
        color: widget.onPressed == null
            ? AppColors.textMuted.withValues(alpha: 0.3)
            : null,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: widget.onPressed != null
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Center(child: _buildContent()),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Center(child: _buildContent()),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Colors.white,
        ),
      );
    }

    final contentColor = widget.isOutlined
        ? AppColors.primary
        : widget.onPressed == null
            ? AppColors.textPrimary
            : Colors.white;

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 20, color: contentColor),
          const SizedBox(width: 8),
          Text(
            widget.text,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: contentColor,
            ),
          ),
        ],
      );
    }

    return Text(
      widget.text,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: contentColor,
      ),
    );
  }
}
