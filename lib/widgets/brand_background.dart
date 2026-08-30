import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Soft light background with subtle brand accents.
class BrandBackground extends StatelessWidget {
  final Widget child;
  final bool showAccent;

  const BrandBackground({super.key, required this.child, this.showAccent = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF4FBFF), AppTheme.kBackground],
        ),
      ),
      child: Stack(
        children: [
          if (showAccent) ...[
            Positioned(
              top: -90,
              right: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.kCyan.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -110,
              left: -70,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.kNavy.withValues(alpha: 0.04),
                ),
              ),
            ),
          ],
          child,
        ],
      ),
    );
  }
}
