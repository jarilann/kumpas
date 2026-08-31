import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Shared scaffold + "🏠 Bumalik" back header used across the
/// Matuto/module/lesson/quiz screens (mockup screens 6–14).
class ModuleScaffold extends StatelessWidget {
  final Widget child;
  final bool showBackHeader;

  const ModuleScaffold({
    super.key,
    required this.child,
    this.showBackHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.primaryBlue,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showBackHeader) const _BumalikHeader(),
                if (showBackHeader) const SizedBox(height: 12),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BumalikHeader extends StatelessWidget {
  const _BumalikHeader();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).maybePop(),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home_outlined, color: AppColors.textWhite, size: 20),
            SizedBox(width: 6),
            Text('Bumalik',
                style: TextStyle(color: AppColors.textWhite, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
