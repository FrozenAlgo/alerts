import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AppBrandedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool showShield;

  const AppBrandedAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.showShield = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: centerTitle,
      leading: leading,
      title: showShield
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined, color: AppTheme.kCyan, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.kTextPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            )
          : Text(
              title,
              style: const TextStyle(
                color: AppTheme.kTextPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
      actions: actions,
    );
  }
}
