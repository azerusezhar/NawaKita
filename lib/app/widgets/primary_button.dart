import 'package:flutter/material.dart';

/// A reusable primary button used across the app.
/// Default color follows brand: #2158E1.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.textColor,
    this.icon,
    this.fullWidth = true,
    this.height = 52,
    this.borderRadius = 14,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final Widget? icon;
  final bool fullWidth;
  final double height;
  final double borderRadius;

  // Lighter/brighter blue
  static const Color _defaultColor = Color(0xFF3B73FF);

  @override
  Widget build(BuildContext context) {
    final _ = Theme.of(context).colorScheme;
    final bg = color ?? _defaultColor;
    final fg = textColor ?? Colors.white;

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          icon!,
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );

    final button = ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: DecoratedBox(
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: onPressed == null ? bg.withOpacity(0.5) : bg,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(alignment: Alignment.center, child: child),
            ),
          ),
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
