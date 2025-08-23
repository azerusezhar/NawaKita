import 'package:flutter/material.dart';

/// Reusable rounded, filled text field used in auth screens.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final radius = BorderRadius.circular(18);
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        // Softer, premium-like fill
        fillColor: const Color(0xFFF7F8FA),
        // Subtle icon color and size
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: cs.onSurfaceVariant, size: 22) : null,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        // Lighter default outline, thicker focus
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        // Slightly refined hint/label styles via theme inherit
      ),
    );
  }
}
