import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool outlined;
  final Color? color;
  final Color? foregroundColor;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.outlined = false,
    this.color,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppTheme.kCyan;
    final fg = foregroundColor ?? AppTheme.kTextOnBrand;

    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: bg,
            side: BorderSide(color: bg, width: 1.8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _content(fg: bg),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _content(fg: fg),
      ),
    );
  }

  Widget _content({required Color fg}) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(color: fg, strokeWidth: 2.4),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 10),
        ],
        Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: fg, letterSpacing: 0.4)),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: 18, color: fg),
        ],
      ],
    );
  }
}
